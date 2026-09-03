-- ============================================================
-- REDO — run ONCE in Supabase SQL Editor  (v3 — realtime + OTP + auth fix)
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

-- 4) Fix RLS permissions for registration & bookings counterparty check (Fixes 42501 error)
grant select on public.bookings to anon;
grant select, insert, update on public.profiles to authenticated;
grant select, insert, update on public.profiles to anon;

drop policy if exists profiles_counterparty on public.profiles;
create policy profiles_counterparty on public.profiles for select using (
  auth.role() = 'authenticated' and exists (
    select 1 from public.bookings b
    join public.trucks t on t.truck_id = b.truck_id
    join public.cargo_requests c on c.cargo_id = b.cargo_id
    where (t.owner_id = profiles.id and c.sme_id = auth.uid())
       or (c.sme_id = profiles.id and t.owner_id = auth.uid())
  )
);

-- Ensure authenticated users can insert/update their own profile
drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own on public.profiles for insert with check (id = auth.uid());

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());

-- 5) Auto-create profile trigger on auth.users (zero failure registration for Email & Google)
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, role, onboarding_complete)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(coalesce(new.email, 'User'), '@', 1)),
    coalesce(new.raw_user_meta_data->>'role', 'truck_owner'),
    false
  )
  on conflict (id) do update set
    full_name = coalesce(excluded.full_name, profiles.full_name);
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 6) Verify
select tablename from pg_publication_tables
 where pubname = 'supabase_realtime' order by tablename;
