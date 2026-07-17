-- SyncUp — 0037 Archive Chats
-- Adds archive support to conversation participants.

alter table public.conversation_participants
add column if not exists is_archived boolean default false;

-- Auto-unarchive on new message
create or replace function public.on_message_insert_unarchive()
returns trigger language plpgsql security definer
set search_path = public as $$
begin
  update public.conversation_participants
     set is_archived = false
   where conversation_id = new.conversation_id;
  return new;
end;
$$;

drop trigger if exists trg_on_message_insert_unarchive on public.messages;
create trigger trg_on_message_insert_unarchive
  after insert on public.messages
  for each row execute function public.on_message_insert_unarchive();

-- Policy to allow users to update their own archive status
-- existing participants_update policy might already cover this if it uses user_id = auth.uid()
