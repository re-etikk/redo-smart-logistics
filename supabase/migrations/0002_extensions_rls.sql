-- Redo v2 — required extensions beyond the base §51 schema.
-- Each addition is documented; nothing in §51 is altered destructively.

-- (1) Return trips. §14/§23 require an owner to post a return route with
-- spare capacity, but §51 has no trips table — matching needs one.
create table truck_trips (
  id uuid primary key default gen_random_uuid(),
  truck_id text not null references trucks(truck_id),
  origin text not null,
  destination text not null,
  distance_km numeric,
  departure_at timestamptz not null,
  available_capacity_tons numeric not null check (available_capacity_tons >= 0),
  price_per_km_ton numeric default 1.0,
  accepted_cargo_types text[],
  open_for_matching boolean default true,
  created_at timestamptz default now()
);

-- (2) Booking audit trail — every transition with actor + timestamps (§41).
create table booking_events (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references bookings(id),
  from_status text,
  to_status text not null,
  actor_id uuid references profiles(id),
  created_at timestamptz default now()
);

-- (3) Honest tracking: simulated events must be distinguishable (§37, §72).
alter table tracking_events add column is_simulated boolean not null default true;

-- (4) Booking link column for trips (which trip a booking rides on).
alter table bookings add column trip_id uuid references truck_trips(id);

-- (5) Cargo pickup as a proper timestamp (backend uses pickup_at; §51's
-- pickup_date/pickup_hour kept for CSV-compat, generated on insert if absent).
alter table cargo_requests add column pickup_at timestamptz;
alter table cargo_requests add column special_handling text;

-- ============================ RLS (§52) ============================
alter table profiles enable row level security;
alter table trucks enable row level security;
alter table truck_trips enable row level security;
alter table cargo_requests enable row level security;
alter table bookings enable row level security;
alter table booking_events enable row level security;
alter table kyc_verifications enable row level security;
alter table digital_proof enable row level security;
alter table tracking_events enable row level security;
alter table impact_records enable row level security;
alter table ratings enable row level security;
alter table notifications enable row level security;

-- Helper: are you a party to this booking?
create or replace function is_booking_party(b_id uuid) returns boolean
language sql security definer stable as $$
  select exists (
    select 1 from bookings b
    join trucks t on t.truck_id = b.truck_id
    join cargo_requests c on c.cargo_id = b.cargo_id
    where b.id = b_id and (t.owner_id = auth.uid() or c.sme_id = auth.uid())
  );
$$;

-- profiles: own row full access; counterparties readable via bookings.
create policy profiles_own on profiles for all
  using (id = auth.uid()) with check (id = auth.uid());
create policy profiles_counterparty on profiles for select using (
  exists (
    select 1 from bookings b
    join trucks t on t.truck_id = b.truck_id
    join cargo_requests c on c.cargo_id = b.cargo_id
    where (t.owner_id = profiles.id and c.sme_id = auth.uid())
       or (c.sme_id = profiles.id and t.owner_id = auth.uid())
  )
);

-- trucks: owner writes; authenticated read of non-sensitive matching fields.
create policy trucks_owner_all on trucks for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy trucks_read on trucks for select using (auth.role() = 'authenticated');

-- trips: owner writes; authenticated read (needed for matching).
create policy trips_owner_all on truck_trips for all
  using (exists (select 1 from trucks t where t.truck_id = truck_trips.truck_id and t.owner_id = auth.uid()))
  with check (exists (select 1 from trucks t where t.truck_id = truck_trips.truck_id and t.owner_id = auth.uid()));
create policy trips_read on truck_trips for select using (auth.role() = 'authenticated');

-- cargo: SME writes own; open cargo readable to authenticated users.
create policy cargo_sme_all on cargo_requests for all
  using (sme_id = auth.uid()) with check (sme_id = auth.uid());
create policy cargo_read_open on cargo_requests for select
  using (auth.role() = 'authenticated' and status = 'open');
create policy cargo_read_party on cargo_requests for select using (
  exists (select 1 from bookings b where b.cargo_id = cargo_requests.cargo_id and is_booking_party(b.id))
);

-- bookings + children: only the two parties.
create policy bookings_party on bookings for select using (is_booking_party(id));
create policy booking_events_party on booking_events for select using (is_booking_party(booking_id));
create policy proof_party on digital_proof for select using (is_booking_party(booking_id));
create policy tracking_party on tracking_events for select using (is_booking_party(booking_id));
create policy impact_party on impact_records for select using (is_booking_party(booking_id));
create policy ratings_party on ratings for select
  using (rated_by = auth.uid() or rated_user = auth.uid());

-- KYC: strictly own rows. Server workflows use the service role (bypasses RLS).
create policy kyc_own on kyc_verifications for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- notifications: own only.
create policy notifications_own on notifications for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- NOTE: inserts/updates for bookings, tracking, proof, ratings, impact go
-- through the backend (service role) so the state machine and authorization
-- checks in code are always enforced; client policies are read-only there.

-- ====================== Storage buckets (§35) ======================
insert into storage.buckets (id, name, public) values
  ('kyc-documents', 'kyc-documents', false),
  ('pickup-proofs', 'pickup-proofs', false),
  ('delivery-proofs', 'delivery-proofs', false),
  ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- Users may upload only into their own folder: <uid>/filename
create policy storage_own_upload on storage.objects for insert with check (
  bucket_id in ('kyc-documents','pickup-proofs','delivery-proofs','avatars')
  and (storage.foldername(name))[1] = auth.uid()::text
);
create policy storage_own_read on storage.objects for select using (
  bucket_id = 'avatars'
  or (storage.foldername(name))[1] = auth.uid()::text
);

-- ========================= Realtime (§37) =========================
alter publication supabase_realtime add table tracking_events, bookings, notifications;
