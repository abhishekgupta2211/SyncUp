-- LoveChat — 0005 message actions
-- Keep "deleted for everyone" rows SELECTable (so the delete propagates live and
-- the client can show a "message was deleted" placeholder). Still hide rows the
-- current user deleted for themselves.

drop policy if exists msg_select on public.messages;
create policy msg_select on public.messages
  for select to authenticated
  using (
    public.is_conversation_participant(conversation_id, auth.uid())
    and not (auth.uid() = any(deleted_for_me))
  );
