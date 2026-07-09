-- LoveChat — 0027 Public Lounges & AI Art
-- Adds global chat rooms and AI art tracking.

-- Lounges (Public Rooms)
create table if not exists public.lounges (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  description text,
  icon        text,
  created_at  timestamptz not null default now()
);

-- Lounge Messages
create table if not exists public.lounge_messages (
  id          uuid primary key default gen_random_uuid(),
  lounge_id   uuid not null references public.lounges(id) on delete cascade,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  message     text not null,
  created_at  timestamptz not null default now()
);

-- RLS
alter table public.lounges enable row level security;
alter table public.lounge_messages enable row level security;

create policy "lounges_select" on public.lounges for select to authenticated using (true);
create policy "lounge_msgs_select" on public.lounge_messages for select to authenticated using (true);
create policy "lounge_msgs_insert" on public.lounge_messages for insert to authenticated with check (user_id = auth.uid());

-- Initial Lounges
insert into public.lounges (name, description, icon) values
('General Lounge', 'The heart of SyncUp. Say hi to everyone!', '🏠'),
('Music & Vibes', 'Share your favorite tracks and vibe together.', '🎵'),
('Love Cafe', 'Talk about love, dating and relationships.', '☕'),
('Tech & Gaming', 'For the geeks and gamers in SyncUp.', '🎮');
