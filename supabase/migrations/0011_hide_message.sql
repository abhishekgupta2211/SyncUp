-- LoveChat — 0011 atomic "delete for me"
-- Appends the caller to deleted_for_me race-safely (server-side), instead of a
-- client-snapshot whole-array overwrite that could clobber the other user.

create or replace function public.hide_message_for_me(p_message_id uuid)
returns void
language sql security definer set search_path = public as $$
  update public.messages
     set deleted_for_me = (
       select array(select distinct unnest(deleted_for_me || auth.uid()))
     )
   where id = p_message_id
     and public.is_conversation_participant(conversation_id, auth.uid());
$$;

grant execute on function public.hide_message_for_me(uuid) to authenticated;
