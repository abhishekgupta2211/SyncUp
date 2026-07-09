-- LoveChat — 0026 Social Pro Features
-- Adds profile views and global feed helper.

-- Table for tracking profile visits
create table if not exists public.profile_views (
  id           uuid primary key default gen_random_uuid(),
  viewer_id    uuid not null references public.profiles(id) on delete cascade,
  profile_id   uuid not null references public.profiles(id) on delete cascade,
  viewed_at    timestamptz not null default now()
);

-- Index for fast lookup
create index if not exists idx_profile_views_target on public.profile_views (profile_id, viewed_at desc);

-- RLS
alter table public.profile_views enable row level security;
create policy "profile_views_select" on public.profile_views for select to authenticated using (profile_id = auth.uid());
create policy "profile_views_insert" on public.profile_views for insert to authenticated with check (viewer_id = auth.uid());

-- Function to record a view (never record yourself)
create or replace function public.record_profile_view(p_target_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() <> p_target_id then
    insert into public.profile_views (viewer_id, profile_id)
    values (auth.uid(), p_target_id);
  end if;
end; $$;

-- Update profiles table to track total views
alter table public.profiles add column if not exists total_views int default 0;
