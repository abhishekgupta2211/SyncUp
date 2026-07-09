-- LoveChat — 0032 Post Bookmarks
-- Saves posts for later viewing.

create table if not exists public.post_bookmarks (
  user_id    uuid not null references public.profiles(id) on delete cascade,
  post_id    uuid not null references public.posts(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, post_id)
);

alter table public.post_bookmarks enable row level security;
create policy "bookmarks_all" on public.post_bookmarks for all to authenticated using (user_id = auth.uid());
