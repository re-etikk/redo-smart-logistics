-- 0004_real_reputation.sql
-- "Sab real": brand-new trucks must not carry fabricated reputation.
-- Reputation columns become nullable with NO defaults; the UI shows "New"
-- until real ratings exist, and the ML uses documented neutral priors
-- internally (never shown to users).

alter table public.trucks alter column driver_rating drop default;
alter table public.trucks alter column on_time_rate drop default;
alter table public.trucks alter column cancel_rate drop default;
alter table public.trucks alter column driver_rating drop not null;
alter table public.trucks alter column on_time_rate drop not null;
alter table public.trucks alter column cancel_rate drop not null;

-- Null-out reputation that was only ever the old column default
-- (i.e. trucks that never received a real rating). Demo (T-DEMO-1) and
-- synthetic (SEED-%) trucks keep their labeled demo stats.
update public.trucks t
set driver_rating = null, on_time_rate = null, cancel_rate = null
where t.truck_id not like 'SEED-%'
  and t.truck_id <> 'T-DEMO-1'
  and not exists (
    select 1 from public.ratings r
    join public.bookings b on b.id = r.booking_id
    where b.truck_id = t.truck_id
  );
