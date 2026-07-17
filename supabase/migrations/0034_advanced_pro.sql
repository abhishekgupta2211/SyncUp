-- SyncUp — 0034 Advanced XP & levels
alter table public.profiles add column if not exists xp_points int default 0;
alter table public.profiles add column if not exists social_level int default 1;
alter table public.conversations add column if not exists is_locked boolean default false;

create or replace function public.tg_add_xp_on_message()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update public.profiles
  set xp_points = xp_points + 5,
      social_level = floor((xp_points + 5) / 100) + 1
  where id = new.sender_id;
  return new;
end; $$;

drop trigger if exists trg_message_xp on public.messages;
create trigger trg_message_xp after insert on public.messages
  for each row execute function public.tg_add_xp_on_message();
