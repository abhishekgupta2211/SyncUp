-- LoveChat — 0008 hard-delete a conversation
-- Frees storage: deletes the conversation + all messages/reactions/participants
-- (via cascade) AND the media objects in storage, for BOTH users.

create or replace function public.delete_conversation(p_conversation_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_conversation_participant(p_conversation_id, auth.uid()) then
    raise exception 'not a participant';
  end if;

  -- remove chat media + voice notes for this conversation (frees storage)
  delete from storage.objects
   where bucket_id in ('chat-media', 'voice-notes')
     and (storage.foldername(name))[1] = p_conversation_id::text;

  -- delete the conversation; cascades to messages, participants, reactions
  delete from public.conversations where id = p_conversation_id;
end;
$$;

grant execute on function public.delete_conversation(uuid) to authenticated;
