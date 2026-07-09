-- LoveChat — 0007 stories (24h status) + view tracking

-- Do two users share at least one conversation? (defines "friend" for stories)
create or replace function public.users_share_conversation(other_user uuid)
returns boolean
language sql security definer set search_path = public stable as $$
  select exists (
    select 1
    from public.conversation_participants p1
    join public.conversation_participants p2
      on p1.conversation_id = p2.conversation_id
    where p1.user_id = auth.uid()
      and p2.user_id = other_user
  );
$$;
revoke all on function public.users_share_conversation(uuid) from public;
grant execute on function public.users_share_conversation(uuid) to authenticated;

-- =========================================================
-- stories  (one row per image segment; expires in 24h)
-- =========================================================
create table if not exists public.stories (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  media_url   text not null,
  media_type  text not null default 'image',
  caption     text,
  created_at  timestamptz not null default now(),
  expires_at  timestamptz not null default (now() + interval '24 hours')
);
create index if not exists idx_stories_user_created
  on public.stories (user_id, created_at desc);
create index if not exists idx_stories_expires on public.stories (expires_at);

-- =========================================================
-- story_views  (who viewed which story)
-- =========================================================
create table if not exists public.story_views (
  story_id   uuid not null references public.stories(id) on delete cascade,
  viewer_id  uuid not null references public.profiles(id) on delete cascade,
  viewed_at  timestamptz not null default now(),
  primary key (story_id, viewer_id)
);
create index if not exists idx_story_views_story on public.story_views (story_id);

alter table public.stories      enable row level security;
alter table public.story_views  enable row level security;

-- ---- stories RLS ----
drop policy if exists stories_select on public.stories;
create policy stories_select on public.stories
  for select to authenticated
  using (
    user_id = auth.uid()
    or public.users_share_conversation(user_id)
  );

drop policy if exists stories_insert on public.stories;
create policy stories_insert on public.stories
  for insert to authenticated with check (user_id = auth.uid());

drop policy if exists stories_delete on public.stories;
create policy stories_delete on public.stories
  for delete to authenticated using (user_id = auth.uid());

-- ---- story_views RLS ----
-- The story author can see all viewers; a viewer can see their own view rows.
drop policy if exists story_views_select on public.story_views;
create policy story_views_select on public.story_views
  for select to authenticated
  using (
    viewer_id = auth.uid()
    or exists (
      select 1 from public.stories s
      where s.id = story_id and s.user_id = auth.uid()
    )
  );

drop policy if exists story_views_insert on public.story_views;
create policy story_views_insert on public.story_views
  for insert to authenticated
  with check (
    viewer_id = auth.uid()
    and exists (
      select 1 from public.stories s
      where s.id = story_id
        and (s.user_id = auth.uid() or public.users_share_conversation(s.user_id))
    )
  );

-- ---- realtime ----
do $$ begin
  alter publication supabase_realtime add table public.stories;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.story_views;
exception when duplicate_object then null; end $$;
alter table public.stories     replica identity full;
alter table public.story_views replica identity full;

-- =========================================================
-- storage: stories bucket (public read, owner writes own folder)
-- =========================================================
insert into storage.buckets (id, name, public)
values ('stories', 'stories', true)
on conflict (id) do nothing;

drop policy if exists stories_read on storage.objects;
create policy stories_read on storage.objects
  for select to authenticated using (bucket_id = 'stories');

drop policy if exists stories_write on storage.objects;
create policy stories_write on storage.objects
  for insert to authenticated
  with check (bucket_id = 'stories'
    and (storage.foldername(name))[1] = auth.uid()::text);
