-- SyncUp — 0033 Notes
create table if not exists public.user_notes (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  content     text not null check (char_length(content) <= 60),
  created_at  timestamptz not null default now(),
  unique(user_id)
);
alter table public.user_notes enable row level security;
create policy "notes_select" on public.user_notes for select to authenticated using (true);
create policy "notes_all" on public.user_notes for all to authenticated using (user_id = auth.uid());
