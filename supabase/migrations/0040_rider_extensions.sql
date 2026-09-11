-- Rider App Transformation — 0040 Rider Extensions
-- Extends profiles and adds bikes/maintenance tables.

-- 1. Extend profiles for Rider details
alter table public.profiles
add column if not exists riding_style text,
add column if not exists experience_years int default 0,
add column if not exists total_distance_km float default 0.0,
add column if not exists total_rides int default 0;

-- 2. Create bikes table (Garage)
create table if not exists public.bikes (
  id           uuid primary key default gen_random_uuid(),
  owner_id     uuid not null references public.profiles(id) on delete cascade,
  brand        text not null,
  model        text not null,
  year         int,
  engine_cc    int,
  color        text,
  nickname     text,
  image_url    text,
  odometer     int default 0,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- 3. Create maintenance table
create table if not exists public.bike_maintenance (
  id              uuid primary key default gen_random_uuid(),
  bike_id         uuid not null references public.bikes(id) on delete cascade,
  service_type    text not null, -- oil_change, chain_service, etc.
  service_date    date not null default current_date,
  odometer_at     int,
  cost            float,
  notes           text,
  next_service_at int, -- odometer value for next service
  created_at      timestamptz not null default now()
);

-- 4. RLS for new tables
alter table public.bikes enable row level security;
alter table public.bike_maintenance enable row level security;

create policy "bikes_owner_all" on public.bikes for all to authenticated using (owner_id = auth.uid());
create policy "bikes_public_select" on public.bikes for select to authenticated using (true);

create policy "maintenance_owner_all" on public.bike_maintenance for all to authenticated
  using (exists (select 1 from public.bikes where id = bike_id and owner_id = auth.uid()));

-- 5. Helper function for ride stats
create or replace function public.increment_rider_stats(p_km float)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.profiles
  set total_distance_km = total_distance_km + p_km,
      total_rides = total_rides + 1
  where id = auth.uid();
end; $$;
