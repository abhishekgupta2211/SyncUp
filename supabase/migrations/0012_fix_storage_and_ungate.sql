-- LoveChat — 0012 FIX:
--   (a) (re)create the storage buckets + policies that never got created
--   (b) un-gate chat + stories (the friend-request UI isn't built yet, so 0010's
--       friends-only restriction is reverted for now)

-- =========================================================
-- (a) storage buckets
-- =========================================================
insert into storage.buckets (id, name, public) values
  ('avatars', 'avatars', true),
  ('chat-media', 'chat-media', false),
  ('voice-notes', 'voice-notes', false),
  ('stories', 'stories', true)
on conflict (id) do nothing;

-- avatars (public read, owner writes own folder)
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

-- stories (public read, owner writes own folder)
drop policy if exists stories_read on storage.objects;
create policy stories_read on storage.objects
  for select to authenticated using (bucket_id = 'stories');
drop policy if exists stories_write on storage.objects;
create policy stories_write on storage.objects
  for insert to authenticated
  with check (bucket_id = 'stories'
    and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists stories_delete on storage.objects;
create policy stories_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'stories'
    and (storage.foldername(name))[1] = auth.uid()::text);

-- chat-media (participants only)
drop policy if exists chatmedia_read on storage.objects;
create policy chatmedia_read on storage.objects
  for select to authenticated
  using (bucket_id = 'chat-media'
    and public.is_conversation_participant(((storage.foldername(name))[1])::uuid, auth.uid()));
drop policy if exists chatmedia_write on storage.objects;
create policy chatmedia_write on storage.objects
  for insert to authenticated
  with check (bucket_id = 'chat-media'
    and public.is_conversation_participant(((storage.foldername(name))[1])::uuid, auth.uid()));

-- voice-notes (participants only)
drop policy if exists voice_read on storage.objects;
create policy voice_read on storage.objects
  for select to authenticated
  using (bucket_id = 'voice-notes'
    and public.is_conversation_participant(((storage.foldername(name))[1])::uuid, auth.uid()));
drop policy if exists voice_write on storage.objects;
create policy voice_write on storage.objects
  for insert to authenticated
  with check (bucket_id = 'voice-notes'
    and public.is_conversation_participant(((storage.foldername(name))[1])::uuid, auth.uid()));

-- =========================================================
-- (b) un-gate get_or_create_conversation (no friend requirement yet)
-- =========================================================
create or replace function public.get_or_create_conversation(other_user_id uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid(); a uuid; b uuid; key text; conv uuid;
begin
  if me is null then raise exception 'not authenticated'; end if;
  if other_user_id = me then raise exception 'cannot DM yourself'; end if;
  if not exists (select 1 from public.profiles where id = other_user_id) then
    raise exception 'target user does not exist'; end if;

  a := least(me, other_user_id); b := greatest(me, other_user_id);
  key := a::text || ':' || b::text;
  insert into public.conversations (is_group, dm_key, created_by)
  values (false, key, me) on conflict (dm_key) do nothing returning id into conv;
  if conv is null then
    select id into conv from public.conversations where dm_key = key;
  else
    insert into public.conversation_participants (conversation_id, user_id)
    values (conv, a), (conv, b) on conflict do nothing;
  end if;
  return conv;
end; $$;

-- stories visible to conversation-mates again (not friends-only)
create or replace function public.can_view_story(p_story_id uuid)
returns boolean language sql security definer set search_path = public stable as $$
  select exists (
    select 1 from public.stories s
    where s.id = p_story_id
      and (s.user_id = auth.uid() or public.users_share_conversation(s.user_id))
  );
$$;

drop policy if exists stories_select on public.stories;
create policy stories_select on public.stories
  for select to authenticated
  using (user_id = auth.uid() or public.users_share_conversation(user_id));

drop policy if exists story_views_insert on public.story_views;
create policy story_views_insert on public.story_views
  for insert to authenticated
  with check (
    viewer_id = auth.uid()
    and exists (select 1 from public.stories s
                where s.id = story_id
                  and (s.user_id = auth.uid() or public.users_share_conversation(s.user_id)))
  );
