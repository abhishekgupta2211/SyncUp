-- LoveChat — 0014 robust hard-delete of a conversation
--
-- Why: "Delete chat" was not actually removing the conversation (the RPC was
-- failing, the client swallowed the error and re-loaded → the chat reappeared).
-- This version is bulletproof: it deletes the child rows EXPLICITLY (so it works
-- even if ON DELETE CASCADE is missing on the live DB), and the storage cleanup
-- is best-effort so it can never block the actual delete.

create or replace function public.delete_conversation(p_conversation_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_conversation_participant(p_conversation_id, auth.uid()) then
    raise exception 'not a participant';
  end if;

  -- best-effort storage cleanup (never let it block the delete)
  begin
    delete from storage.objects
     where bucket_id in ('chat-media', 'voice-notes')
       and (storage.foldername(name))[1] = p_conversation_id::text;
  exception when others then null;
  end;

  -- explicit child deletes (robust even if cascade FKs are missing), then the
  -- conversation itself — for BOTH participants.
  delete from public.message_reactions
   where message_id in (
     select id from public.messages where conversation_id = p_conversation_id
   );
  delete from public.messages
   where conversation_id = p_conversation_id;
  delete from public.conversation_participants
   where conversation_id = p_conversation_id;
  delete from public.conversations
   where id = p_conversation_id;
end;
$$;

revoke all on function public.delete_conversation(uuid) from public;
grant execute on function public.delete_conversation(uuid) to authenticated;
