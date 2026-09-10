-- 0009_customer_profile_kyc.sql
-- Adds columns to profiles table for customer business verification & legal KYC

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS gstin text,
  ADD COLUMN IF NOT EXISTS pan_number text,
  ADD COLUMN IF NOT EXISTS business_address text;
