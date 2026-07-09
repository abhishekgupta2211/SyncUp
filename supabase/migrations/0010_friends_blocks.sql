-- LoveChat — 0010 friend requests + blocking
-- Chat is now gated on an ACCEPTED friendship; blocked users can't interact.

-- =========================================================
-- friendships (directional request; accepted = friends both ways)
-- =========================================================
create table if not exists public.friendships (
  id            uuid primary key default gen_random_uuid(),
  requester_id  uuid not null references public.profiles(id) on delete cascade,
  addressee_id  uuid not null references public.profiles(id) on delete cascade,
  status        text not null default 'pending' check (status in ('pending','accepted')),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  unique (requester_id, addressee_id),
  check (requester_id <> addressee_id)
);
create index if not exists idx_friendships_addressee on public.friendships (addressee_id, status);
create index if not exists idx_friendships_requester on public.friendships (requester_id, status);

create table if not exists public.user_blocks (
  blocker_id  uuid not null references public.profiles(id) on delete cascade,
  blocked_id  uuid not null references public.profiles(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (blocker_id, blocked_id)
);

-- =========================================================
-- helpers
-- =========================================================
create or replace function public.are_friends(other_user uuid)
returns boolean language sql security definer set search_path = public stable as $$
  select exists (
    select 1 from public.friendships f
    where f.status = 'accepted'
      and ((f.requester_id = auth.uid() and f.addressee_id = other_user)
        or (f.requester_id = other_user and f.addressee_id = auth.uid()))
  );
$$;
grant execute on function public.are_friends(uuid) to authenticated;

create or replace function public.is_blocked_between(other_user uuid)
returns boolean language sql security definer set search_path = public stable as $$
  select exists (
    select 1 from public.user_blocks b
    where (b.blocker_id = auth.uid() and b.blocked_id = other_user)
       or (b.blocker_id = other_user and b.blocked_id = auth.uid())
  );
$$;
grant execute on function public.is_blocked_between(uuid) to authenticated;

-- relationship label for the search UI
create or replace function public.relationship_with(other_user uuid)
returns text language plpgsql security definer set search_path = public stable as $$
declare me uuid := auth.uid();
begin
  if public.is_blocked_between(other_user) then return 'blocked'; end if;
  if public.are_friends(other_user) then return 'friends'; end if;
  if exists (select 1 from public.friendships where requester_id=me and addressee_id=other_user and status='pending') then return 'pending_out'; end if;
  if exists (select 1 from public.friendships where requester_id=other_user and addressee_id=me and status='pending') then return 'pending_in'; end if;
  return 'none';
end; $$;
grant execute on function public.relationship_with(uuid) to authenticated;

-- =========================================================
-- RPCs
-- =========================================================
create or replace function public.send_friend_request(addressee uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if addressee = auth.uid() then raise exception 'cannot friend yourself'; end if;
  if public.is_blocked_between(addressee) then raise exception 'blocked'; end if;
  if public.are_friends(addressee) then return; end if;
  -- if they already sent me a request, accept it
  if exists (select 1 from public.friendships where requester_id=addressee and addressee_id=auth.uid() and status='pending') then
    update public.friendships set status='accepted', updated_at=now()
      where requester_id=addressee and addressee_id=auth.uid();
    return;
  end if;
  insert into public.friendships (requester_id, addressee_id, status)
  values (auth.uid(), addressee, 'pending')
  on conflict (requester_id, addressee_id) do nothing;
end; $$;
grant execute on function public.send_friend_request(uuid) to authenticated;

create or replace function public.accept_friend_request(requester uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.friendships set status='accepted', updated_at=now()
    where requester_id=requester and addressee_id=auth.uid() and status='pending';
end; $$;
grant execute on function public.accept_friend_request(uuid) to authenticated;

create or replace function public.block_user(target uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if target = auth.uid() then return; end if;
  insert into public.user_blocks (blocker_id, blocked_id) values (auth.uid(), target)
    on conflict do nothing;
  delete from public.friendships
    where (requester_id=auth.uid() and addressee_id=target)
       or (requester_id=target and addressee_id=auth.uid());
end; $$;
grant execute on function public.block_user(uuid) to authenticated;

create or replace function public.unblock_user(target uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  delete from public.user_blocks where blocker_id=auth.uid() and blocked_id=target;
end; $$;
grant execute on function public.unblock_user(uuid) to authenticated;

-- =========================================================
-- RLS for the new tables
-- =========================================================
alter table public.friendships enable row level security;
alter table public.user_blocks enable row level security;

drop policy if exists friendships_select on public.friendships;
create policy friendships_select on public.friendships
  for select to authenticated
  using (requester_id = auth.uid() or addressee_id = auth.uid());

drop policy if exists friendships_insert on public.friendships;
create policy friendships_insert on public.friendships
  for insert to authenticated with check (requester_id = auth.uid());

drop policy if exists friendships_delete on public.friendships;
create policy friendships_delete on public.friendships
  for delete to authenticated
  using (requester_id = auth.uid() or addressee_id = auth.uid());

drop policy if exists blocks_select on public.user_blocks;
create policy blocks_select on public.user_blocks
  for select to authenticated using (blocker_id = auth.uid());
drop policy if exists blocks_insert on public.user_blocks;
create policy blocks_insert on public.user_blocks
  for insert to authenticated with check (blocker_id = auth.uid());
drop policy if exists blocks_delete on public.user_blocks;
create policy blocks_delete on public.user_blocks
  for delete to authenticated using (blocker_id = auth.uid());

-- realtime for live request/accept updates
do $$ begin alter publication supabase_realtime add table public.friendships;
exception when duplicate_object then null; end $$;
alter table public.friendships replica identity full;

-- =========================================================
-- Gate chat creation on friendship + not-blocked
-- =========================================================
create or replace function public.get_or_create_conversation(other_user_id uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid(); a uuid; b uuid; key text; conv uuid;
begin
  if me is null then raise exception 'not authenticated'; end if;
  if other_user_id = me then raise exception 'cannot DM yourself'; end if;
  if not exists (select 1 from public.profiles where id = other_user_id) then
    raise exception 'target user does not exist'; end if;
  if public.is_blocked_between(other_user_id) then raise exception 'blocked'; end if;
  if not public.are_friends(other_user_id) then raise exception 'not friends'; end if;

  a := least(me, other_user_id); b := greatest(me, other_user_id);
  key := a::text || ':' || b::text;
  insert into public.conversations (is_group, dm_key, created_by)
  values (false, key, me) on conflict (dm_key) do nothing returning id into conv;
  if conv is null then
    select id into conv from public.conversations where dm_key = key;
  else
    insert into public.conversation_participants (conversation_id, user_id)
    values (conv, a), (conv, b) on conflict do nothing;
  end if;
  return conv;
end; $$;

-- =========================================================
-- Stories now follow FRIENDSHIP (not just shared conversations)
-- =========================================================
create or replace function public.can_view_story(p_story_id uuid)
returns boolean language sql security definer set search_path = public stable as $$
  select exists (
    select 1 from public.stories s
    where s.id = p_story_id
      and (s.user_id = auth.uid() or public.are_friends(s.user_id))
  );
$$;

drop policy if exists stories_select on public.stories;
create policy stories_select on public.stories
  for select to authenticated
  using (user_id = auth.uid() or public.are_friends(user_id));

drop policy if exists story_views_insert on public.story_views;
create policy story_views_insert on public.story_views
  for insert to authenticated
  with check (
    viewer_id = auth.uid()
    and exists (select 1 from public.stories s
                where s.id = story_id
                  and (s.user_id = auth.uid() or public.are_friends(s.user_id)))
  );

-- =========================================================
-- search excludes blocked users
-- =========================================================
create or replace function public.search_users(
  q text, cursor_id uuid default null, page_size int default 20
) returns setof public.profiles
language sql stable security definer set search_path = public as $$
  select p.*
  from public.profiles p
  where p.id <> auth.uid()
    and not public.is_blocked_between(p.id)
    and (
      lower(p.username) like '%'||lower(q)||'%'
      or lower(p.display_name) like '%'||lower(q)||'%'
      or p.phone like '%'||q||'%'
    )
    and (cursor_id is null or p.id > cursor_id)
  order by p.id
  limit greatest(1, least(page_size, 50));
$$;
grant execute on function public.search_users(text, uuid, int) to authenticated;
