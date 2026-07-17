-- SyncUp — 0036 Game notifications
create or replace function public.tg_notify_game_invite()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  inviter_name text;
begin
  select display_name into inviter_name from public.profiles where id = new.created_by;
  perform public.notify(
    (case when new.player_a_id = new.created_by then new.player_b_id else new.player_a_id end),
    new.created_by,
    'game_invite',
    coalesce(inviter_name, 'Someone'),
    'invited you to play ' || (select label from (values ('rps', 'Rock Paper Scissors'), ('ttt', 'Tic-Tac-Toe')) as t(id, label) where t.id = new.game_type::text),
    jsonb_build_object('match_id', new.id)
  );
  return new;
end; $$;

drop trigger if exists trg_notify_game_invite on public.game_matches;
create trigger trg_notify_game_invite after insert on public.game_matches
  for each row execute function public.tg_notify_game_invite();
