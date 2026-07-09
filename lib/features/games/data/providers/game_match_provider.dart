import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../game_rules.dart';
import '../models/game_match.dart';
import '../repositories/game_repository.dart';

/// Per-match live state. Subscribes to the single match row and sends moves via
/// the authoritative RPC. Grid moves are shown optimistically for snappiness and
/// reconciled the instant the realtime UPDATE (the DB's truth) arrives.
class GameMatchProvider extends ChangeNotifier {
  GameMatchProvider(GameMatch initial)
      : _match = initial,
        _repo = GameRepository(SupabaseService.client) {
    _subscribe();
  }

  final GameRepository _repo;
  GameMatch _match;
  RealtimeChannel? _channel;
  bool _sending = false;
  String? _error;

  GameMatch get match => _match;
  bool get sending => _sending;
  String? get error => _error;
  String get me => SupabaseService.currentUserId!;

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void _subscribe() {
    final old = _channel;
    if (old != null) _repo.removeChannel(old);
    _channel = _repo.subscribeMatch(_match.id, (fresh) {
      _match = fresh.withNamesFrom(_match);
      _sending = false;
      notifyListeners();
    });
  }

  Future<void> refresh() async {
    try {
      _match = await _repo.fetchMatch(_match.id);
      notifyListeners();
    } catch (_) {}
  }

  // ---- Tic-Tac-Toe / Connect Four ----
  Future<void> placeCell(int cell) => _grid({'cell': cell}, cell);

  Future<void> dropColumn(int col) {
    final row = GameRules.c4LandingRow(_match.cells, col);
    if (row < 0) return Future.value();
    return _grid({'col': col}, row * GameRules.c4Cols + col);
  }

  Future<void> _grid(Map<String, dynamic> move, int index) async {
    final me = this.me;
    if (!_match.isMyTurn(me) || _sending) return;
    final before = _match;
    final cells = List<String>.of(_match.cells);
    if (index >= 0 && index < cells.length && cells[index].isEmpty) {
      cells[index] = _match.myMark(me);
      _match = _match.copyWith(
        board: {..._match.board, 'cells': cells},
        turn: _match.opponentId(me),
      );
    }
    _sending = true;
    _error = null;
    notifyListeners();
    HapticFeedback.lightImpact();
    try {
      await _repo.move(_match.id, move);
    } catch (e) {
      _match = before; // server rejected — realtime never confirmed
      _error = _clean(e);
      _sending = false;
      notifyListeners();
    }
  }

  /// Non-optimistic move for games where local prediction is complex (reversi
  /// flips, dots & boxes). The authoritative board arrives via realtime.
  Future<void> sendMove(Map<String, dynamic> move) async {
    if (!_match.isMyTurn(me) || _sending) return;
    _sending = true;
    _error = null;
    notifyListeners();
    HapticFeedback.lightImpact();
    try {
      await _repo.move(_match.id, move);
    } catch (e) {
      _error = _clean(e);
      _sending = false;
      notifyListeners();
    }
    // On success the realtime UPDATE resets _sending and applies the new board.
  }

  // ---- Rock-Paper-Scissors ----
  Future<void> chooseRps(String choice) async {
    final me = this.me;
    if (_sending || _match.rpsChosen(_match.amPlayerA(me))) return;
    final before = _match;
    final side = _match.amPlayerA(me) ? 'a' : 'b';
    final chosen = {
      ...((_match.board['chosen'] as Map?)?.cast<String, dynamic>() ?? {}),
      side: true,
    };
    _match = _match.copyWith(board: {..._match.board, 'chosen': chosen});
    _sending = true;
    _error = null;
    notifyListeners();
    HapticFeedback.selectionClick();
    try {
      await _repo.move(_match.id, {'choice': choice});
    } catch (e) {
      _match = before;
      _error = _clean(e);
    }
    _sending = false;
    notifyListeners();
  }

  Future<void> abandon() async {
    try {
      await _repo.abandon(_match.id);
    } catch (_) {}
  }

  String _clean(Object e) {
    final s = e.toString();
    final i = s.lastIndexOf(':');
    return i >= 0 && i < s.length - 1 ? s.substring(i + 1).trim() : s;
  }

  @override
  void dispose() {
    final old = _channel;
    if (old != null) _repo.removeChannel(old);
    super.dispose();
  }
}
