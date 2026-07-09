-- LoveChat — 0015 RE-GATE chat behind an accepted friendship (+ block)
--
-- 0012 had ungated chat ("friend-request UI isn't built yet"). The UI now exists,
-- so we close the gate again — at TWO levels:
--   (a) creation gate: get_or_create_conversation only makes a DM between friends
--   (b) DURABLE gate: a message-level RLS check, so blocking/unfriending stops
--       messages even on a conversation that already exists.
-- Plus a one-time backfill so every EXISTING 1:1 chat becomes an accepted
-- friendship (existing chats keep working instead of breaking with "not friends").

-- =========================================================
-- (0) Backfill: existing 1:1 conversations => accepted friendship
-- =========================================================
insert into public.friendships (requester_id, addressee_id, status)
select least(p1.user_id, p2.user_id),
       greatest(p1.user_id, p2.user_id),
       'accepted'
from public.conversation_participants p1
join public.conversation_participants p2
  on p1.conversation_id = p2.conversation_id
 and p1.user_id < p2.user_id
join public.conversations c
  on c.id = p1.conversation_id and c.is_group = false
on conflict (requester_id, addressee_id) do nothing;

-- =========================================================
-- (a) creation gate — friends only, not blocked
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
-- (b) durable message gate — survives a pre-existing DM
-- =========================================================
-- True if the caller may message this conversation: groups => participants;
-- 1:1 => the OTHER member must be an accepted friend and not blocked.
create or replace function public.can_message_conversation(p_conversation_id uuid)
returns boolean language sql security definer set search_path = public stable as $$
  select case
    when coalesce((select is_group from public.conversations where id = p_conversation_id), false)
      then true
    else exists (
      select 1 from public.conversation_participants other
      where other.conversation_id = p_conversation_id
        and other.user_id <> auth.uid()
        and public.are_friends(other.user_id)
        and not public.is_blocked_between(other.user_id)
    )
  end;
$$;
grant execute on function public.can_message_conversation(uuid) to authenticated;

-- re-create msg_insert to also require the friendship/block gate
drop policy if exists msg_insert on public.messages;
create policy msg_insert on public.messages
  for insert to authenticated
  with check (
    sender_id = auth.uid()
    and public.is_conversation_participant(conversation_id, auth.uid())
    and public.can_message_conversation(conversation_id)
  );

-- realtime for blocks so the home chat list can hide a blocked peer instantly
do $$ begin alter publication supabase_realtime add table public.user_blocks;
exception when duplicate_object then null; end $$;
alter table public.user_blocks replica identity full;
