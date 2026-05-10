-- Realtime publication. Drift clients subscribe to messages + waves +
-- conversations; popular profiles use the wave_aggregates channel rather
-- than the raw stream.

drop publication if exists drift_realtime;

create publication drift_realtime for table
    public.messages,
    public.waves,
    public.conversations,
    public.wave_aggregates;

-- For supabase Realtime to honour RLS on broadcast.
alter table public.messages         replica identity full;
alter table public.waves            replica identity full;
alter table public.conversations    replica identity full;
alter table public.wave_aggregates  replica identity full;
