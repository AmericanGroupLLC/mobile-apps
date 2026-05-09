-- RLS helper functions + the policies that delegate to them.
-- Keep the rules concentrated here so the policy DDL stays readable.

-- ───────────────────────────────────────────────────────────────────────
-- helpers
-- ───────────────────────────────────────────────────────────────────────

create or replace function public.is_blocked(a uuid, b uuid)
returns boolean
language sql
stable
security definer
as $$
    select exists (
        select 1
          from public.blocked_users bu
         where (bu.blocker_id = a and bu.blocked_id = b)
            or (bu.blocker_id = b and bu.blocked_id = a)
    );
$$;

create or replace function public.is_layer_match(viewer uuid, target uuid, layer layer_t)
returns boolean
language sql
stable
security definer
as $$
    select exists (
        select 1
          from public.profiles v, public.profiles t
         where v.id = viewer and t.id = target
           and not v.invisible and not t.invisible
           and not v.paused    and not t.paused
           and layer = any (v.discoverable_layers)
           and layer = any (t.discoverable_layers)
           and case layer
                 when 'zip'    then v.zip_prefix3 is not null and v.zip_prefix3 = t.zip_prefix3
                 when 'county' then v.county_fips is not null and v.county_fips = t.county_fips
                 when 'state'  then v.state_code  is not null and v.state_code  = t.state_code
                 when 'server' then true
               end
    );
$$;

create or replace function public.can_view_profile(viewer uuid, target uuid)
returns boolean
language sql
stable
security definer
as $$
    select viewer = target
        or (
            not public.is_blocked(viewer, target)
            and (
                public.is_layer_match(viewer, target, 'zip')
                or public.is_layer_match(viewer, target, 'county')
                or public.is_layer_match(viewer, target, 'state')
                or public.is_layer_match(viewer, target, 'server')
            )
        );
$$;

create or replace function public.is_conversation_participant(viewer uuid, conv uuid)
returns boolean
language sql
stable
security definer
as $$
    select exists (
        select 1
          from public.conversations c
         where c.id = conv and (c.profile_a_id = viewer or c.profile_b_id = viewer)
    );
$$;

create or replace function public.can_send_message(sender uuid, conv uuid)
returns boolean
language sql
stable
security definer
as $$
    select exists (
        select 1
          from public.conversations c
          join public.profiles a on a.id = c.profile_a_id
          join public.profiles b on b.id = c.profile_b_id
         where c.id = conv
           and (sender = c.profile_a_id or sender = c.profile_b_id)
           and a.verified_at is not null
           and b.verified_at is not null
           and not public.is_blocked(c.profile_a_id, c.profile_b_id)
    );
$$;

-- ───────────────────────────────────────────────────────────────────────
-- profiles
-- ───────────────────────────────────────────────────────────────────────

create policy profiles_select on public.profiles
    for select using (public.can_view_profile(auth.uid(), id));

create policy profiles_insert_self on public.profiles
    for insert with check (auth.uid() = id);

create policy profiles_update_self on public.profiles
    for update using (auth.uid() = id) with check (auth.uid() = id);

create policy profiles_delete_self on public.profiles
    for delete using (auth.uid() = id);

-- ───────────────────────────────────────────────────────────────────────
-- profile_prompts
-- ───────────────────────────────────────────────────────────────────────

create policy prompts_select on public.profile_prompts
    for select using (public.can_view_profile(auth.uid(), profile_id));

create policy prompts_write_self on public.profile_prompts
    for all using (profile_id = auth.uid()) with check (profile_id = auth.uid());

-- ───────────────────────────────────────────────────────────────────────
-- photos
-- ───────────────────────────────────────────────────────────────────────

create policy photos_select on public.photos
    for select using (public.can_view_profile(auth.uid(), profile_id));

create policy photos_write_self on public.photos
    for all using (profile_id = auth.uid()) with check (profile_id = auth.uid());

-- ───────────────────────────────────────────────────────────────────────
-- waves
-- ───────────────────────────────────────────────────────────────────────

create policy waves_select on public.waves
    for select using (
        from_profile_id = auth.uid() or to_profile_id = auth.uid()
    );

create policy waves_insert on public.waves
    for insert with check (
        from_profile_id = auth.uid()
        and public.is_layer_match(auth.uid(), to_profile_id, layer)
        and not public.is_blocked(auth.uid(), to_profile_id)
    );

create policy waves_update on public.waves
    for update using (to_profile_id = auth.uid())
    with check    (to_profile_id = auth.uid());

-- ───────────────────────────────────────────────────────────────────────
-- wave_aggregates (read-only to clients)
-- ───────────────────────────────────────────────────────────────────────

create policy wave_aggregates_select on public.wave_aggregates
    for select using (profile_id = auth.uid());

-- ───────────────────────────────────────────────────────────────────────
-- conversations
-- ───────────────────────────────────────────────────────────────────────

create policy conversations_select on public.conversations
    for select using (auth.uid() in (profile_a_id, profile_b_id));

create policy conversations_insert on public.conversations
    for insert with check (auth.uid() in (profile_a_id, profile_b_id));

create policy conversations_update on public.conversations
    for update using (auth.uid() in (profile_a_id, profile_b_id))
    with check    (auth.uid() in (profile_a_id, profile_b_id));

-- ───────────────────────────────────────────────────────────────────────
-- messages
-- ───────────────────────────────────────────────────────────────────────

create policy messages_select on public.messages
    for select using (public.is_conversation_participant(auth.uid(), conversation_id));

create policy messages_insert on public.messages
    for insert with check (
        author_id = auth.uid()
        and public.can_send_message(auth.uid(), conversation_id)
    );

-- No update / delete on messages for v1.

-- ───────────────────────────────────────────────────────────────────────
-- reports + blocked_users
-- ───────────────────────────────────────────────────────────────────────

create policy reports_insert on public.reports
    for insert with check (reporter_id = auth.uid());
-- Reports are NOT selectable by clients.

create policy blocked_users_select on public.blocked_users
    for select using (blocker_id = auth.uid());

create policy blocked_users_insert on public.blocked_users
    for insert with check (blocker_id = auth.uid());

create policy blocked_users_delete on public.blocked_users
    for delete using (blocker_id = auth.uid());
