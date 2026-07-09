-- SyncUp — 0019 more games: Gomoku, Reversi (Othello), Dots & Boxes
-- All plug into the same server-authoritative game_matches framework: we extend
-- the game check, add initial boards in create_match, and add branches +
-- helper functions to game_move. Everything else (lobby, invites, notifications,
-- result, rematch, realtime) is reused unchanged.

-- =========================================================
-- allow the new game types
-- =========================================================
alter table public.game_matches drop constraint if exists game_matches_game_check;
alter table public.game_matches add constraint game_matches_game_check
  check (game in ('tictactoe','connect4','rps','gomoku','reversi','dotsboxes'));

-- =========================================================
-- helpers
-- =========================================================
-- Gomoku: is there a run of >= `need` of `mark` through (p_row,p_col)?
create or replace function public._grid_win(cells text[], size int, p_row int, p_col int, mark text, need int)
returns boolean language plpgsql immutable as $$
declare
  dr int[] := array[0, 1, 1, 1];
  dc int[] := array[1, 0, 1, -1];
  d int; cnt int; k int; r int; c int;
begin
  for d in 1..4 loop
    cnt := 1;
    k := 1;
    loop
      r := p_row + dr[d] * k; c := p_col + dc[d] * k;
      exit when r < 0 or r >= size or c < 0 or c >= size;
      exit when cells[r * size + c + 1] <> mark;
      cnt := cnt + 1; k := k + 1;
    end loop;
    k := 1;
    loop
      r := p_row - dr[d] * k; c := p_col - dc[d] * k;
      exit when r < 0 or r >= size or c < 0 or c >= size;
      exit when cells[r * size + c + 1] <> mark;
      cnt := cnt + 1; k := k + 1;
    end loop;
    if cnt >= need then return true; end if;
  end loop;
  return false;
end; $$;

-- Reversi: the 0-based cells that placing `mark` at `idx` would flip (empty = illegal).
create or replace function public._reversi_flips(cells text[], size int, idx int, mark text)
returns int[] language plpgsql immutable as $$
declare
  opp text := case when mark = 'B' then 'W' else 'B' end;
  flips int[] := array[]::int[];
  dr int[] := array[-1,-1,-1, 0, 0, 1, 1, 1];
  dc int[] := array[-1, 0, 1,-1, 1,-1, 0, 1];
  d int; r int; c int; r0 int; c0 int; line int[]; cell text;
begin
  if cells[idx + 1] <> '' then return array[]::int[]; end if;
  r0 := idx / size; c0 := idx % size;
  for d in 1..8 loop
    line := array[]::int[];
    r := r0 + dr[d]; c := c0 + dc[d];
    loop
      exit when r < 0 or r >= size or c < 0 or c >= size;
      cell := cells[r * size + c + 1];
      if cell = opp then
        line := array_append(line, r * size + c);
        r := r + dr[d]; c := c + dc[d];
      elsif cell = mark then
        if array_length(line, 1) is not null then flips := flips || line; end if;
        exit;
      else
        exit;
      end if;
    end loop;
  end loop;
  return flips;
end; $$;

-- Reversi: does `mark` have any legal move?
create or replace function public._reversi_has_move(cells text[], size int, mark text)
returns boolean language plpgsql immutable as $$
declare i int;
begin
  for i in 0..(size * size - 1) loop
    if cells[i + 1] = ''
       and array_length(public._reversi_flips(cells, size, i, mark), 1) is not null then
      return true;
    end if;
  end loop;
  return false;
end; $$;

-- Dots & Boxes (5 dots per side → 4x4 boxes): are all 4 edges of box (br,bc) drawn?
create or replace function public._db_box_complete(hh boolean[], vv boolean[], br int, bc int)
returns boolean language sql immutable as $$
  select hh[br * 4 + bc + 1] and hh[(br + 1) * 4 + bc + 1]
     and vv[br * 5 + bc + 1] and vv[br * 5 + bc + 2];
$$;

-- =========================================================
-- create_match — now knows the 3 new games' opening boards
-- =========================================================
create or replace function public.create_match(p_game text, p_opponent uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_me uuid := auth.uid(); v_id uuid; v_board jsonb; v_turn uuid; v_name text; v_rc text[];
begin
  if v_me is null then raise exception 'not authenticated'; end if;
  if p_opponent = v_me then raise exception 'cannot play yourself'; end if;
  if p_game not in ('tictactoe','connect4','rps','gomoku','reversi','dotsboxes') then
    raise exception 'unknown game'; end if;
  if public.is_blocked_between(p_opponent) then raise exception 'blocked'; end if;
  if not public.are_friends(p_opponent) then raise exception 'not friends'; end if;

  if p_game = 'tictactoe' then
    v_board := jsonb_build_object('cells', to_jsonb(array_fill(''::text, array[9])));
  elsif p_game = 'connect4' then
    v_board := jsonb_build_object('cells', to_jsonb(array_fill(''::text, array[42])), 'rows', 6, 'cols', 7);
  elsif p_game = 'gomoku' then
    v_board := jsonb_build_object('cells', to_jsonb(array_fill(''::text, array[121])), 'size', 11);
  elsif p_game = 'reversi' then
    v_rc := array_fill(''::text, array[64]);
    v_rc[28] := 'W'; v_rc[29] := 'B'; v_rc[36] := 'B'; v_rc[37] := 'W'; -- standard opening
    v_board := jsonb_build_object('cells', to_jsonb(v_rc), 'size', 8);
  elsif p_game = 'dotsboxes' then
    v_board := jsonb_build_object(
      'h', to_jsonb(array_fill(false, array[20])),
      'v', to_jsonb(array_fill(false, array[20])),
      'boxes', to_jsonb(array_fill(''::text, array[16])),
      'scoreA', 0, 'scoreB', 0, 'size', 5);
  else -- rps
    v_board := jsonb_build_object('round', 1, 'scoreA', 0, 'scoreB', 0, 'target', 3,
                                  'reveal', null, 'chosen', jsonb_build_object('a', false, 'b', false));
  end if;

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
        when 'gomoku'    then 'Gomoku'
        when 'reversi'   then 'Reversi'
        when 'dotsboxes' then 'Dots & Boxes'
        else 'Rock Paper Scissors' end,
    jsonb_build_object('match_id', v_id, 'game', p_game));
  return v_id;
end; $$;
grant execute on function public.create_match(text, uuid) to authenticated;

-- =========================================================
-- game_move — full function with the 3 new branches added
-- =========================================================
create or replace function public.game_move(p_match uuid, p_move jsonb)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_me uuid := auth.uid();
  m public.game_matches%rowtype;
  v_other uuid;
  v_cells text[];
  v_mark text;
  v_cell int; v_col int; v_landing int; v_r int; v_row int;
  v_won boolean := false; v_full boolean;
  v_choice text; v_round int; v_cnt int;
  v_ca text; v_cb text; v_rwin text;
  v_scoreA int; v_scoreB int; v_target int;
  -- reversi
  v_size int; v_flips int[]; v_fi int; v_cntA int; v_cntB int;
  -- dots & boxes
  v_edge text; v_eidx int; v_hh boolean[]; v_vv boolean[]; v_boxes text[];
  v_completed int; v_br int; v_bc int; v_all boolean;
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

  -- ---------- Gomoku (5 in a row on 11x11) ----------
  elsif m.game = 'gomoku' then
    if m.turn <> v_me then raise exception 'not your turn'; end if;
    v_size := 11;
    v_cell := (p_move->>'cell')::int;
    if v_cell < 0 or v_cell >= v_size * v_size then raise exception 'invalid cell'; end if;
    v_cells := array(select value from jsonb_array_elements_text(m.board->'cells')
                     with ordinality as t(value, ord) order by ord);
    if v_cells[v_cell + 1] <> '' then raise exception 'cell taken'; end if;
    v_mark := case when v_me = m.player_a then 'X' else 'O' end;
    v_cells[v_cell + 1] := v_mark;
    v_row := v_cell / v_size; v_col := v_cell % v_size;
    v_won := public._grid_win(v_cells, v_size, v_row, v_col, v_mark, 5);
    v_full := not exists (select 1 from unnest(v_cells) c where c = '');
    v_new_board := jsonb_build_object('cells', to_jsonb(v_cells), 'size', v_size);
    if v_won then      v_new_status := 'finished'; v_new_winner := v_me;  v_new_turn := null;
    elsif v_full then  v_new_status := 'finished'; v_new_winner := null;  v_new_turn := null;
    else               v_new_status := 'active';   v_new_winner := null;  v_new_turn := v_other;
    end if;

  -- ---------- Reversi / Othello (8x8) ----------
  elsif m.game = 'reversi' then
    if m.turn <> v_me then raise exception 'not your turn'; end if;
    v_size := 8;
    v_cell := (p_move->>'cell')::int;
    if v_cell < 0 or v_cell >= 64 then raise exception 'invalid cell'; end if;
    v_cells := array(select value from jsonb_array_elements_text(m.board->'cells')
                     with ordinality as t(value, ord) order by ord);
    v_mark := case when v_me = m.player_a then 'B' else 'W' end;
    v_flips := public._reversi_flips(v_cells, v_size, v_cell, v_mark);
    if array_length(v_flips, 1) is null then raise exception 'invalid move'; end if;
    v_cells[v_cell + 1] := v_mark;
    foreach v_fi in array v_flips loop v_cells[v_fi + 1] := v_mark; end loop;
    if public._reversi_has_move(v_cells, v_size, case when v_mark = 'B' then 'W' else 'B' end) then
      v_new_status := 'active'; v_new_winner := null; v_new_turn := v_other;
    elsif public._reversi_has_move(v_cells, v_size, v_mark) then
      v_new_status := 'active'; v_new_winner := null; v_new_turn := v_me; -- opponent passes
    else
      v_cntA := (select count(*) from unnest(v_cells) c where c = 'B');
      v_cntB := (select count(*) from unnest(v_cells) c where c = 'W');
      v_new_status := 'finished'; v_new_turn := null;
      if v_cntA > v_cntB then v_new_winner := m.player_a;
      elsif v_cntB > v_cntA then v_new_winner := m.player_b;
      else v_new_winner := null; end if;
    end if;
    v_new_board := jsonb_build_object('cells', to_jsonb(v_cells), 'size', v_size);

  -- ---------- Dots & Boxes (5 dots per side, 4x4 boxes) ----------
  elsif m.game = 'dotsboxes' then
    if m.turn <> v_me then raise exception 'not your turn'; end if;
    v_edge := p_move->>'edge';
    v_eidx := (p_move->>'index')::int;
    v_hh := array(select value::boolean from jsonb_array_elements_text(m.board->'h')
                  with ordinality as t(value, ord) order by ord);
    v_vv := array(select value::boolean from jsonb_array_elements_text(m.board->'v')
                  with ordinality as t(value, ord) order by ord);
    v_boxes := array(select value from jsonb_array_elements_text(m.board->'boxes')
                     with ordinality as t(value, ord) order by ord);
    v_mark := case when v_me = m.player_a then 'A' else 'B' end;
    v_completed := 0;

    if v_edge = 'h' then
      if v_eidx < 0 or v_eidx >= 20 then raise exception 'invalid edge'; end if;
      if v_hh[v_eidx + 1] then raise exception 'edge taken'; end if;
      v_hh[v_eidx + 1] := true;
      v_br := v_eidx / 4; v_bc := v_eidx % 4;            -- h[r][c], r 0..4, c 0..3
      if v_br <= 3 and v_boxes[v_br * 4 + v_bc + 1] = ''
         and public._db_box_complete(v_hh, v_vv, v_br, v_bc) then
        v_boxes[v_br * 4 + v_bc + 1] := v_mark; v_completed := v_completed + 1;
      end if;
      if v_br >= 1 and v_boxes[(v_br - 1) * 4 + v_bc + 1] = ''
         and public._db_box_complete(v_hh, v_vv, v_br - 1, v_bc) then
        v_boxes[(v_br - 1) * 4 + v_bc + 1] := v_mark; v_completed := v_completed + 1;
      end if;
    elsif v_edge = 'v' then
      if v_eidx < 0 or v_eidx >= 20 then raise exception 'invalid edge'; end if;
      if v_vv[v_eidx + 1] then raise exception 'edge taken'; end if;
      v_vv[v_eidx + 1] := true;
      v_br := v_eidx / 5; v_bc := v_eidx % 5;            -- v[r][c], r 0..3, c 0..4
      if v_bc <= 3 and v_boxes[v_br * 4 + v_bc + 1] = ''
         and public._db_box_complete(v_hh, v_vv, v_br, v_bc) then
        v_boxes[v_br * 4 + v_bc + 1] := v_mark; v_completed := v_completed + 1;
      end if;
      if v_bc >= 1 and v_boxes[v_br * 4 + (v_bc - 1) + 1] = ''
         and public._db_box_complete(v_hh, v_vv, v_br, v_bc - 1) then
        v_boxes[v_br * 4 + (v_bc - 1) + 1] := v_mark; v_completed := v_completed + 1;
      end if;
    else
      raise exception 'invalid edge';
    end if;

    v_scoreA := (select count(*) from unnest(v_boxes) b where b = 'A');
    v_scoreB := (select count(*) from unnest(v_boxes) b where b = 'B');
    v_all := not (exists (select 1 from unnest(v_hh) x where x = false)
               or exists (select 1 from unnest(v_vv) x where x = false));
    v_new_board := jsonb_build_object('h', to_jsonb(v_hh), 'v', to_jsonb(v_vv),
                                      'boxes', to_jsonb(v_boxes),
                                      'scoreA', v_scoreA, 'scoreB', v_scoreB, 'size', 5);
    if v_all then
      v_new_status := 'finished'; v_new_turn := null;
      if v_scoreA > v_scoreB then v_new_winner := m.player_a;
      elsif v_scoreB > v_scoreA then v_new_winner := m.player_b;
      else v_new_winner := null; end if;
    elsif v_completed > 0 then
      v_new_status := 'active'; v_new_winner := null; v_new_turn := v_me;   -- extra turn
    else
      v_new_status := 'active'; v_new_winner := null; v_new_turn := v_other;
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
