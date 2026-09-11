-- Rider App Transformation — 0043 Fuel Logs
-- Track fuel expenses for motorcycles.

create table if not exists public.fuel_logs (
  id              uuid primary key default gen_random_uuid(),
  bike_id         uuid not null references public.bikes(id) on delete cascade,
  amount          float not null,
  liters          float,
  odometer        int,
  fuel_date       timestamptz not null default now(),
  created_at      timestamptz not null default now()
);

alter table public.fuel_logs enable row level security;

create policy "fuel_owner_all" on public.fuel_logs for all to authenticated
  using (exists (select 1 from public.bikes where id = bike_id and owner_id = auth.uid()));
