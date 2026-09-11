-- Rider App Transformation — 0041 Rides and Routes
-- Adds support for planned rides and route discovery.

-- 1. Routes Table (Pre-defined or user-suggested routes)
create table if not exists public.discovery_routes (
  id              uuid primary key default gen_random_uuid(),
  title           text not null,
  description     text,
  start_point     jsonb not null, -- {lat, lng, name}
  end_point       jsonb not null,   -- {lat, lng, name}
  waypoints       jsonb default '[]', -- list of {lat, lng}
  distance_km     float,
  duration_mins   int,
  difficulty      text check (difficulty in ('easy','moderate','hard')),
  category        text, -- scenic, adventure, off-road
  created_by      uuid references public.profiles(id),
  created_at      timestamptz not null default now()
);

-- 2. Rides Table (Actual events)
create table if not exists public.rides (
  id              uuid primary key default gen_random_uuid(),
  organizer_id    uuid not null references public.profiles(id) on delete cascade,
  title           text not null,
  description     text,
  start_at        timestamptz not null,
  meeting_point   jsonb not null,
  destination     jsonb not null,
  ride_type       text default 'public' check (ride_type in ('public','private','solo')),
  status          text default 'upcoming' check (status in ('upcoming', 'live', 'completed', 'cancelled')),
  max_riders      int,
  required_gear   text[],
  route_id        uuid references public.discovery_routes(id),
  created_at      timestamptz not null default now()
);

-- 3. Ride Participants
create table if not exists public.ride_participants (
  ride_id         uuid not null references public.rides(id) on delete cascade,
  user_id         uuid not null references public.profiles(id) on delete cascade,
  status          text default 'joined' check (status in ('requested', 'joined', 'declined')),
  joined_at       timestamptz not null default now(),
  primary key (ride_id, user_id)
);

-- 4. RLS
alter table public.discovery_routes enable row level security;
alter table public.rides enable row level security;
alter table public.ride_participants enable row level security;

create policy "routes_select" on public.discovery_routes for select to authenticated using (true);
create policy "rides_select" on public.rides for select to authenticated using (true);
create policy "rides_organizer_all" on public.rides for all to authenticated using (organizer_id = auth.uid());
create policy "participants_select" on public.ride_participants for select to authenticated using (true);
create policy "participants_self_all" on public.ride_participants for all to authenticated using (user_id = auth.uid());

-- Initial Mock Routes
insert into public.discovery_routes (title, description, start_point, end_point, distance_km, duration_mins, difficulty, category)
values
('Coastal Sprint', 'A beautiful ride along the shoreline.', '{"lat": 19.076, "lng": 72.877, "name": "Mumbai"}', '{"lat": 18.520, "lng": 73.856, "name": "Pune"}', 150, 180, 'easy', 'scenic'),
('Mountain Twisties', 'Sharp turns and high altitude.', '{"lat": 32.243, "lng": 77.189, "name": "Manali"}', '{"lat": 32.732, "lng": 77.161, "name": "Rohtang"}', 50, 120, 'hard', 'adventure');
