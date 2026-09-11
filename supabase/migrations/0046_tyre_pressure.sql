-- Rider App Transformation — 0046 Tyre Pressure
-- Log tyre pressure checks.

create table if not exists public.tyre_pressure_logs (
  id              uuid primary key default gen_random_uuid(),
  bike_id         uuid not null references public.bikes(id) on delete cascade,
  front_psi       float,
  rear_psi        float,
  checked_at      timestamptz not null default now()
);

alter table public.tyre_pressure_logs enable row level security;

create policy "tyre_owner_all" on public.tyre_pressure_logs for all to authenticated
  using (exists (select 1 from public.bikes where id = bike_id and owner_id = auth.uid()));
