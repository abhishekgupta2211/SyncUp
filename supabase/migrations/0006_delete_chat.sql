-- LoveChat — 0006 delete chat
-- Let a user leave/delete a conversation for themselves (removes their own
-- participant row). The peer keeps the chat (WhatsApp-style "Delete chat").

drop policy if exists cp_delete on public.conversation_participants;
create policy cp_delete on public.conversation_participants
  for delete to authenticated
  using (user_id = auth.uid());
