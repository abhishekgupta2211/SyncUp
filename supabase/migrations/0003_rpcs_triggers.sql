-- LoveChat — 0003 RPCs & triggers

-- ---- Auto-touch updated_at ----
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

drop trigger if exists trg_touch_profiles on public.profiles;
create trigger trg_touch_profiles before update on public.profiles
  for each row execute function public.touch_updated_at();

drop trigger if exists trg_touch_messages on public.messages;
create trigger trg_touch_messages before update on public.messages
  for each row execute function public.touch_updated_at();

-- ---- On new message: denormalize preview + bump unread for the other side ----
create or replace function public.on_message_insert()
returns trigger language plpgsql security definer
set search_path = public as $$
begin
  update public.conversations c
     set last_message_id   = new.id,
         last_message_text = case when new.message_type = 'text'
                                  then new.message
                                  else '[' || new.message_type || ']' end,
         last_message_type = new.message_type::text,
         last_message_at   = new.created_at,
         updated_at        = now()
   where c.id = new.conversation_id;

  update public.conversation_participants p
     set unread_count = p.unread_count + 1
   where p.conversation_id = new.conversation_id
     and p.user_id <> new.sender_id;

  return new;
end;
$$;

drop trigger if exists trg_on_message_insert on public.messages;
create trigger trg_on_message_insert
  after insert on public.messages
  for each row execute function public.on_message_insert();

-- ---- Mark a conversation read (drives heart ♡→🩷 + clears unread) ----
create or replace function public.mark_conversation_read(p_conversation_id uuid)
returns void language plpgsql security definer
set search_path = public as $$
begin
  if not public.is_conversation_participant(p_conversation_id, auth.uid()) then
    raise exception 'not a participant';
  end if;

  update public.messages
     set seen = true, delivered = true, seen_at = now(), updated_at = now()
   where conversation_id = p_conversation_id
     and receiver_id = auth.uid()
     and seen = false
     and deleted_for_everyone = false;

  update public.conversation_participants
     set unread_count = 0, last_read_at = now()
   where conversation_id = p_conversation_id
     and user_id = auth.uid();
end;
$$;
grant execute on function public.mark_conversation_read(uuid) to authenticated;

-- ---- Race-safe get-or-create 1:1 conversation ----
create or replace function public.get_or_create_conversation(other_user_id uuid)
returns uuid
language plpgsql security definer
set search_path = public as $$
declare
  me   uuid := auth.uid();
  a    uuid;
  b    uuid;
  key  text;
  conv uuid;
begin
  if me is null then raise exception 'not authenticated'; end if;
  if other_user_id = me then raise exception 'cannot DM yourself'; end if;
  if not exists (select 1 from public.profiles where id = other_user_id) then
    raise exception 'target user does not exist';
  end if;

  a := least(me, other_user_id);
  b := greatest(me, other_user_id);
  key := a::text || ':' || b::text;

  insert into public.conversations (is_group, dm_key, created_by)
  values (false, key, me)
  on conflict (dm_key) do nothing
  returning id into conv;

  if conv is null then
    select id into conv from public.conversations where dm_key = key;
  else
    insert into public.conversation_participants (conversation_id, user_id)
    values (conv, a), (conv, b)
    on conflict do nothing;
  end if;

  return conv;
end;
$$;
grant execute on function public.get_or_create_conversation(uuid) to authenticated;

-- ---- Scalable user search (pg_trgm, keyset pagination) ----
create or replace function public.search_users(
  q text,
  cursor_id uuid default null,
  page_size int default 20
)
returns setof public.profiles
language sql stable
security definer set search_path = public as $$
  select p.*
  from public.profiles p
  where p.id <> auth.uid()
    and (
      lower(p.username)     like '%' || lower(q) || '%'
      or lower(p.display_name) like '%' || lower(q) || '%'
      or p.phone like '%' || q || '%'
    )
    and (cursor_id is null or p.id > cursor_id)
  order by p.id
  limit greatest(1, least(page_size, 50));
$$;
grant execute on function public.search_users(text, uuid, int) to authenticated;

-- ---- Auto-create a profile row on signup ----
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer
set search_path = public as $$
begin
  insert into public.profiles (id, username, display_name, phone, email, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', 'user_' || left(new.id::text, 8)),
    coalesce(new.raw_user_meta_data->>'display_name', 'New User'),
    new.phone,
    new.email,
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
