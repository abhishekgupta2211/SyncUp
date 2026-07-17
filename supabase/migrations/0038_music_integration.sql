-- SyncUp — 0038 Music Integration
-- Adds support for proper music on profiles and stories.

alter table public.profiles
add column if not exists theme_song_url text,
add column if not exists theme_song_cover text;

alter table public.stories
add column if not exists music_name text,
add column if not exists music_artist text,
add column if not exists music_url text;
