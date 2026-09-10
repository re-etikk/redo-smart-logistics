-- Fixes: "profile complete hoti nahi / truck register + load booking issue"
--
-- Root cause: redo_customer and redo_partner share the SAME `profiles` row
-- per user id, but both apps were reading/writing ONE shared boolean
-- (`onboarding_complete`) to mean two different things ("finished customer
-- business-profile setup" vs "finished driver+truck KYC setup"). If the same
-- email was used to log into both apps, whichever app's onboarding finished
-- FIRST would mark the flag true, and the other app would then skip its own
-- onboarding entirely — e.g. a driver never actually got to register a
-- truck, so there was nothing to match loads against.
--
-- Fix: give the partner app its own dedicated completion flag.

alter table public.profiles
  add column if not exists partner_onboarding_complete boolean default false;

-- Backfill: any row that is already a truck_owner AND has at least one truck
-- registered is clearly a driver who finished onboarding previously —
-- don't force them back through the stepper.
update public.profiles p
set partner_onboarding_complete = true
where p.role = 'truck_owner'
  and exists (select 1 from public.trucks t where t.owner_id = p.id)
  and p.partner_onboarding_complete is distinct from true;

-- Keep the auto-profile trigger from 0007 in sync (defaults both flags false
-- for brand new users; harmless no-op if the function already looks like this).
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, role, onboarding_complete, partner_onboarding_complete)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(coalesce(new.email, 'User'), '@', 1)),
    coalesce(new.raw_user_meta_data->>'role', 'truck_owner'),
    false,
    false
  )
  on conflict (id) do update set
    full_name = coalesce(excluded.full_name, profiles.full_name);
  return new;
end;
$$ language plpgsql security definer;
