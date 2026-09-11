-- Rider App Transformation — 0044 Route Ratings
-- Allow users to rate and review discovered routes.

create table if not exists public.route_reviews (
  id              uuid primary key default gen_random_uuid(),
  route_id        uuid not null references public.discovery_routes(id) on delete cascade,
  user_id         uuid not null references public.profiles(id) on delete cascade,
  rating          int check (rating >= 1 and rating <= 5),
  comment         text,
  created_at      timestamptz not null default now(),
  unique(route_id, user_id)
);

alter table public.route_reviews enable row level security;

create policy "reviews_select" on public.route_reviews for select to authenticated using (true);
create policy "reviews_owner_all" on public.route_reviews for all to authenticated using (user_id = auth.uid());
