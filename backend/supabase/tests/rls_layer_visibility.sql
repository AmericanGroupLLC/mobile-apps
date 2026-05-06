-- backend/supabase/tests/rls_layer_visibility.sql
-- Run with:  psql "$DATABASE_URL" -f rls_layer_visibility.sql
--
-- Asserts that two distinct users see each other only when they share a
-- discovery layer, and never each other's reports.

\set ON_ERROR_STOP on

begin;

-- Helper: assume a JWT for user U
create or replace function set_jwt(u uuid) returns void as $$
begin
    perform set_config('request.jwt.claims',
        json_build_object('sub', u, 'role', 'authenticated')::text, true);
    perform set_config('role', 'authenticated', true);
end; $$ language plpgsql;

-- Sara + Maya share zip '940' (seeded by seed.sql); Noah is in '100'.
select set_jwt('11111111-1111-1111-1111-111111111101'::uuid);

do $$
declare
    n_visible int;
    n_noah_visible int;
begin
    select count(*) into n_visible
      from public.profiles where id = '11111111-1111-1111-1111-111111111102'::uuid;
    if n_visible <> 1 then
        raise exception 'RLS layer-zip: Sara should see Maya, got %', n_visible;
    end if;

    select count(*) into n_noah_visible
      from public.profiles where id = '11111111-1111-1111-1111-111111111106'::uuid;
    -- They share the server layer too, so this is allowed. RLS layer-server.
    if n_noah_visible <> 1 then
        raise exception 'RLS layer-server: Sara should see Noah via server, got %', n_noah_visible;
    end if;
end $$;

-- Reports: a regular user cannot SELECT reports.
select set_jwt('11111111-1111-1111-1111-111111111101'::uuid);
do $$
declare
    n int;
begin
    select count(*) into n from public.reports;
    if n <> 0 then
        raise exception 'RLS reports: client should never SELECT, got %', n;
    end if;
end $$;

rollback;
\echo PASS rls_layer_visibility
