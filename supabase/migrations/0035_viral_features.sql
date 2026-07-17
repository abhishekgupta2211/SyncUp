-- SyncUp — 0035 Viral features
create table if not exists public.anonymous_messages (
  id          uuid primary key default gen_random_uuid(),
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  content     text not null,
  created_at  timestamptz not null default now()
);
alter table public.anonymous_messages enable row level security;
create policy "anon_select" on public.anonymous_messages for select to authenticated using (receiver_id = auth.uid());
create policy "anon_insert" on public.anonymous_messages for insert to authenticated with check (true);
alter table public.profiles add column if not exists profile_skin text default 'default';
