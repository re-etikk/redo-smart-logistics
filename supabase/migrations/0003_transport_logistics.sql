-- 0003_transport_logistics.sql
-- REDO Transport & Logistics pivot: admin role, addresses, support desk,
-- published rate cards, invoices. Run after 0001 and 0002.

-- 1) Allow the admin role on profiles
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles
  add constraint profiles_role_check check (role in ('truck_owner', 'sme', 'admin'));
alter table public.profiles add column if not exists status text not null default 'active'
  check (status in ('active', 'suspended'));

-- 2) Saved addresses (shipper address book)
create table if not exists public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  label text not null,
  type text not null default 'pickup' check (type in ('pickup', 'delivery', 'warehouse', 'office')),
  address text,
  city text not null,
  state text,
  pincode text,
  contact_name text,
  contact_phone text,
  is_frequent boolean not null default false,
  deleted boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists idx_addresses_user on public.addresses(user_id) where not deleted;

-- 3) Support desk
create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  subject text not null,
  description text,
  category text not null default 'General',
  status text not null default 'open' check (status in ('open', 'in_progress', 'resolved', 'closed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.support_messages (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.support_tickets(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);
create index if not exists idx_support_msgs_ticket on public.support_messages(ticket_id);

-- 4) Published FTL rate cards (indicative lane pricing)
create table if not exists public.rate_cards (
  id uuid primary key default gen_random_uuid(),
  origin text not null,
  destination text not null,
  distance_km numeric not null,
  ft20 numeric not null,
  ft24 numeric not null,
  ft32 numeric not null,
  ft40 numeric not null,
  transit_days text not null default '2-3 days',
  unique (origin, destination)
);

insert into public.rate_cards (origin, destination, distance_km, ft20, ft24, ft32, ft40, transit_days) values
  ('Mumbai', 'Delhi', 1400, 28000, 32000, 38000, 44000, '2-3 days'),
  ('Mumbai', 'Bangalore', 980, 22000, 25000, 30000, 36000, '2 days'),
  ('Delhi', 'Kolkata', 1500, 29000, 33000, 39000, 45000, '3 days'),
  ('Delhi', 'Jaipur', 280, 9000, 11000, 14000, 17000, '1 day'),
  ('Mumbai', 'Pune', 150, 6000, 7500, 9500, 12000, 'Same day'),
  ('Surat', 'Mumbai', 280, 9000, 11000, 14000, 17000, '1 day'),
  ('Chennai', 'Kolkata', 1670, 31000, 36000, 42000, 48000, '3-4 days')
on conflict (origin, destination) do nothing;

-- 5) Invoices (auto-created when a booking completes)
create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  invoice_no text not null unique,
  booking_id uuid not null references public.bookings(id) on delete cascade,
  sme_id uuid not null references public.profiles(id),
  base_inr numeric not null,
  gst_inr numeric not null,
  total_inr numeric not null,
  status text not null default 'paid' check (status in ('paid', 'pending')),
  created_at timestamptz not null default now(),
  unique (booking_id)
);

-- 6) RLS
alter table public.addresses enable row level security;
alter table public.support_tickets enable row level security;
alter table public.support_messages enable row level security;
alter table public.rate_cards enable row level security;
alter table public.invoices enable row level security;

drop policy if exists addresses_own on public.addresses;
create policy addresses_own on public.addresses
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists tickets_own on public.support_tickets;
create policy tickets_own on public.support_tickets
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists ticket_msgs_party on public.support_messages;
create policy ticket_msgs_party on public.support_messages
  for select using (
    exists (select 1 from public.support_tickets t where t.id = ticket_id and t.user_id = auth.uid())
  );
drop policy if exists ticket_msgs_insert on public.support_messages;
create policy ticket_msgs_insert on public.support_messages
  for insert with check (
    author_id = auth.uid()
    and exists (select 1 from public.support_tickets t where t.id = ticket_id and t.user_id = auth.uid())
  );

drop policy if exists rate_cards_read on public.rate_cards;
create policy rate_cards_read on public.rate_cards for select using (true);

drop policy if exists invoices_own on public.invoices;
create policy invoices_own on public.invoices for select using (sme_id = auth.uid());

-- Admin operations (stats, user lists, KYC decisions) go through the backend
-- service-role client with an explicit role check — no anon RLS bypass is granted.
