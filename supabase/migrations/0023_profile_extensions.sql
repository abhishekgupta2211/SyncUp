-- LoveChat — 0023 profile extensions
-- Adds bio, interests, and verification badges to profiles.

alter table public.profiles
add column if not exists bio text,
add column if not exists interests text[],
add column if not exists is_verified boolean default false,
add column if not exists is_vip boolean default false;

-- Function to get "Suggested Users" for discovery
create or replace function public.get_suggested_users(limit_count int default 10)
returns setof public.profiles
language sql stable
security definer set search_path = public as $$
  select *
  from public.profiles
  where id <> auth.uid()
  order by last_seen desc nulls last, created_at desc
  limit limit_count;
$$;
grant execute on function public.get_suggested_users(int) to authenticated;
