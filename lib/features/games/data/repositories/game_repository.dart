import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_refs.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../models/game_enums.dart';
import '../models/game_match.dart';

/// Reads matches + drives every mutation through the authoritative RPCs.
class GameRepository {
  GameRepository(this._client);

  final SupabaseClient _client;

  String get _me => SupabaseService.currentUserId!;

  static const _embed =
      '*, a:profiles!game_matches_player_a_fkey(display_name, avatar_url), '
      'b:profiles!game_matches_player_b_fkey(display_name, avatar_url)';

  Future<List<GameMatch>> fetchMyMatches() async {
    final rows = await _client
        .from(Tables.gameMatches)
        .select(_embed)
        .or('player_a.eq.$_me,player_b.eq.$_me')
        .order('updated_at', ascending: false)
        .limit(50);
    return (rows as List)
        .map((e) => GameMatch.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<GameMatch> fetchMatch(String id) async {
    final row = await _client
        .from(Tables.gameMatches)
        .select(_embed)
        .eq('id', id)
        .single();
    return GameMatch.fromMap(row);
  }

  Future<String> createMatch(GameType game, String opponentId) async {
    final res = await _client.rpc(
      Rpcs.createMatch,
      params: {'p_game': game.db, 'p_opponent': opponentId},
    );
    return res as String;
  }

  Future<void> move(String matchId, Map<String, dynamic> move) =>
      _client.rpc(Rpcs.gameMove, params: {'p_match': matchId, 'p_move': move});

  Future<void> abandon(String matchId) =>
      _client.rpc(Rpcs.abandonMatch, params: {'p_match': matchId});

  Future<void> deleteMatch(String matchId) =>
      _client.from(Tables.gameMatches).delete().eq('id', matchId);

  /// The lobby needs "player_a = me OR player_b = me", but a postgres_changes
  /// filter only supports a single eq — so we open one channel per side (same
  /// approach the conversation list uses).
  List<RealtimeChannel> subscribeLobby(void Function() onChange) {
    RealtimeChannel side(String column, String tag) =>
        _client.channel('games:$_me:$tag')
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: Tables.gameMatches,
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: column,
              value: _me,
            ),
            callback: (_) => onChange(),
          )
          ..subscribe();
    return [side('player_a', 'a'), side('player_b', 'b')];
  }

  RealtimeChannel subscribeMatch(
    String matchId,
    void Function(GameMatch) onUpdate,
  ) {
    final channel = _client.channel('match:$matchId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: Tables.gameMatches,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: matchId,
        ),
        callback: (payload) => onUpdate(GameMatch.fromMap(payload.newRecord)),
      )
      ..subscribe();
    return channel;
  }

  Future<void> removeChannel(RealtimeChannel channel) =>
      _client.removeChannel(channel);
}
