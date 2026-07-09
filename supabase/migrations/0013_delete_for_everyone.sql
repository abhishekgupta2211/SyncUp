-- LoveChat — 0013 delete-for-everyone (reliable persist + WhatsApp tombstone)
--
-- Why: the old client did a direct UPDATE on messages to flip
-- deleted_for_everyone. That write was not persisting (it got silently rejected
-- on the RLS UPDATE path), and the controller swallowed the error, so the
-- message reappeared on reopen. We move the delete into a SECURITY DEFINER RPC
-- that reliably applies the flag (self-checking sender ownership), and we stop
-- hiding deleted rows in msg_select so the "message was deleted" tombstone
-- persists (the chat bubble renders it).

-- (a) Reliable delete-for-everyone: runs as the function owner (bypasses the
--     per-row UPDATE policy quirks) but only deletes the caller's OWN message.
create or replace function public.delete_message_for_everyone(p_message_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update public.messages
     set deleted_for_everyone = true,
         message              = '',
         media_url            = null
   where id = p_message_id
     and sender_id = auth.uid();
$$;

revoke all on function public.delete_message_for_everyone(uuid) from public;
grant execute on function public.delete_message_for_everyone(uuid) to authenticated;

-- (b) Keep deleted rows visible (as a tombstone) on reopen — remove the
--     `not deleted_for_everyone` hide. Per-user "delete for me" and participant
--     scoping stay intact.
drop policy if exists msg_select on public.messages;
create policy msg_select on public.messages
  for select to authenticated
  using (
    public.is_conversation_participant(conversation_id, auth.uid())
    and not (auth.uid() = any(deleted_for_me))
  );
