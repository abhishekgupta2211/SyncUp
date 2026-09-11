-- Rider App Transformation — 0045 Bike Documents
-- Store insurance, PUC, and registration photos securely.

create table if not exists public.bike_documents (
  id              uuid primary key default gen_random_uuid(),
  bike_id         uuid not null references public.bikes(id) on delete cascade,
  doc_type        text not null, -- insurance, puc, registration
  image_url       text not null,
  expiry_date     date,
  created_at      timestamptz not null default now()
);

alter table public.bike_documents enable row level security;

create policy "docs_owner_all" on public.bike_documents for all to authenticated
  using (exists (select 1 from public.bikes where id = bike_id and owner_id = auth.uid()));
