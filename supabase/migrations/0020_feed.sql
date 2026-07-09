-- SyncUp — 0020 Feed: permanent friend-only posts (text / image / video)
-- with likes, comments and threaded replies. Visibility follows friendship
-- (reuses are_friends from 0010). Counts are denormalised via triggers; author
-- notifications reuse the notify() helper from 0016.

-- =========================================================
-- tables
-- =========================================================
create table if not exists public.posts (
  id            uuid primary key default gen_random_uuid(),
  author_id     uuid not null references public.profiles(id) on delete cascade,
  kind          text not null check (kind in ('text','image','video')),
  text          text,
  media_url     text,
  media_meta    jsonb,
  like_count    int not null default 0,
  comment_count int not null default 0,
  created_at    timestamptz not null default now()
);
create index if not exists idx_posts_author on public.posts (author_id, created_at desc);
create index if not exists idx_posts_created on public.posts (created_at desc);

create table if not exists public.post_likes (
  post_id    uuid not null references public.posts(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists public.post_comments (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid not null references public.posts(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  parent_id  uuid references public.post_comments(id) on delete cascade, -- null = top-level
  text       text not null,
  created_at timestamptz not null default now()
);
create index if not exists idx_post_comments_post on public.post_comments (post_id, created_at);

-- =========================================================
-- helper: can the current user see this post? (author or their friend)
-- =========================================================
create or replace function public.can_see_post(p_post_id uuid)
returns boolean language sql security definer set search_path = public stable as $$
  select exists (
    select 1 from public.posts p
    where p.id = p_post_id
      and (p.author_id = auth.uid() or public.are_friends(p.author_id))
  );
$$;
grant execute on function public.can_see_post(uuid) to authenticated;

-- =========================================================
-- RLS
-- =========================================================
alter table public.posts enable row level security;
alter table public.post_likes enable row level security;
alter table public.post_comments enable row level security;

drop policy if exists posts_select on public.posts;
create policy posts_select on public.posts
  for select to authenticated
  using (author_id = auth.uid() or public.are_friends(author_id));
drop policy if exists posts_insert on public.posts;
create policy posts_insert on public.posts
  for insert to authenticated with check (author_id = auth.uid());
drop policy if exists posts_delete on public.posts;
create policy posts_delete on public.posts
  for delete to authenticated using (author_id = auth.uid());

drop policy if exists post_likes_select on public.post_likes;
create policy post_likes_select on public.post_likes
  for select to authenticated using (public.can_see_post(post_id));
drop policy if exists post_likes_insert on public.post_likes;
create policy post_likes_insert on public.post_likes
  for insert to authenticated
  with check (user_id = auth.uid() and public.can_see_post(post_id));
drop policy if exists post_likes_delete on public.post_likes;
create policy post_likes_delete on public.post_likes
  for delete to authenticated using (user_id = auth.uid());

drop policy if exists post_comments_select on public.post_comments;
create policy post_comments_select on public.post_comments
  for select to authenticated using (public.can_see_post(post_id));
drop policy if exists post_comments_insert on public.post_comments;
create policy post_comments_insert on public.post_comments
  for insert to authenticated
  with check (user_id = auth.uid() and public.can_see_post(post_id));
drop policy if exists post_comments_delete on public.post_comments;
create policy post_comments_delete on public.post_comments
  for delete to authenticated using (user_id = auth.uid());

-- =========================================================
-- realtime (live likes / comments / new posts)
-- =========================================================
do $$ begin alter publication supabase_realtime add table public.posts;
exception when duplicate_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.post_likes;
exception when duplicate_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.post_comments;
exception when duplicate_object then null; end $$;
alter table public.posts replica identity full;
alter table public.post_likes replica identity full;
alter table public.post_comments replica identity full;

-- =========================================================
-- denormalised counts
-- =========================================================
create or replace function public.tg_post_like_count()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    update public.posts set like_count = like_count + 1 where id = new.post_id;
  elsif tg_op = 'DELETE' then
    update public.posts set like_count = greatest(0, like_count - 1) where id = old.post_id;
  end if;
  return null;
end; $$;
drop trigger if exists trg_post_like_count on public.post_likes;
create trigger trg_post_like_count after insert or delete on public.post_likes
  for each row execute function public.tg_post_like_count();

create or replace function public.tg_post_comment_count()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    update public.posts set comment_count = comment_count + 1 where id = new.post_id;
  elsif tg_op = 'DELETE' then
    update public.posts set comment_count = greatest(0, comment_count - 1) where id = old.post_id;
  end if;
  return null;
end; $$;
drop trigger if exists trg_post_comment_count on public.post_comments;
create trigger trg_post_comment_count after insert or delete on public.post_comments
  for each row execute function public.tg_post_comment_count();

-- =========================================================
-- author / parent notifications
-- =========================================================
create or replace function public.tg_notify_post_like()
returns trigger language plpgsql security definer set search_path = public as $$
declare owner uuid; aname text;
begin
  select author_id into owner from public.posts where id = new.post_id;
  select display_name into aname from public.profiles where id = new.user_id;
  perform public.notify(owner, new.user_id, 'post_like', coalesce(aname,'Someone'),
    'liked your post', jsonb_build_object('post_id', new.post_id));
  return new;
end; $$;
drop trigger if exists trg_notify_post_like on public.post_likes;
create trigger trg_notify_post_like after insert on public.post_likes
  for each row execute function public.tg_notify_post_like();

create or replace function public.tg_notify_post_comment()
returns trigger language plpgsql security definer set search_path = public as $$
declare owner uuid; parent_owner uuid; aname text;
begin
  select display_name into aname from public.profiles where id = new.user_id;
  select author_id into owner from public.posts where id = new.post_id;
  if new.parent_id is not null then
    select user_id into parent_owner from public.post_comments where id = new.parent_id;
    perform public.notify(parent_owner, new.user_id, 'comment_reply', coalesce(aname,'Someone'),
      'replied to your comment', jsonb_build_object('post_id', new.post_id));
  end if;
  -- always tell the post author about a new comment (unless they made it, or it's their own reply already sent)
  if new.parent_id is null or parent_owner is distinct from owner then
    perform public.notify(owner, new.user_id, 'post_comment', coalesce(aname,'Someone'),
      'commented on your post', jsonb_build_object('post_id', new.post_id));
  end if;
  return new;
end; $$;
drop trigger if exists trg_notify_post_comment on public.post_comments;
create trigger trg_notify_post_comment after insert on public.post_comments
  for each row execute function public.tg_notify_post_comment();

-- =========================================================
-- storage bucket for post media (public read; write to own folder).
-- Post rows are friend-gated, so non-friends never receive the media URL.
-- =========================================================
insert into storage.buckets (id, name, public)
  values ('posts', 'posts', true) on conflict (id) do nothing;

drop policy if exists "posts read" on storage.objects;
create policy "posts read" on storage.objects
  for select using (bucket_id = 'posts');
drop policy if exists "posts insert own" on storage.objects;
create policy "posts insert own" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'posts' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "posts delete own" on storage.objects;
create policy "posts delete own" on storage.objects
  for delete to authenticated
  using (bucket_id = 'posts' and (storage.foldername(name))[1] = auth.uid()::text);
