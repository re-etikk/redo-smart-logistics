-- ============================================================
-- REDO — run ONCE in Supabase SQL Editor  (v2 — realtime + OTP)
-- Safe to re-run (idempotent).
-- ============================================================

-- 1) Realtime publication (live cross-app wiring)
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

-- 2) Open return trips visible to signed-in users
--    (powers the Rapido-style "live trucks on the map" feed)
drop policy if exists trips_read_open on public.truck_trips;
create policy trips_read_open on public.truck_trips
  for select using (auth.role() = 'authenticated');

-- 3) OTP-secured handover (Rapido/Porter-style pickup & delivery OTPs)
alter table public.bookings add column if not exists pickup_otp text;
alter table public.bookings add column if not exists delivery_otp text;
alter table public.bookings add column if not exists pickup_otp_verified_at timestamptz;
alter table public.bookings add column if not exists delivery_otp_verified_at timestamptz;

-- 4) Verify
select tablename from pg_publication_tables
 where pubname = 'supabase_realtime' order by tablename;
