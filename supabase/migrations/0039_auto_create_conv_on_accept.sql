-- SyncUp — 0039 Auto-create conversation on friend accept
-- When a friendship status becomes 'accepted', automatically create a 1:1 conversation record.

create or replace function public.tg_auto_create_conversation()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  a uuid; b uuid; key text; conv uuid;
begin
  if new.status = 'accepted' and (old.status is null or old.status <> 'accepted') then
    a := least(new.requester_id, new.addressee_id);
    b := greatest(new.requester_id, new.addressee_id);
    key := a::text || ':' || b::text;

    -- Create conversation if it doesn't exist
    insert into public.conversations (is_group, dm_key, created_by)
    values (false, key, new.addressee_id) -- addressee is usually the one accepting
    on conflict (dm_key) do nothing
    returning id into conv;

    if conv is null then
      select id into conv from public.conversations where dm_key = key;
    end if;

    -- Ensure both are participants
    insert into public.conversation_participants (conversation_id, user_id)
    values (conv, a), (conv, b)
    on conflict do nothing;
  end if;
  return new;
end; $$;

drop trigger if exists trg_auto_create_conversation on public.friendships;
create trigger trg_auto_create_conversation
  after update on public.friendships
  for each row execute function public.tg_auto_create_conversation();

-- Also handle cases where friendship might be inserted as 'accepted' directly (if any)
create trigger trg_auto_create_conversation_insert
  after insert on public.friendships
  for each row execute function public.tg_auto_create_conversation();
