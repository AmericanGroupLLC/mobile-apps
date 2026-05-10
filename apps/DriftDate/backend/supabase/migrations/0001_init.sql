-- Drift v1 schema
-- ───────────────────────────────────────────────────────────────────────
-- Conventions:
--   * No `lat` / `lon` columns. Only fuzzed location: zip_prefix3 (3 chars),
--     county_fips (5 chars), state_code (2 chars). PostGIS centroids per
--     county live in `geo.county_centroids` and are server-private.
--   * Every user-facing table has RLS ON. Policies delegate to helper
--     functions defined in 0003_rls_helpers.sql.
--   * Foreign keys cascade ON DELETE so erase-all-data is one statement.

create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";
create extension if not exists "postgis";

-- Reference schema for read-only ops data.
create schema if not exists geo;

-- Geo lookup tables (seeded out-of-band; not exposed via the REST API).
create table if not exists geo.county_centroids (
    fips        char(5) primary key,
    state_code  char(2) not null,
    name        text    not null,
    centroid    geometry(Point, 4326) not null
);
revoke all on geo.county_centroids from anon, authenticated;

-- ───────────────────────────────────────────────────────────────────────
-- profiles
-- ───────────────────────────────────────────────────────────────────────

create type intent_t as enum ('dating', 'serious', 'friendship', 'open');
create type layer_t  as enum ('server', 'state', 'county', 'zip');
create type tone_t   as enum ('slow', 'energetic', 'deep', 'meetup_ready');
create type wave_status_t as enum ('pending', 'matched', 'passed');

create table public.profiles (
    id              uuid primary key references auth.users(id) on delete cascade,
    display_name    text not null,
    legal_name      text,                                       -- ops-only, never returned to clients
    dob             date not null,                              -- age computed on read
    intent          intent_t not null,
    vibe_tags       text[] not null default '{}',               -- ≤ 5 from fixed taxonomy
    zip_prefix3     char(3),
    county_fips     char(5),
    state_code      char(2),
    voice_prompt_url text,
    discoverable_layers layer_t[] not null default array['server','state','county','zip']::layer_t[],
    invisible       boolean not null default false,
    paused          boolean not null default false,
    verified_at     timestamptz,
    last_active_at  timestamptz not null default now(),
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    constraint vibe_tags_max_5 check (cardinality(vibe_tags) <= 5),
    constraint zip_prefix3_3char check (zip_prefix3 is null or length(zip_prefix3) = 3)
);

create index profiles_layer_idx on public.profiles (zip_prefix3, county_fips, state_code);
create index profiles_active_idx on public.profiles (last_active_at desc);

-- Three Hinge-style structured prompts.
create table public.profile_prompts (
    id          uuid primary key default uuid_generate_v4(),
    profile_id  uuid not null references public.profiles(id) on delete cascade,
    slot        smallint not null check (slot between 1 and 3),
    prompt_key  text not null,             -- e.g. "looking_for", "perfect_sunday"
    response    text not null check (length(response) <= 280),
    created_at  timestamptz not null default now(),
    unique (profile_id, slot)
);

-- Up to 6 photos per profile. Exactly one tagged the verification selfie.
create table public.photos (
    id            uuid primary key default uuid_generate_v4(),
    profile_id    uuid not null references public.profiles(id) on delete cascade,
    storage_path  text not null,                                -- supabase storage key
    sort_order    smallint not null check (sort_order between 1 and 6),
    is_verification_selfie boolean not null default false,
    created_at    timestamptz not null default now(),
    unique (profile_id, sort_order)
);

create unique index photos_one_verification_selfie
  on public.photos (profile_id)
  where is_verification_selfie;

-- ───────────────────────────────────────────────────────────────────────
-- waves
-- ───────────────────────────────────────────────────────────────────────

create table public.waves (
    id              uuid primary key default uuid_generate_v4(),
    from_profile_id uuid not null references public.profiles(id) on delete cascade,
    to_profile_id   uuid not null references public.profiles(id) on delete cascade,
    layer           layer_t not null,
    status          wave_status_t not null default 'pending',
    created_at      timestamptz not null default now(),
    matched_at      timestamptz,
    constraint waves_no_self_wave check (from_profile_id <> to_profile_id),
    unique (from_profile_id, to_profile_id)
);

create index waves_to_idx     on public.waves (to_profile_id, status);
create index waves_status_idx on public.waves (status, created_at);

-- Aggregate for popular profiles. Refresh every 5s via pg_cron (created
-- in production, no-op in local).
create table public.wave_aggregates (
    profile_id  uuid primary key references public.profiles(id) on delete cascade,
    pending_total bigint not null default 0,
    matched_total bigint not null default 0,
    refreshed_at  timestamptz not null default now()
);

-- ───────────────────────────────────────────────────────────────────────
-- conversations + messages
-- ───────────────────────────────────────────────────────────────────────

create table public.conversations (
    id            uuid primary key default uuid_generate_v4(),
    profile_a_id  uuid not null references public.profiles(id) on delete cascade,
    profile_b_id  uuid not null references public.profiles(id) on delete cascade,
    tone          tone_t not null default 'slow',
    last_read_a   timestamptz,
    last_read_b   timestamptz,
    muted_by_a    boolean not null default false,
    muted_by_b    boolean not null default false,
    created_at    timestamptz not null default now(),
    constraint conversations_distinct_parties check (profile_a_id <> profile_b_id),
    -- canonical ordering so the (a,b) pair is unique regardless of who matched first
    constraint conversations_ordered check (profile_a_id < profile_b_id),
    unique (profile_a_id, profile_b_id)
);

create table public.messages (
    id              uuid primary key default uuid_generate_v4(),
    conversation_id uuid not null references public.conversations(id) on delete cascade,
    author_id       uuid not null references public.profiles(id) on delete cascade,
    text            text not null check (length(text) between 1 and 4000),
    created_at      timestamptz not null default now()
);

create index messages_conversation_idx on public.messages (conversation_id, created_at desc);

-- ───────────────────────────────────────────────────────────────────────
-- safety: reports + blocked_users
-- ───────────────────────────────────────────────────────────────────────

create table public.reports (
    id            uuid primary key default uuid_generate_v4(),
    reporter_id   uuid not null references public.profiles(id) on delete cascade,
    target_id     uuid not null references public.profiles(id) on delete cascade,
    reason        text not null check (length(reason) between 1 and 64),
    note          text check (length(note) <= 2000),
    created_at    timestamptz not null default now(),
    resolved_at   timestamptz,
    constraint reports_no_self check (reporter_id <> target_id)
);

create index reports_target_idx on public.reports (target_id, created_at desc);

create table public.blocked_users (
    blocker_id  uuid not null references public.profiles(id) on delete cascade,
    blocked_id  uuid not null references public.profiles(id) on delete cascade,
    created_at  timestamptz not null default now(),
    primary key (blocker_id, blocked_id),
    constraint blocked_users_no_self check (blocker_id <> blocked_id)
);

-- ───────────────────────────────────────────────────────────────────────
-- audit views (server-private)
-- ───────────────────────────────────────────────────────────────────────

create schema if not exists audit;

create or replace view audit.user_actions as
    select 'report'::text as kind, reporter_id as actor, target_id as object,
           created_at, reason as detail
      from public.reports
    union all
    select 'block'::text, blocker_id, blocked_id, created_at, null
      from public.blocked_users;
revoke all on audit.user_actions from anon, authenticated;

-- ───────────────────────────────────────────────────────────────────────
-- RLS — every table on, policies wired in 0003_rls_helpers.sql
-- ───────────────────────────────────────────────────────────────────────

alter table public.profiles         enable row level security;
alter table public.profile_prompts  enable row level security;
alter table public.photos           enable row level security;
alter table public.waves            enable row level security;
alter table public.wave_aggregates  enable row level security;
alter table public.conversations    enable row level security;
alter table public.messages         enable row level security;
alter table public.reports          enable row level security;
alter table public.blocked_users    enable row level security;
