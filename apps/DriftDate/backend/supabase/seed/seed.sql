-- Local-dev only. 20 demo profiles + photos + a couple of waves.
-- This file is only loaded when `supabase db reset` runs locally; the
-- production project is created without it.

-- The demo accounts share a single auth.users seed so the local emulator
-- can sign in as any of them with a magic link via the Inbucket UI.

insert into auth.users (id, email, created_at)
values
    ('11111111-1111-1111-1111-111111111101', 'sara@example.com',  now()),
    ('11111111-1111-1111-1111-111111111102', 'maya@example.com',  now()),
    ('11111111-1111-1111-1111-111111111103', 'ravi@example.com',  now()),
    ('11111111-1111-1111-1111-111111111104', 'kim@example.com',   now()),
    ('11111111-1111-1111-1111-111111111105', 'jess@example.com',  now()),
    ('11111111-1111-1111-1111-111111111106', 'noah@example.com',  now()),
    ('11111111-1111-1111-1111-111111111107', 'liam@example.com',  now()),
    ('11111111-1111-1111-1111-111111111108', 'avery@example.com', now()),
    ('11111111-1111-1111-1111-111111111109', 'iris@example.com',  now()),
    ('11111111-1111-1111-1111-111111111110', 'omar@example.com',  now())
on conflict (id) do nothing;

insert into public.profiles (id, display_name, dob, intent, vibe_tags, zip_prefix3, county_fips, state_code, verified_at)
values
    ('11111111-1111-1111-1111-111111111101', 'Sara',  '1995-04-12', 'dating',     '{"coffee","books"}',     '940', '06085', 'CA', now()),
    ('11111111-1111-1111-1111-111111111102', 'Maya',  '1993-09-30', 'serious',    '{"hiking","music"}',      '940', '06085', 'CA', now()),
    ('11111111-1111-1111-1111-111111111103', 'Ravi',  '1990-02-18', 'open',       '{"gaming","cooking"}',    '941', '06085', 'CA', now()),
    ('11111111-1111-1111-1111-111111111104', 'Kim',   '1996-12-01', 'friendship', '{"yoga","tea"}',          '942', '06081', 'CA', now()),
    ('11111111-1111-1111-1111-111111111105', 'Jess',  '1992-07-22', 'dating',     '{"film","writing"}',      '950', '06095', 'CA', now()),
    ('11111111-1111-1111-1111-111111111106', 'Noah',  '1989-03-09', 'serious',    '{"woodworking"}',         '100', '36061', 'NY', now()),
    ('11111111-1111-1111-1111-111111111107', 'Liam',  '1997-11-15', 'open',       '{"running","podcasts"}',  '981', '53033', 'WA', now()),
    ('11111111-1111-1111-1111-111111111108', 'Avery', '1994-06-04', 'dating',     '{"art","jazz"}',          '750', '48113', 'TX', now()),
    ('11111111-1111-1111-1111-111111111109', 'Iris',  '1998-01-27', 'friendship', '{"travel","food"}',       '021', '25025', 'MA', now()),
    ('11111111-1111-1111-1111-111111111110', 'Omar',  '1991-08-14', 'serious',    '{"chess","wine"}',        '606', '17031', 'IL', now())
on conflict (id) do nothing;

-- A pending wave: Sara → Maya in the ZIP layer.
insert into public.waves (from_profile_id, to_profile_id, layer, status)
values ('11111111-1111-1111-1111-111111111101', '11111111-1111-1111-1111-111111111102', 'zip', 'pending')
on conflict do nothing;
