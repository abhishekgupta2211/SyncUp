-- LoveChat — 0029 Fun & Engagement Features
-- Adds streaks and profile music.

alter table public.conversation_participants
add column if not exists streak_count int default 0,
add column if not exists last_streak_at timestamptz;

alter table public.profiles
add column if not exists theme_song_name text,
add column if not exists theme_song_artist text;
