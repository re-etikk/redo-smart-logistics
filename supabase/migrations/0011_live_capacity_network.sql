-- 0011_live_capacity_network.sql
-- REDO Live Capacity Marketplace: Corridor waypoints, Cargo compatibility matrix,
-- Dynamic pricing rules, Trip segments, and Disputes & Escrow management.

-- 1. Corridor Waypoints (Highway graph for sub-segment matching)
create table if not exists public.corridor_waypoints (
  id uuid primary key default gen_random_uuid(),
  corridor_id text not null,
  corridor_name text not null,
  sequence_idx integer not null,
  city text not null,
  state text,
  km_from_start numeric not null default 0,
  lat numeric,
  lng numeric,
  created_at timestamptz not null default now(),
  unique(corridor_id, sequence_idx),
  unique(corridor_id, city)
);

create index if not exists idx_corridor_waypoints_city on public.corridor_waypoints(city);
create index if not exists idx_corridor_waypoints_corridor on public.corridor_waypoints(corridor_id);

-- 2. Cargo Compatibility Matrix
create table if not exists public.cargo_compatibility_rules (
  id uuid primary key default gen_random_uuid(),
  cargo_type_a text not null,
  cargo_type_b text not null,
  is_compatible boolean not null default true,
  risk_level text not null default 'safe' check (risk_level in ('safe', 'warning', 'prohibited')),
  restrictions text,
  created_at timestamptz not null default now(),
  unique(cargo_type_a, cargo_type_b)
);

-- 3. Dynamic Pricing Configurations (Editable from Admin Control Room)
create table if not exists public.pricing_configurations (
  id uuid primary key default gen_random_uuid(),
  corridor_id text not null unique,
  corridor_name text not null,
  base_rate_per_ton_km numeric not null default 2.40,
  min_fare_inr numeric not null default 1500,
  detour_rate_per_km numeric not null default 25.0,
  platform_commission_pct numeric not null default 0.08,
  fragile_multiplier numeric not null default 1.18,
  fmcg_multiplier numeric not null default 1.08,
  perishable_multiplier numeric not null default 1.25,
  high_value_multiplier numeric not null default 1.30,
  hazardous_multiplier numeric not null default 1.35,
  occupancy_deep_discount numeric not null default 0.88,
  occupancy_std_discount numeric not null default 0.95,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 4. Trip Segments (Live capacity tracked at each highway waypoint)
create table if not exists public.trip_segments (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null,
  truck_id text not null references public.trucks(truck_id) on delete cascade,
  from_city text not null,
  to_city text not null,
  sequence_order integer not null,
  distance_km numeric not null default 0,
  max_capacity_tons numeric not null,
  booked_capacity_tons numeric not null default 0,
  available_capacity_tons numeric not null,
  status text not null default 'scheduled' check (status in ('scheduled', 'in_progress', 'completed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_trip_segments_cities on public.trip_segments(from_city, to_city);
create index if not exists idx_trip_segments_truck on public.trip_segments(truck_id);

-- 5. Disputes & Claims Table (Escrow Release/Hold desk)
create table if not exists public.disputes (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  filed_by uuid not null references public.profiles(id),
  claim_type text not null check (claim_type in ('cargo_damage', 'shortage', 'major_delay', 'driver_misbehavior', 'billing_issue')),
  description text not null,
  photo_urls text[] default '{}',
  claim_amount_inr numeric default 0,
  status text not null default 'open' check (status in ('open', 'under_investigation', 'resolved_refund', 'resolved_payout', 'rejected')),
  resolution_notes text,
  resolved_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

-- 6. Initial Seed Data

-- A. Corridor Waypoints Seed (Delhi-Patna, Delhi-Mumbai, Mumbai-Bengaluru)
insert into public.corridor_waypoints (corridor_id, corridor_name, sequence_idx, city, state, km_from_start, lat, lng) values
  ('delhi_patna', 'Delhi - Agra - Kanpur - Lucknow - Patna', 0, 'Delhi', 'Delhi', 0, 28.6139, 77.2090),
  ('delhi_patna', 'Delhi - Agra - Kanpur - Lucknow - Patna', 1, 'Mathura', 'Uttar Pradesh', 160, 27.4924, 77.6737),
  ('delhi_patna', 'Delhi - Agra - Kanpur - Lucknow - Patna', 2, 'Agra', 'Uttar Pradesh', 215, 27.1767, 78.0081),
  ('delhi_patna', 'Delhi - Agra - Kanpur - Lucknow - Patna', 3, 'Kanpur', 'Uttar Pradesh', 490, 26.4499, 80.3319),
  ('delhi_patna', 'Delhi - Agra - Kanpur - Lucknow - Patna', 4, 'Lucknow', 'Uttar Pradesh', 550, 26.8467, 80.9462),
  ('delhi_patna', 'Delhi - Agra - Kanpur - Lucknow - Patna', 5, 'Prayagraj', 'Uttar Pradesh', 670, 25.4358, 81.8463),
  ('delhi_patna', 'Delhi - Agra - Kanpur - Lucknow - Patna', 6, 'Varanasi', 'Uttar Pradesh', 790, 25.3176, 82.9739),
  ('delhi_patna', 'Delhi - Agra - Kanpur - Lucknow - Patna', 7, 'Patna', 'Bihar', 1050, 25.5941, 85.1376),

  ('delhi_mumbai', 'Delhi - Jaipur - Ahmedabad - Surat - Mumbai', 0, 'Delhi', 'Delhi', 0, 28.6139, 77.2090),
  ('delhi_mumbai', 'Delhi - Jaipur - Ahmedabad - Surat - Mumbai', 1, 'Jaipur', 'Rajasthan', 280, 26.9124, 75.7873),
  ('delhi_mumbai', 'Delhi - Jaipur - Ahmedabad - Surat - Mumbai', 2, 'Ajmer', 'Rajasthan', 415, 26.4499, 74.6399),
  ('delhi_mumbai', 'Delhi - Jaipur - Ahmedabad - Surat - Mumbai', 3, 'Ahmedabad', 'Gujarat', 930, 23.0225, 72.5714),
  ('delhi_mumbai', 'Delhi - Jaipur - Ahmedabad - Surat - Mumbai', 4, 'Vadodara', 'Gujarat', 1040, 22.3072, 73.1812),
  ('delhi_mumbai', 'Delhi - Jaipur - Ahmedabad - Surat - Mumbai', 5, 'Surat', 'Gujarat', 1160, 21.1702, 72.8311),
  ('delhi_mumbai', 'Delhi - Jaipur - Ahmedabad - Surat - Mumbai', 6, 'Vapi', 'Gujarat', 1280, 20.3712, 72.9048),
  ('delhi_mumbai', 'Delhi - Jaipur - Ahmedabad - Surat - Mumbai', 7, 'Mumbai', 'Maharashtra', 1400, 19.0760, 72.8777),

  ('mumbai_bengaluru', 'Mumbai - Pune - Kolhapur - Bengaluru', 0, 'Mumbai', 'Maharashtra', 0, 19.0760, 72.8777),
  ('mumbai_bengaluru', 'Mumbai - Pune - Kolhapur - Bengaluru', 1, 'Pune', 'Maharashtra', 150, 18.5204, 73.8567),
  ('mumbai_bengaluru', 'Mumbai - Pune - Kolhapur - Bengaluru', 2, 'Satara', 'Maharashtra', 265, 17.6805, 74.0183),
  ('mumbai_bengaluru', 'Mumbai - Pune - Kolhapur - Bengaluru', 3, 'Kolhapur', 'Maharashtra', 385, 16.7050, 74.2433),
  ('mumbai_bengaluru', 'Mumbai - Pune - Kolhapur - Bengaluru', 4, 'Belagavi', 'Karnataka', 495, 15.8497, 74.4977),
  ('mumbai_bengaluru', 'Mumbai - Pune - Kolhapur - Bengaluru', 5, 'Hubli', 'Karnataka', 590, 15.3647, 75.1240),
  ('mumbai_bengaluru', 'Mumbai - Pune - Kolhapur - Bengaluru', 6, 'Davanagere', 'Karnataka', 730, 14.4644, 75.9218),
  ('mumbai_bengaluru', 'Mumbai - Pune - Kolhapur - Bengaluru', 7, 'Bengaluru', 'Karnataka', 980, 12.9716, 77.5946)
on conflict (corridor_id, sequence_idx) do nothing;

-- B. Cargo Compatibility Rules Seed
insert into public.cargo_compatibility_rules (cargo_type_a, cargo_type_b, is_compatible, risk_level, restrictions) values
  ('food', 'chemicals', false, 'prohibited', 'Strictly prohibited: Severe chemical contamination hazard'),
  ('chemicals', 'food', false, 'prohibited', 'Strictly prohibited: Severe chemical contamination hazard'),
  ('food', 'fertilizers', false, 'prohibited', 'Prohibited: Toxic odor & contamination'),
  ('fertilizers', 'food', false, 'prohibited', 'Prohibited: Toxic odor & contamination'),
  ('fragile', 'heavy_machinery', false, 'prohibited', 'Prohibited: Heavy vibration and crush hazard'),
  ('heavy_machinery', 'fragile', false, 'prohibited', 'Prohibited: Heavy vibration and crush hazard'),
  ('food', 'fmcg', true, 'safe', 'Fully compatible: Packaged goods with food-grade compliance'),
  ('fmcg', 'food', true, 'safe', 'Fully compatible: Packaged goods with food-grade compliance'),
  ('general', 'general', true, 'safe', 'Fully compatible: Standard dry freight'),
  ('general', 'fmcg', true, 'safe', 'Fully compatible: Standard dry freight'),
  ('general', 'fragile', true, 'warning', 'Conditional: Fragile items must be top-loaded with secure lashing'),
  ('fragile', 'general', true, 'warning', 'Conditional: Fragile items must be top-loaded with secure lashing')
on conflict (cargo_type_a, cargo_type_b) do nothing;

-- C. Pricing Configurations Seed
insert into public.pricing_configurations (corridor_id, corridor_name, base_rate_per_ton_km, min_fare_inr, detour_rate_per_km, platform_commission_pct) values
  ('delhi_patna', 'Delhi - Agra - Kanpur - Lucknow - Patna Corridor', 2.40, 1500, 25.0, 0.08),
  ('delhi_mumbai', 'Delhi - Jaipur - Ahmedabad - Surat - Mumbai Corridor', 2.20, 1500, 25.0, 0.08),
  ('mumbai_bengaluru', 'Mumbai - Pune - Kolhapur - Bengaluru Corridor', 2.30, 1500, 25.0, 0.08),
  ('default', 'Standard All-India Freight Baseline', 2.50, 1200, 25.0, 0.08)
on conflict (corridor_id) do nothing;

-- 7. Row Level Security Policies
alter table public.corridor_waypoints enable row level security;
alter table public.cargo_compatibility_rules enable row level security;
alter table public.pricing_configurations enable row level security;
alter table public.trip_segments enable row level security;
alter table public.disputes enable row level security;

-- Read policies (open for authenticated users and apps)
create policy "Public can read corridor waypoints" on public.corridor_waypoints for select using (true);
create policy "Public can read compatibility rules" on public.cargo_compatibility_rules for select using (true);
create policy "Public can read pricing configurations" on public.pricing_configurations for select using (true);
create policy "Authenticated can read trip segments" on public.trip_segments for select using (true);

-- Disputes: user can see their own disputes, admins can see all
create policy "Users view own disputes" on public.disputes for select using (
  filed_by = auth.uid() or exists (
    select 1 from public.profiles where id = auth.uid() and role = 'admin'
  )
);
create policy "Users create disputes" on public.disputes for insert with check (
  filed_by = auth.uid()
);
