-- Nearby dispatch: exact 10 km matching, nearest five available trucks.
alter table public.cargo_requests
  add column if not exists pickup_lat numeric,
  add column if not exists pickup_lng numeric;

create table if not exists public.dispatch_offers (
  id uuid primary key default gen_random_uuid(),
  cargo_id text not null references public.cargo_requests(cargo_id) on delete cascade,
  driver_id uuid not null references public.profiles(id) on delete cascade,
  truck_id text not null references public.trucks(truck_id) on delete cascade,
  distance_km numeric not null check (distance_km >= 0 and distance_km <= 10),
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'skipped', 'expired', 'lost')),
  expires_at timestamptz not null default (now() + interval '45 seconds'),
  booking_id uuid references public.bookings(id),
  created_at timestamptz not null default now(),
  unique (cargo_id, truck_id)
);

create index if not exists dispatch_offers_driver_pending_idx
  on public.dispatch_offers(driver_id, created_at desc)
  where status = 'pending';

alter table public.dispatch_offers enable row level security;
drop policy if exists dispatch_offers_driver_select on public.dispatch_offers;
create policy dispatch_offers_driver_select on public.dispatch_offers
  for select to authenticated using (driver_id = auth.uid());

grant select on public.dispatch_offers to authenticated;
grant all on public.dispatch_offers to service_role;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'dispatch_offers'
  ) then
    alter publication supabase_realtime add table public.dispatch_offers;
  end if;
end $$;

create or replace function public.accept_dispatch_offer(target_offer_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  offer_row public.dispatch_offers%rowtype;
  cargo_row public.cargo_requests%rowtype;
  booking_row public.bookings%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select * into offer_row
  from public.dispatch_offers
  where id = target_offer_id and driver_id = auth.uid()
  for update;

  if not found then
    raise exception 'Dispatch offer not found';
  end if;
  if offer_row.status <> 'pending' or offer_row.expires_at <= now() then
    raise exception 'Dispatch offer is no longer available';
  end if;

  select * into cargo_row
  from public.cargo_requests
  where cargo_id = offer_row.cargo_id
  for update;

  if not found or cargo_row.status <> 'open' then
    raise exception 'Another driver has already accepted this load';
  end if;

  if not exists (
    select 1 from public.trucks
    where truck_id = offer_row.truck_id
      and owner_id = auth.uid()
      and status = 'available'
      and default_capacity_tons >= cargo_row.cargo_weight_tons
  ) then
    raise exception 'The offered truck is no longer available';
  end if;

  insert into public.bookings (
    cargo_id, truck_id, match_score, agreed_price_inr, status,
    pickup_otp, delivery_otp
  ) values (
    cargo_row.cargo_id,
    offer_row.truck_id,
    0.85,
    round(coalesce(cargo_row.distance_km, 0) * cargo_row.cargo_weight_tons * 1.05),
    'accepted',
    lpad(floor(random() * 10000)::text, 4, '0'),
    lpad(floor(random() * 10000)::text, 4, '0')
  ) returning * into booking_row;

  update public.cargo_requests
  set status = 'matched'
  where cargo_id = cargo_row.cargo_id;

  update public.dispatch_offers
  set status = case when id = target_offer_id then 'accepted' else 'lost' end,
      booking_id = case when id = target_offer_id then booking_row.id else null end
  where cargo_id = cargo_row.cargo_id and status = 'pending';

  insert into public.booking_events (booking_id, from_status, to_status, actor_id)
  values (booking_row.id, 'pending', 'accepted', auth.uid());

  insert into public.notifications (user_id, type, title, message)
  values (
    cargo_row.sme_id,
    'booking_request',
    'A nearby driver accepted your load',
    cargo_row.origin || ' → ' || cargo_row.destination || ' · Please confirm the booking.'
  );

  return jsonb_build_object(
    'booking', jsonb_build_object(
      'id', booking_row.id,
      'cargo_id', booking_row.cargo_id,
      'truck_id', booking_row.truck_id,
      'agreed_price_inr', booking_row.agreed_price_inr,
      'status', booking_row.status,
      'created_at', booking_row.created_at
    ),
    'offer_id', target_offer_id,
    'status', 'accepted'
  );
end;
$$;

revoke all on function public.accept_dispatch_offer(uuid) from public, anon;
grant execute on function public.accept_dispatch_offer(uuid) to authenticated, service_role;