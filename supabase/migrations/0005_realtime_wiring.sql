-- 0005_realtime_wiring.sql
-- Full live wiring between website ↔ customer app ↔ partner app.
-- bookings, notifications, tracking_events are already in the realtime
-- publication (0002). cargo_requests was missing — without it, a shipper
-- posting cargo never appears live in the partner's Available Loads feed.
-- RLS already permits it (cargo_read_open: any authenticated user can
-- SELECT open cargo), so this is safe to broadcast.

do $$
begin
  alter publication supabase_realtime add table public.cargo_requests;
exception when duplicate_object then
  null; -- already added, fine
end $$;

do $$
begin
  alter publication supabase_realtime add table public.truck_trips;
exception when duplicate_object then
  null;
end $$;

-- Let authenticated users read open return trips (needed if clients ever
-- subscribe to trips; backend matching already reads them server-side).
drop policy if exists trips_read_open on public.truck_trips;
create policy trips_read_open on public.truck_trips
  for select using (auth.role() = 'authenticated');
