-- LoveChat — 0009 story likes + comments

-- Can the current user see a given story? (author or a conversation-mate)
create or replace function public.can_view_story(p_story_id uuid)
returns boolean
language sql security definer set search_path = public stable as $$
  select exists (
    select 1 from public.stories s
    where s.id = p_story_id
      and (s.user_id = auth.uid() or public.users_share_conversation(s.user_id))
  );
$$;
revoke all on function public.can_view_story(uuid) from public;
grant execute on function public.can_view_story(uuid) to authenticated;

-- =========================================================
-- story_likes
-- =========================================================
create table if not exists public.story_likes (
  story_id   uuid not null references public.stories(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (story_id, user_id)
);
create index if not exists idx_story_likes_story on public.story_likes (story_id);

-- =========================================================
-- story_comments
-- =========================================================
create table if not exists public.story_comments (
  id         uuid primary key default gen_random_uuid(),
  story_id   uuid not null references public.stories(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  text       text not null,
  created_at timestamptz not null default now()
);
create index if not exists idx_story_comments_story
  on public.story_comments (story_id, created_at);

alter table public.story_likes    enable row level security;
alter table public.story_comments enable row level security;

-- ---- story_likes RLS ----
drop policy if exists story_likes_select on public.story_likes;
create policy story_likes_select on public.story_likes
  for select to authenticated using (public.can_view_story(story_id));

drop policy if exists story_likes_insert on public.story_likes;
create policy story_likes_insert on public.story_likes
  for insert to authenticated
  with check (user_id = auth.uid() and public.can_view_story(story_id));

drop policy if exists story_likes_delete on public.story_likes;
create policy story_likes_delete on public.story_likes
  for delete to authenticated using (user_id = auth.uid());

-- ---- story_comments RLS ----
drop policy if exists story_comments_select on public.story_comments;
create policy story_comments_select on public.story_comments
  for select to authenticated using (public.can_view_story(story_id));

drop policy if exists story_comments_insert on public.story_comments;
create policy story_comments_insert on public.story_comments
  for insert to authenticated
  with check (user_id = auth.uid() and public.can_view_story(story_id));

drop policy if exists story_comments_delete on public.story_comments;
create policy story_comments_delete on public.story_comments
  for delete to authenticated
  using (
    user_id = auth.uid()
    or exists (select 1 from public.stories s
               where s.id = story_id and s.user_id = auth.uid())
  );

-- ---- realtime ----
do $$ begin
  alter publication supabase_realtime add table public.story_likes;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.story_comments;
exception when duplicate_object then null; end $$;
alter table public.story_likes    replica identity full;
alter table public.story_comments replica identity full;
