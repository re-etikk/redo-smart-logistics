-- FCM registration tokens: each authenticated user can manage only their own devices.
create table if not exists public.user_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  fcm_token text not null unique,
  platform text not null default 'android'
    check (platform in ('android', 'ios', 'web')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists user_devices_user_id_idx
  on public.user_devices(user_id);

alter table public.user_devices enable row level security;
drop policy if exists user_devices_owner_all on public.user_devices;
create policy user_devices_owner_all on public.user_devices
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

grant select, insert, update, delete on public.user_devices to authenticated;
grant all on public.user_devices to service_role;