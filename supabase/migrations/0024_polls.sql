-- LoveChat — 0024 Polls in Feed
-- Adds poll support to posts.

create table if not exists public.polls (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid not null references public.posts(id) on delete cascade,
  question   text not null,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.poll_options (
  id      uuid primary key default gen_random_uuid(),
  poll_id uuid not null references public.polls(id) on delete cascade,
  text    text not null,
  index   int not null -- display order
);

create table if not exists public.poll_votes (
  poll_id   uuid not null references public.polls(id) on delete cascade,
  option_id uuid not null references public.poll_options(id) on delete cascade,
  user_id   uuid not null references public.profiles(id) on delete cascade,
  primary key (poll_id, user_id)
);

-- RLS
alter table public.polls enable row level security;
alter table public.poll_options enable row level security;
alter table public.poll_votes enable row level security;

create policy "polls_select" on public.polls for select to authenticated using (true);
create policy "poll_options_select" on public.poll_options for select to authenticated using (true);
create policy "poll_votes_all" on public.poll_votes for all to authenticated using (user_id = auth.uid());
