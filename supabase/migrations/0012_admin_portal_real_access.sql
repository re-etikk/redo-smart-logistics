-- 0012_admin_portal_real_access.sql
-- REDO Operations Control Room: Full Admin Access, KYC Verification, and Live Realtime Publications.
-- Founder bootstrap in the Supabase SQL Editor (replace the email, run once):
-- select public.promote_to_admin('founder@example.com');

alter table public.profiles
  add column if not exists admin_previous_role text
  check (admin_previous_role in ('truck_owner', 'sme'));

alter table public.kyc_verifications
  add column if not exists rejection_reason text;

-- 1. Helper Function: Is the current user an approved administrator?
create or replace function public.is_admin()
returns boolean language sql security definer stable
set search_path = public, auth as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- 2. Helper Procedure: Easily promote any user to Admin via SQL or RPC
create or replace function public.promote_to_admin(target_email text)
returns jsonb language plpgsql security definer
set search_path = public, auth as $$
declare
  target_id uuid;
  updated_row public.profiles%rowtype;
begin
  -- This function is intended for trusted service-role operations only.
  if auth.uid() is not null and not public.is_admin() then
    raise exception 'Admin access required';
  end if;

  -- Lookup by email in auth.users
  select u.id into target_id
  from auth.users u
  where lower(u.email) = lower(target_email)
  limit 1;

  if target_id is null then
    return jsonb_build_object('success', false, 'message', 'User not found with provided email or phone.');
  end if;

  if not exists (select 1 from public.profiles where id = target_id) then
    return jsonb_build_object('success', false, 'message', 'User profile is not initialized yet.');
  end if;

  update public.profiles
  set admin_previous_role = case when role = 'admin' then admin_previous_role else role end,
      role = 'admin', onboarding_complete = true
  where id = target_id
  returning * into updated_row;

  return jsonb_build_object(
    'success', true,
    'user_id', updated_row.id,
    'full_name', updated_row.full_name,
    'role', updated_row.role,
    'message', 'User successfully promoted to Platform Administrator.'
  );
end;
$$;

revoke all on function public.promote_to_admin(text) from public, anon, authenticated;
grant execute on function public.promote_to_admin(text) to service_role;

-- 3. Admin RLS Policies (Allow role='admin' to inspect and manage all tables)

-- Profiles: Admin can view and update all profiles
create policy profiles_admin_select on public.profiles
  for select using (public.is_admin());

create policy profiles_admin_update on public.profiles
  for update using (public.is_admin());

-- Bookings: Admin can view and manage all bookings
create policy bookings_admin_select on public.bookings
  for select using (public.is_admin());

create policy bookings_admin_update on public.bookings
  for update using (public.is_admin());

-- Cargo Requests: Admin can view and manage all loads
create policy cargo_admin_select on public.cargo_requests
  for select using (public.is_admin());

create policy cargo_admin_update on public.cargo_requests
  for update using (public.is_admin());

-- Trucks: Admin can view and manage all trucks
create policy trucks_admin_select on public.trucks
  for select using (public.is_admin());

create policy trucks_admin_update on public.trucks
  for update using (public.is_admin());

-- KYC Verifications: Admin can view and update documents
create policy kyc_admin_select on public.kyc_verifications
  for select using (public.is_admin());

create policy kyc_admin_update on public.kyc_verifications
  for update using (public.is_admin());

-- Disputes: Admin can view and resolve disputes
create policy disputes_admin_select on public.disputes
  for select using (public.is_admin());

create policy disputes_admin_update on public.disputes
  for update using (public.is_admin());

-- Pricing Configurations: Admin can read and update pricing rules
create policy pricing_admin_all on public.pricing_configurations
  for all using (public.is_admin());

-- Trip Segments: Admin can inspect and update live capacity segments
create policy trip_segments_admin_all on public.trip_segments
  for all using (public.is_admin()) with check (public.is_admin());

-- Notifications: Admin can inspect and manage delivery/audit notifications
create policy notifications_admin_all on public.notifications
  for all using (public.is_admin()) with check (public.is_admin());

-- 4. Ensure Permissions on schema public
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, service_role;

-- 5. Realtime publication additions
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'cargo_requests'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.cargo_requests;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'bookings'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.bookings;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'trucks'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.trucks;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'kyc_verifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.kyc_verifications;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  END IF;
END $$;
