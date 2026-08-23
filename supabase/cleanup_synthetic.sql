-- cleanup_synthetic.sql
-- Run this ONCE in the Supabase SQL editor to remove every piece of
-- synthetic marketplace data from an existing database, so only real
-- user-created records remain. Demo login accounts stay (they are real
-- auth users) — but their pre-seeded truck/trip go away too if you also
-- run the optional block at the bottom.

-- 1) Synthetic CSV trucks (SEED-…) and everything hanging off them
delete from public.tracking_events
where booking_id in (
  select b.id from public.bookings b where b.truck_id like 'SEED-%'
);
delete from public.digital_proof
where booking_id in (
  select b.id from public.bookings b where b.truck_id like 'SEED-%'
);
delete from public.booking_events
where booking_id in (
  select b.id from public.bookings b where b.truck_id like 'SEED-%'
);
delete from public.impact_records
where booking_id in (
  select b.id from public.bookings b where b.truck_id like 'SEED-%'
);
delete from public.bookings where truck_id like 'SEED-%';
delete from public.truck_trips where truck_id like 'SEED-%';
delete from public.trucks where truck_id like 'SEED-%';

-- 2) Remove fabricated reputation from real trucks that were created
--    before migration 0004 (they inherited the old column defaults).
update public.trucks t
set driver_rating = null, on_time_rate = null, cancel_rate = null
where t.truck_id not like 'SEED-%'
  and t.truck_id <> 'T-DEMO-1'
  and not exists (
    select 1 from public.ratings r
    join public.bookings b on b.id = r.booking_id
    where b.truck_id = t.truck_id
  );

-- 3) OPTIONAL — also remove the demo owner's pre-seeded truck and trip.
--    Uncomment if you want demo accounts to start completely empty as well.
-- delete from public.truck_trips where truck_id = 'T-DEMO-1';
-- delete from public.trucks where truck_id = 'T-DEMO-1';

-- Verify what's left:
select truck_id, owner_id, driver_rating, on_time_rate, status from public.trucks order by truck_id;
