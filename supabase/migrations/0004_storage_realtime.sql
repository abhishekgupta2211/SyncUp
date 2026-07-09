-- LoveChat — 0004 storage + realtime

-- ===================== Realtime publication =====================
-- Add the tables whose row changes clients must observe.
do $$ begin
  alter publication supabase_realtime add table public.messages;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.conversations;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.conversation_participants;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.message_reactions;
exception when duplicate_object then null; end $$;

-- REPLICA IDENTITY FULL so UPDATE/DELETE payloads carry old values
-- (needed to detect seen false→true and route updates correctly).
alter table public.messages                  replica identity full;
alter table public.conversations             replica identity full;
alter table public.conversation_participants replica identity full;
alter table public.message_reactions         replica identity full;

-- ===================== Storage buckets =====================
insert into storage.buckets (id, name, public) values
  ('avatars', 'avatars', true),
  ('chat-media', 'chat-media', false),
  ('voice-notes', 'voice-notes', false)
on conflict (id) do nothing;

-- ---- avatars: public read; owner writes own folder (avatars/{userId}/..) ----
drop policy if exists avatars_read on storage.objects;
create policy avatars_read on storage.objects
  for select to authenticated using (bucket_id = 'avatars');

drop policy if exists avatars_write on storage.objects;
create policy avatars_write on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists avatars_update on storage.objects;
create policy avatars_update on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text);

-- ---- chat-media: participants only (chat-media/{conversationId}/..) ----
drop policy if exists chatmedia_read on storage.objects;
create policy chatmedia_read on storage.objects
  for select to authenticated
  using (bucket_id = 'chat-media'
    and public.is_conversation_participant(
          ((storage.foldername(name))[1])::uuid, auth.uid()));

drop policy if exists chatmedia_write on storage.objects;
create policy chatmedia_write on storage.objects
  for insert to authenticated
  with check (bucket_id = 'chat-media'
    and public.is_conversation_participant(
          ((storage.foldername(name))[1])::uuid, auth.uid()));

-- ---- voice-notes: participants only (voice-notes/{conversationId}/..) ----
drop policy if exists voice_read on storage.objects;
create policy voice_read on storage.objects
  for select to authenticated
  using (bucket_id = 'voice-notes'
    and public.is_conversation_participant(
          ((storage.foldername(name))[1])::uuid, auth.uid()));

drop policy if exists voice_write on storage.objects;
create policy voice_write on storage.objects
  for insert to authenticated
  with check (bucket_id = 'voice-notes'
    and public.is_conversation_participant(
          ((storage.foldername(name))[1])::uuid, auth.uid()));

-- ===================== Realtime Authorization (optional hardening) =====================
-- Presence/typing/"recording" run on private channels named after the
-- conversation id. Enabling these makes those channels participant-only.
-- Safe to defer for the MVP (public channels work); enable before launch.
--
-- alter table realtime.messages enable row level security;  -- usually already on
-- drop policy if exists rt_conv_participants_read on realtime.messages;
-- create policy rt_conv_participants_read on realtime.messages
--   for select to authenticated
--   using (public.is_conversation_participant((realtime.topic())::uuid, auth.uid()));
-- drop policy if exists rt_conv_participants_send on realtime.messages;
-- create policy rt_conv_participants_send on realtime.messages
--   for insert to authenticated
--   with check (public.is_conversation_participant((realtime.topic())::uuid, auth.uid()));
