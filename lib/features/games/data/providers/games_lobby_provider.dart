import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../models/game_enums.dart';
import '../models/game_match.dart';
import '../repositories/game_repository.dart';

/// App-lifetime state for the Games hub: my matches, kept live via realtime.
/// Resets on account switch — mirrors [NotificationsProvider].
class GamesLobbyProvider extends ChangeNotifier {
  GamesLobbyProvider() {
    _authSub = SupabaseService.auth.onAuthStateChange.listen((s) {
      switch (s.event) {
        case AuthChangeEvent.signedOut:
          _clear();
        case AuthChangeEvent.signedIn:
          _start();
        case AuthChangeEvent.initialSession:
          if (s.session != null) _start();
        default:
          break;
      }
    });
    _start();
  }

  final GameRepository _repo = GameRepository(SupabaseService.client);
  late final StreamSubscription<AuthState> _authSub;
  List<RealtimeChannel> _channels = [];
  List<GameMatch> _matches = [];
  bool _loading = true;
  bool _badgeCleared = false; // NEW

  List<GameMatch> get matches => List.unmodifiable(_matches);
  List<GameMatch> get active =>
      _matches.where((m) => m.status == GameStatus.active).toList();
  List<GameMatch> get finished =>
      _matches.where((m) => m.status != GameStatus.active).toList();
  bool get loading => _loading;

  String? get _me => SupabaseService.currentUserId;

  /// Active matches waiting on MY move — drives the floating bubble badge.
  int get myTurnCount {
    if (_badgeCleared) return 0;
    final me = _me;
    if (me == null) return 0;
    return _matches.where((m) => m.isMyTurn(me)).length;
  }

  void clearBadge() {
    if (!_badgeCleared) {
      _badgeCleared = true;
      notifyListeners();
    }
  }

  Future<void> _start() async {
    _badgeCleared = false;
    await load();
    _subscribe();
  }

  Future<void> load() async {
    try {
      _matches = await _repo.fetchMyMatches();
      // If matches changed, we might want to reset badgeCleared if there's a NEW turn?
      // For now, let's just reset it when load happens if we want it to be "sticky".
      // But the user said "when I see it", so maybe only reset on new login or manually.
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  void _subscribe() {
    _unsubscribe();
    _channels = _repo.subscribeLobby(load);
  }

  /// Challenge a friend to a game; returns the new match id, or null on error.
  Future<String?> createMatch(GameType game, String opponentId) async {
    try {
      final id = await _repo.createMatch(game, opponentId);
      await load();
      return id;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteMatch(String id) async {
    _matches = _matches.where((m) => m.id != id).toList();
    notifyListeners();
    try {
      await _repo.deleteMatch(id);
    } catch (_) {}
  }

  void _unsubscribe() {
    for (final c in _channels) {
      _repo.removeChannel(c);
    }
    _channels = [];
  }

  void _clear() {
    _unsubscribe();
    _matches = [];
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub.cancel();
    _unsubscribe();
    super.dispose();
  }
}
