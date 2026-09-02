-- ============================================================
-- REDO — run ONCE in Supabase SQL Editor (project npisbdoztiweaayqmqev)
-- This is what makes the two apps + website LIVE-connected.
-- Safe to re-run (idempotent).
-- ============================================================

-- 1) Realtime publication: without cargo_requests here, a shipper posting
--    cargo NEVER pops live into the partner's Available Loads feed.
do $$ begin
  alter publication supabase_realtime add table public.cargo_requests;
exception when duplicate_object then null; end $$;

do $$ begin
  alter publication supabase_realtime add table public.truck_trips;
exception when duplicate_object then null; end $$;

do $$ begin
  alter publication supabase_realtime add table public.bookings;
exception when duplicate_object then null; end $$;

do $$ begin
  alter publication supabase_realtime add table public.notifications;
exception when duplicate_object then null; end $$;

do $$ begin
  alter publication supabase_realtime add table public.tracking_events;
exception when duplicate_object then null; end $$;

-- 2) Open return trips readable by any signed-in user (matching visibility).
drop policy if exists trips_read_open on public.truck_trips;
create policy trips_read_open on public.truck_trips
  for select using (auth.role() = 'authenticated');

-- 3) Verify (should list all 5 tables):
select tablename from pg_publication_tables
where pubname = 'supabase_realtime' order by tablename;
