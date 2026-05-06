# Drift backend (Supabase)

The Drift backend is a single Supabase project: Postgres + GoTrue (Auth) +
Realtime + Storage + Edge Functions.

## Local boot

```sh
../scripts/seed-supabase.sh   # supabase start + db reset + seed
```

This requires Docker + the Supabase CLI (`brew install supabase/tap/supabase`).

## Layout

```
backend/supabase/
├── config.toml                 # supabase init output, committed
├── migrations/
│   ├── 0001_init.sql           # profiles, photos, waves, conversations, messages, reports, blocked_users
│   ├── 0002_realtime.sql       # RT publication on messages, waves, conversations
│   └── 0003_rls_helpers.sql    # is_layer_match(), can_view_profile(), can_send_message()
├── functions/
│   ├── reply-suggest/index.ts  # 3 reply suggestions (Casual, Context, Playful)
│   ├── reply-suggest/_test.ts
│   ├── verify-selfie/index.ts  # AWS Rekognition CompareFaces
│   ├── verify-selfie/_test.ts
│   ├── fuzz-location/index.ts  # lat/lon -> {zipPrefix3, countyFips, stateCode}
│   └── fuzz-location/_test.ts
├── seed/seed.sql               # 20 demo profiles for local dev
└── tests/
    └── rls_layer_visibility.sql # asserts RLS gates apply per-layer
```

## Schema cheatsheet

- `profiles` — one row per user, joined to `auth.users` by id.
  Fuzzed location columns: `zip_prefix3 char(3)`, `county_fips char(5)`,
  `state_code char(2)`. **No lat/lon.**
- `photos` — up to 6 per profile; one tagged `is_verification_selfie`.
- `waves` — `from_profile_id`, `to_profile_id`, `layer`, `status`.
- `conversations` — `profile_ids uuid[]`, `tone enum`, `last_read_*` timestamps.
- `messages` — `conversation_id`, `author_id`, `text`, `created_at`.
- `reports` — `reporter_id`, `target_id`, `reason`, `note`.
- `blocked_users` — `blocker_id`, `blocked_id`.

## RLS reasoning

Every table has Row-Level Security ON. The three SQL helper functions in
`0003_rls_helpers.sql` capture the rules:

- `can_view_profile(viewer uuid, target uuid) returns bool` — true iff
  - the viewer's chosen layer overlaps a layer the target is discoverable in,
  - **and** neither party blocked the other.
- `is_layer_match(viewer, target, layer) returns bool` — same as above but
  scoped to a specific layer (used by the `waves` insert policy).
- `can_send_message(sender, conversation) returns bool` — true iff
  - the sender is a participant in the conversation,
  - **and** both participants are verified,
  - **and** neither blocked the other.

These three helpers are the single source of truth for "who can see/do what."
Every RLS policy delegates to them so the rules stay easy to audit.

## Edge Function secrets

Set via the Supabase CLI (NOT via `.env`):

```sh
supabase secrets set LLM_API_KEY=...                  # reply-suggest
supabase secrets set LLM_PROVIDER=openai              # or "anthropic"
supabase secrets set AWS_ACCESS_KEY_ID=...            # verify-selfie
supabase secrets set AWS_SECRET_ACCESS_KEY=...
supabase secrets set AWS_REGION=us-east-1
```

The functions log to Supabase Logflare. None of these secrets are ever
shipped to the client.
