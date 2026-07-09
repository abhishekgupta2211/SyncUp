-- SyncUp — 0016 in-app notification center
-- A notifications table + RLS (recipient reads/updates/deletes own; rows are
-- created only by SECURITY DEFINER triggers) + realtime + auto-create triggers.

create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade, -- recipient
  actor_id   uuid references public.profiles(id) on delete cascade,          -- who triggered it
  type       text not null,      -- friend_request | friend_accept | story_like | story_comment | reaction | call
  title      text not null,
  body       text,
  data       jsonb,
  read       boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists idx_notifications_user
  on public.notifications (user_id, created_at desc);

alter table public.notifications enable row level security;

drop policy if exists notif_select on public.notifications;
create policy notif_select on public.notifications
  for select to authenticated using (user_id = auth.uid());
drop policy if exists notif_update on public.notifications;
create policy notif_update on public.notifications
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists notif_delete on public.notifications;
create policy notif_delete on public.notifications
  for delete to authenticated using (user_id = auth.uid());
-- no insert policy: only the SECURITY DEFINER helper below writes rows.

do $$ begin alter publication supabase_realtime add table public.notifications;
exception when duplicate_object then null; end $$;
alter table public.notifications replica identity full;

-- helper: create a notification (never notify yourself)
create or replace function public.notify(
  p_user uuid, p_actor uuid, p_type text, p_title text,
  p_body text default null, p_data jsonb default null
) returns void language sql security definer set search_path = public as $$
  insert into public.notifications (user_id, actor_id, type, title, body, data)
  select p_user, p_actor, p_type, p_title, p_body, p_data
  where p_user is not null and (p_actor is null or p_user <> p_actor);
$$;

-- ---- triggers ----
create or replace function public.tg_notify_friend_request()
returns trigger language plpgsql security definer set search_path = public as $$
declare aname text;
begin
  if new.status = 'pending' then
    select display_name into aname from public.profiles where id = new.requester_id;
    perform public.notify(new.addressee_id, new.requester_id, 'friend_request',
      coalesce(aname,'Someone'), 'sent you a friend request');
  end if;
  return new;
end; $$;
drop trigger if exists trg_notify_friend_request on public.friendships;
create trigger trg_notify_friend_request after insert on public.friendships
  for each row execute function public.tg_notify_friend_request();

create or replace function public.tg_notify_friend_accept()
returns trigger language plpgsql security definer set search_path = public as $$
declare aname text;
begin
  if new.status = 'accepted' and old.status = 'pending' then
    select display_name into aname from public.profiles where id = new.addressee_id;
    perform public.notify(new.requester_id, new.addressee_id, 'friend_accept',
      coalesce(aname,'Someone'), 'accepted your friend request');
  end if;
  return new;
end; $$;
drop trigger if exists trg_notify_friend_accept on public.friendships;
create trigger trg_notify_friend_accept after update on public.friendships
  for each row execute function public.tg_notify_friend_accept();

create or replace function public.tg_notify_story_like()
returns trigger language plpgsql security definer set search_path = public as $$
declare owner uuid; aname text;
begin
  select user_id into owner from public.stories where id = new.story_id;
  select display_name into aname from public.profiles where id = new.user_id;
  perform public.notify(owner, new.user_id, 'story_like',
    coalesce(aname,'Someone'), 'liked your story');
  return new;
end; $$;
drop trigger if exists trg_notify_story_like on public.story_likes;
create trigger trg_notify_story_like after insert on public.story_likes
  for each row execute function public.tg_notify_story_like();

create or replace function public.tg_notify_story_comment()
returns trigger language plpgsql security definer set search_path = public as $$
declare owner uuid; aname text;
begin
  select user_id into owner from public.stories where id = new.story_id;
  select display_name into aname from public.profiles where id = new.user_id;
  perform public.notify(owner, new.user_id, 'story_comment',
    coalesce(aname,'Someone'), 'commented on your story');
  return new;
end; $$;
drop trigger if exists trg_notify_story_comment on public.story_comments;
create trigger trg_notify_story_comment after insert on public.story_comments
  for each row execute function public.tg_notify_story_comment();

create or replace function public.tg_notify_reaction()
returns trigger language plpgsql security definer set search_path = public as $$
declare owner uuid; aname text;
begin
  select sender_id into owner from public.messages where id = new.message_id;
  select display_name into aname from public.profiles where id = new.user_id;
  perform public.notify(owner, new.user_id, 'reaction',
    coalesce(aname,'Someone'), 'reacted ' || coalesce(new.emoji,'') || ' to your message');
  return new;
end; $$;
drop trigger if exists trg_notify_reaction on public.message_reactions;
create trigger trg_notify_reaction after insert on public.message_reactions
  for each row execute function public.tg_notify_reaction();

create or replace function public.tg_notify_call()
returns trigger language plpgsql security definer set search_path = public as $$
declare aname text;
begin
  select display_name into aname from public.profiles where id = new.caller_id;
  perform public.notify(new.callee_id, new.caller_id, 'call',
    coalesce(aname,'Someone'),
    (case when new.type = 'video' then 'video' else 'voice' end) || ' call');
  return new;
end; $$;
drop trigger if exists trg_notify_call on public.call_logs;
create trigger trg_notify_call after insert on public.call_logs
  for each row execute function public.tg_notify_call();
