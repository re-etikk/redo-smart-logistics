-- Redo v2 — schema per master prompt §51 (verbatim tables) + required constraints.
create extension if not exists "pgcrypto";

create table profiles (
  id uuid primary key references auth.users(id),
  full_name text not null,
  phone text unique,
  role text not null check (role in ('truck_owner','sme')),
  company_name text,
  avatar_url text,
  onboarding_complete boolean default false,
  created_at timestamptz default now()
);

create table trucks (
  truck_id text primary key,
  owner_id uuid not null references profiles(id),
  truck_type text not null,
  registration_number text,
  body_type text,
  home_origin text,
  default_capacity_tons numeric not null,
  driver_rating numeric default 4.0,
  on_time_rate numeric default 0.85,
  cancel_rate numeric default 0.05,
  route_deviation_rate numeric default 0.03,
  verified_documents boolean default false,
  gps_enabled boolean default true,
  current_lat numeric,
  current_lng numeric,
  status text check (status in ('available','in_transit','offline')) default 'available',
  created_at timestamptz default now()
);

create table cargo_requests (
  cargo_id text primary key,
  sme_id uuid not null references profiles(id),
  origin text not null,
  destination text not null,
  distance_km numeric,
  cargo_type text not null,
  cargo_weight_tons numeric not null,
  pickup_date date,
  pickup_hour int,
  urgency text default 'normal',
  status text check (status in ('open','matched','booked','delivered','cancelled')) default 'open',
  created_at timestamptz default now()
);

create table bookings (
  id uuid primary key default gen_random_uuid(),
  cargo_id text not null references cargo_requests(cargo_id),
  truck_id text not null references trucks(truck_id),
  match_score numeric,
  agreed_price_inr numeric,
  status text check (status in (
    'pending','accepted','confirmed','pickup_ready','picked_up',
    'in_transit','delivered','completed','cancelled','disputed'
  )) default 'pending',
  created_at timestamptz default now()
);

create table kyc_verifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id),
  document_type text not null,
  verification_status text default 'pending',
  verification_source text,
  document_reference_masked text,
  face_verification_status text default 'pending',
  verified_at timestamptz,
  created_at timestamptz default now()
);

create table digital_proof (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references bookings(id),
  proof_type text not null check (proof_type in ('pickup','delivery')),
  photo_url text,
  gps_lat numeric,
  gps_lng numeric,
  timestamp timestamptz default now(),
  confirmed_by uuid references profiles(id),
  unique (booking_id, proof_type)
);

create table tracking_events (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references bookings(id),
  lat numeric,
  lng numeric,
  progress_pct numeric,
  eta_minutes numeric,
  timestamp timestamptz default now()
);

create table impact_records (
  booking_id uuid primary key references bookings(id),
  empty_km_avoided numeric,
  utilization_gain_pct numeric,
  truck_owner_income_inr numeric,
  sme_saving_inr numeric,
  fuel_avoided_liters numeric,
  co2_avoided_kg numeric
);

create table ratings (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references bookings(id),
  rated_by uuid not null references profiles(id),
  rated_user uuid not null references profiles(id),
  score int check (score between 1 and 5),
  comment text,
  created_at timestamptz default now()
);

create table notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id),
  type text,
  title text,
  message text,
  read boolean default false,
  created_at timestamptz default now()
);
