-- 0006: Secure pickup/delivery handover via 4-digit OTPs.
-- The shipper SEES the OTPs (app + website); the driver must enter them.
-- Backend refuses picked_up / delivered until the matching OTP is verified.
alter table public.bookings add column if not exists pickup_otp text;
alter table public.bookings add column if not exists delivery_otp text;
alter table public.bookings add column if not exists pickup_otp_verified_at timestamptz;
alter table public.bookings add column if not exists delivery_otp_verified_at timestamptz;
