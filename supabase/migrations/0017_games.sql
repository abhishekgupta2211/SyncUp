-- SyncUp — 0017 realtime multiplayer games (G1)
-- A single `game_matches` row holds the FULL authoritative board for a 1:1 match.
-- Every move goes through the SECURITY DEFINER `game_move` RPC, which validates
-- (it's your turn + the move is legal), applies it, detects win/draw and updates
-- the row atomically. Both clients subscribe to a realtime UPDATE on that row and
-- re-render from the DB's truth — no move races, no split-brain win detection,
-- no cheating. Supports Tic-Tac-Toe, Connect Four and Rock-Paper-Scissors.

-- =========================================================
-- tables
-- =========================================================
create table if not exists public.game_matches (
  id         uuid primary key default gen_random_uuid(),
  game       text not null check (game in ('tictactoe','connect4','rps')),
  player_a   uuid not null references public.profiles(id) on delete cascade, -- challenger (X / A)
  player_b   uuid not null references public.profiles(id) on delete cascade, -- opponent  (O / B)
  status     text not null default 'active' check (status in ('active','finished','abandoned')),
  turn       uuid references public.profiles(id) on delete set null,          -- whose move (null for rps)
  board      jsonb not null default '{}'::jsonb,                              -- game-specific state
  winner     uuid references public.profiles(id) on delete set null,          -- null + finished = draw
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (player_a <> player_b)
);
create index if not exists idx_game_matches_a on public.game_matches (player_a, updated_at desc);
create index if not exists idx_game_matches_b on public.game_matches (player_b, updated_at desc);

-- Rock-Paper-Scissors is simultaneous: choices are kept here, readable ONLY by
-- their owner, so a peer can't peek before revealing. The SECURITY DEFINER RPC
-- reveals both into game_matches.board only once both have chosen.
create table if not exists public.game_rps_choices (
  match_id   uuid not null references public.game_matches(id) on delete cascade,
  round      int  not null,
  player_id  uuid not null references public.profiles(id) on delete cascade,
  choice     text not null check (choice in ('rock','paper','scissors')),
  created_at timestamptz not null default now(),
  primary key (match_id, round, player_id)
);

-- =========================================================
-- RLS
-- =========================================================
alter table public.game_matches enable row level security;
alter table public.game_rps_choices enable row level security;

-- only the two players can see / remove a match; all writes go through the RPCs
-- (SECURITY DEFINER bypasses RLS), so there is no insert/update policy.
drop policy if exists game_matches_select on public.game_matches;
create policy game_matches_select on public.game_matches
  for select to authenticated
  using (player_a = auth.uid() or player_b = auth.uid());

drop policy if exists game_matches_delete on public.game_matches;
create policy game_matches_delete on public.game_matches
  for delete to authenticated
  using (player_a = auth.uid() or player_b = auth.uid());

-- you can only ever read YOUR OWN pending choice (never the opponent's)
drop policy if exists rps_choices_select_own on public.game_rps_choices;
create policy rps_choices_select_own on public.game_rps_choices
  for select to authenticated
  using (player_id = auth.uid());
-- no insert/update/delete policy: only the game_move RPC writes here.

-- realtime for live play (the match row drives both boards). rps_choices is NOT
-- published — a peer must not receive realtime of your hidden choice.
do $$ begin alter publication supabase_realtime add table public.game_matches;
exception when duplicate_object then null; end $$;
alter table public.game_matches replica identity full;

-- =========================================================
-- helper: Connect-Four win check from the just-placed disc
-- =========================================================
-- cells is a 42-length row-major text[] (row 0 = top). Scans the 4 line
-- directions through (p_row,p_col) and returns true on 4+ in a row of `mark`.
create or replace function public._c4_win(cells text[], p_row int, p_col int, mark text)
returns boolean language plpgsql immutable as $$
declare
  dr int[] := array[0, 1, 1, 1];
  dc int[] := array[1, 0, 1, -1];
  d int; cnt int; k int; r int; c int;
begin
  for d in 1..4 loop
    cnt := 1;
    k := 1;                                   -- forward
    loop
      r := p_row + dr[d] * k; c := p_col + dc[d] * k;
      exit when r < 0 or r > 5 or c < 0 or c > 6;
      exit when cells[r * 7 + c + 1] <> mark;
      cnt := cnt + 1; k := k + 1;
    end loop;
    k := 1;                                   -- backward
    loop
      r := p_row - dr[d] * k; c := p_col - dc[d] * k;
      exit when r < 0 or r > 5 or c < 0 or c > 6;
      exit when cells[r * 7 + c + 1] <> mark;
      cnt := cnt + 1; k := k + 1;
    end loop;
    if cnt >= 4 then return true; end if;
  end loop;
  return false;
end; $$;

-- =========================================================
-- RPC: create_match — challenge a friend
-- =========================================================
create or replace function public.create_match(p_game text, p_opponent uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_me uuid := auth.uid(); v_id uuid; v_board jsonb; v_turn uuid; v_name text;
begin
  if v_me is null then raise exception 'not authenticated'; end if;
  if p_opponent = v_me then raise exception 'cannot play yourself'; end if;
  if p_game not in ('tictactoe','connect4','rps') then raise exception 'unknown game'; end if;
  if public.is_blocked_between(p_opponent) then raise exception 'blocked'; end if;
  if not public.are_friends(p_opponent) then raise exception 'not friends'; end if;

  v_board := case p_game
    when 'tictactoe' then jsonb_build_object('cells', to_jsonb(array_fill(''::text, array[9])))
    when 'connect4'  then jsonb_build_object('cells', to_jsonb(array_fill(''::text, array[42])), 'rows', 6, 'cols', 7)
    when 'rps'       then jsonb_build_object('round', 1, 'scoreA', 0, 'scoreB', 0, 'target', 3,
                                             'reveal', null, 'chosen', jsonb_build_object('a', false, 'b', false))
  end;
  v_turn := case when p_game = 'rps' then null else v_me end;

  insert into public.game_matches (game, player_a, player_b, status, turn, board)
    values (p_game, v_me, p_opponent, 'active', v_turn, v_board)
    returning id into v_id;

  select display_name into v_name from public.profiles where id = v_me;
  perform public.notify(p_opponent, v_me, 'game_invite',
    coalesce(v_name, 'Someone'),
    'invited you to play ' || case p_game
        when 'tictactoe' then 'Tic-Tac-Toe'
        when 'connect4'  then 'Connect Four'
        else 'Rock Paper Scissors' end,
    jsonb_build_object('match_id', v_id, 'game', p_game));
  return v_id;
end; $$;
grant execute on function public.create_match(text, uuid) to authenticated;

-- =========================================================
-- RPC: game_move — the one authoritative mutation
-- =========================================================
-- p_move is game-specific: tictactoe {"cell":0..8}, connect4 {"col":0..6},
-- rps {"choice":"rock"|"paper"|"scissors"}.
create or replace function public.game_move(p_match uuid, p_move jsonb)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_me uuid := auth.uid();
  m public.game_matches%rowtype;
  v_other uuid;
  v_cells text[];
  v_mark text;
  v_cell int; v_col int; v_landing int; v_r int;
  v_won boolean := false; v_full boolean;
  v_choice text; v_round int; v_cnt int;
  v_ca text; v_cb text; v_rwin text;
  v_scoreA int; v_scoreB int; v_target int;
  v_new_board jsonb; v_new_status text; v_new_turn uuid; v_new_winner uuid;
begin
  if v_me is null then raise exception 'not authenticated'; end if;

  select * into m from public.game_matches where id = p_match for update;
  if not found then raise exception 'match not found'; end if;
  if m.player_a <> v_me and m.player_b <> v_me then raise exception 'not a player'; end if;
  if m.status <> 'active' then raise exception 'game is not active'; end if;

  v_other := case when v_me = m.player_a then m.player_b else m.player_a end;

  -- ---------- Tic-Tac-Toe ----------
  if m.game = 'tictactoe' then
    if m.turn <> v_me then raise exception 'not your turn'; end if;
    v_cell := (p_move->>'cell')::int;
    if v_cell < 0 or v_cell > 8 then raise exception 'invalid cell'; end if;
    v_cells := array(select value from jsonb_array_elements_text(m.board->'cells')
                     with ordinality as t(value, ord) order by ord);
    if v_cells[v_cell + 1] <> '' then raise exception 'cell taken'; end if;
    v_mark := case when v_me = m.player_a then 'X' else 'O' end;
    v_cells[v_cell + 1] := v_mark;
    v_won := (v_cells[1]=v_mark and v_cells[2]=v_mark and v_cells[3]=v_mark)
          or (v_cells[4]=v_mark and v_cells[5]=v_mark and v_cells[6]=v_mark)
          or (v_cells[7]=v_mark and v_cells[8]=v_mark and v_cells[9]=v_mark)
          or (v_cells[1]=v_mark and v_cells[4]=v_mark and v_cells[7]=v_mark)
          or (v_cells[2]=v_mark and v_cells[5]=v_mark and v_cells[8]=v_mark)
          or (v_cells[3]=v_mark and v_cells[6]=v_mark and v_cells[9]=v_mark)
          or (v_cells[1]=v_mark and v_cells[5]=v_mark and v_cells[9]=v_mark)
          or (v_cells[3]=v_mark and v_cells[5]=v_mark and v_cells[7]=v_mark);
    v_full := not exists (select 1 from unnest(v_cells) c where c = '');
    v_new_board := jsonb_build_object('cells', to_jsonb(v_cells));
    if v_won then      v_new_status := 'finished'; v_new_winner := v_me;  v_new_turn := null;
    elsif v_full then  v_new_status := 'finished'; v_new_winner := null;  v_new_turn := null;
    else               v_new_status := 'active';   v_new_winner := null;  v_new_turn := v_other;
    end if;

  -- ---------- Connect Four ----------
  elsif m.game = 'connect4' then
    if m.turn <> v_me then raise exception 'not your turn'; end if;
    v_col := (p_move->>'col')::int;
    if v_col < 0 or v_col > 6 then raise exception 'invalid column'; end if;
    v_cells := array(select value from jsonb_array_elements_text(m.board->'cells')
                     with ordinality as t(value, ord) order by ord);
    v_landing := -1;
    for v_r in reverse 5..0 loop
      if v_cells[v_r * 7 + v_col + 1] = '' then v_landing := v_r; exit; end if;
    end loop;
    if v_landing < 0 then raise exception 'column full'; end if;
    v_mark := case when v_me = m.player_a then 'A' else 'B' end;
    v_cells[v_landing * 7 + v_col + 1] := v_mark;
    v_won := public._c4_win(v_cells, v_landing, v_col, v_mark);
    v_full := not exists (select 1 from unnest(v_cells) c where c = '');
    v_new_board := jsonb_build_object('cells', to_jsonb(v_cells), 'rows', 6, 'cols', 7);
    if v_won then      v_new_status := 'finished'; v_new_winner := v_me;  v_new_turn := null;
    elsif v_full then  v_new_status := 'finished'; v_new_winner := null;  v_new_turn := null;
    else               v_new_status := 'active';   v_new_winner := null;  v_new_turn := v_other;
    end if;

  -- ---------- Rock-Paper-Scissors ----------
  elsif m.game = 'rps' then
    v_choice := p_move->>'choice';
    if v_choice not in ('rock','paper','scissors') then raise exception 'invalid choice'; end if;
    v_round := (m.board->>'round')::int;
    if exists (select 1 from public.game_rps_choices
               where match_id = p_match and round = v_round and player_id = v_me) then
      raise exception 'already chose this round';
    end if;
    insert into public.game_rps_choices (match_id, round, player_id, choice)
      values (p_match, v_round, v_me, v_choice);

    select count(*) into v_cnt from public.game_rps_choices
      where match_id = p_match and round = v_round;

    if v_cnt < 2 then
      -- only flag that I've chosen; my actual choice stays hidden
      v_new_board := jsonb_set(m.board,
        array['chosen', case when v_me = m.player_a then 'a' else 'b' end], 'true'::jsonb);
      v_new_status := 'active'; v_new_winner := null; v_new_turn := null;
    else
      select choice into v_ca from public.game_rps_choices
        where match_id = p_match and round = v_round and player_id = m.player_a;
      select choice into v_cb from public.game_rps_choices
        where match_id = p_match and round = v_round and player_id = m.player_b;
      if v_ca = v_cb then v_rwin := 'draw';
      elsif (v_ca='rock'     and v_cb='scissors')
         or (v_ca='scissors' and v_cb='paper')
         or (v_ca='paper'    and v_cb='rock') then v_rwin := 'a';
      else v_rwin := 'b';
      end if;
      v_scoreA := (m.board->>'scoreA')::int + case when v_rwin = 'a' then 1 else 0 end;
      v_scoreB := (m.board->>'scoreB')::int + case when v_rwin = 'b' then 1 else 0 end;
      v_target := (m.board->>'target')::int;
      v_new_board := jsonb_build_object(
        'round', v_round + 1,
        'scoreA', v_scoreA, 'scoreB', v_scoreB, 'target', v_target,
        'reveal', jsonb_build_object('round', v_round, 'a', v_ca, 'b', v_cb, 'winner', v_rwin),
        'chosen', jsonb_build_object('a', false, 'b', false));
      if v_scoreA >= v_target then    v_new_status := 'finished'; v_new_winner := m.player_a; v_new_turn := null;
      elsif v_scoreB >= v_target then v_new_status := 'finished'; v_new_winner := m.player_b; v_new_turn := null;
      else                            v_new_status := 'active';   v_new_winner := null;       v_new_turn := null;
      end if;
    end if;

  else
    raise exception 'unknown game';
  end if;

  update public.game_matches
    set board = v_new_board, status = v_new_status,
        winner = v_new_winner, turn = v_new_turn, updated_at = now()
    where id = p_match;
end; $$;
grant execute on function public.game_move(uuid, jsonb) to authenticated;

-- =========================================================
-- RPC: abandon_match — forfeit (the other player wins)
-- =========================================================
create or replace function public.abandon_match(p_match uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_me uuid := auth.uid(); m public.game_matches%rowtype; v_other uuid;
begin
  if v_me is null then raise exception 'not authenticated'; end if;
  select * into m from public.game_matches where id = p_match for update;
  if not found then return; end if;
  if m.player_a <> v_me and m.player_b <> v_me then raise exception 'not a player'; end if;
  if m.status <> 'active' then return; end if;
  v_other := case when v_me = m.player_a then m.player_b else m.player_a end;
  update public.game_matches
    set status = 'abandoned', winner = v_other, turn = null, updated_at = now()
    where id = p_match;
end; $$;
grant execute on function public.abandon_match(uuid) to authenticated;
