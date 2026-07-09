-- LoveChat — 0025 Vanish Mode & Profile Moods
-- Adds self-destructing messages and mood status.

alter table public.messages
add column if not exists is_vanish boolean default false;

alter table public.profiles
add column if not exists mood_emoji text,
add column if not exists mood_text text;
