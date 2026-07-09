-- LoveChat — 0030 Global Leaderboard & Points
-- Tracks "Vibe Points" for popularity and hall of fame.

alter table public.profiles
add column if not exists vibe_points int default 0;

-- Trigger to give points when someone receives a gift
create or replace function public.tg_add_points_on_gift()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  gift_val int;
begin
  select price into gift_val from public.gifts where id = new.gift_id;
  update public.profiles set vibe_points = vibe_points + gift_val where id = new.receiver_id;
  return new;
end; $$;

drop trigger if exists trg_gift_points on public.sent_gifts;
create trigger trg_gift_points after insert on public.sent_gifts
  for each row execute function public.tg_add_points_on_gift();
