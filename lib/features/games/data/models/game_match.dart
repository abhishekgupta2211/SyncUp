import 'dart:convert';

import 'game_enums.dart';

/// One 1:1 game match. The DB row (this object) is the single source of truth
/// for the board; clients render from it and mutate only via the server RPCs.
class GameMatch {
  final String id;
  final GameType game;
  final String playerA; // challenger — X / A
  final String playerB; // opponent   — O / B
  final GameStatus status;
  final String? turn; // whose move (null for rps / finished)
  final Map<String, dynamic> board;
  final String? winner; // null + finished = draw
  final DateTime updatedAt;

  // Joined profile info — present from list/fetch, absent in realtime payloads.
  final String? playerAName;
  final String? playerAAvatar;
  final String? playerBName;
  final String? playerBAvatar;

  const GameMatch({
    required this.id,
    required this.game,
    required this.playerA,
    required this.playerB,
    required this.status,
    required this.turn,
    required this.board,
    required this.winner,
    required this.updatedAt,
    this.playerAName,
    this.playerAAvatar,
    this.playerBName,
    this.playerBAvatar,
  });

  factory GameMatch.fromMap(Map<String, dynamic> m) {
    final a = (m['a'] as Map?)?.cast<String, dynamic>();
    final b = (m['b'] as Map?)?.cast<String, dynamic>();
    return GameMatch(
      id: m['id'] as String,
      game: GameType.fromDb((m['game'] ?? 'tictactoe') as String),
      playerA: m['player_a'] as String,
      playerB: m['player_b'] as String,
      status: GameStatus.fromDb((m['status'] ?? 'active') as String),
      turn: m['turn'] as String?,
      board: _decodeBoard(m['board']),
      winner: m['winner'] as String?,
      updatedAt:
          DateTime.parse((m['updated_at'] ?? m['created_at']).toString())
              .toLocal(),
      playerAName: a?['display_name'] as String?,
      playerAAvatar: a?['avatar_url'] as String?,
      playerBName: b?['display_name'] as String?,
      playerBAvatar: b?['avatar_url'] as String?,
    );
  }

  static Map<String, dynamic> _decodeBoard(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.cast<String, dynamic>();
    if (raw is String && raw.isNotEmpty) {
      final d = jsonDecode(raw);
      if (d is Map) return d.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  GameMatch copyWith({
    GameStatus? status,
    String? turn,
    Map<String, dynamic>? board,
    String? winner,
    DateTime? updatedAt,
  }) {
    return GameMatch(
      id: id,
      game: game,
      playerA: playerA,
      playerB: playerB,
      status: status ?? this.status,
      turn: turn ?? this.turn,
      board: board ?? this.board,
      winner: winner ?? this.winner,
      updatedAt: updatedAt ?? this.updatedAt,
      playerAName: playerAName,
      playerAAvatar: playerAAvatar,
      playerBName: playerBName,
      playerBAvatar: playerBAvatar,
    );
  }

  /// Realtime payloads carry no joined profile names — re-attach them from the
  /// copy we already have so the header keeps its labels.
  GameMatch withNamesFrom(GameMatch other) => GameMatch(
        id: id,
        game: game,
        playerA: playerA,
        playerB: playerB,
        status: status,
        turn: turn,
        board: board,
        winner: winner,
        updatedAt: updatedAt,
        playerAName: playerAName ?? other.playerAName,
        playerAAvatar: playerAAvatar ?? other.playerAAvatar,
        playerBName: playerBName ?? other.playerBName,
        playerBAvatar: playerBAvatar ?? other.playerBAvatar,
      );

  // ---- perspective helpers ----
  bool amPlayerA(String me) => me == playerA;
  String opponentId(String me) => me == playerA ? playerB : playerA;
  String? myName(String me) => me == playerA ? playerAName : playerBName;
  String? opponentName(String me) => me == playerA ? playerBName : playerAName;
  String? opponentAvatar(String me) =>
      me == playerA ? playerBAvatar : playerAAvatar;
  bool isMyTurn(String me) => status == GameStatus.active && turn == me;
  bool iWon(String me) => winner == me;

  /// My mark: X/O (tic-tac-toe, gomoku), A/B (connect four, dots & boxes),
  /// B/W (reversi).
  String myMark(String me) {
    final a = amPlayerA(me);
    switch (game) {
      case GameType.connect4:
      case GameType.dotsboxes:
        return a ? 'A' : 'B';
      case GameType.reversi:
        return a ? 'B' : 'W';
      default:
        return a ? 'X' : 'O';
    }
  }

  // ---- grid-game board ----
  List<String> get cells =>
      (board['cells'] as List?)?.map((e) => e.toString()).toList() ??
      const <String>[];

  /// Side length for square grid games (gomoku 11, reversi 8).
  int get boardSize => (board['size'] as num?)?.toInt() ?? 3;

  // ---- dots & boxes board ----
  List<bool> get dbH =>
      ((board['h'] as List?) ?? const []).map((e) => e == true).toList();
  List<bool> get dbV =>
      ((board['v'] as List?) ?? const []).map((e) => e == true).toList();
  List<String> get dbBoxes =>
      ((board['boxes'] as List?) ?? const []).map((e) => e.toString()).toList();
  int get dbScoreA => (board['scoreA'] as num?)?.toInt() ?? 0;
  int get dbScoreB => (board['scoreB'] as num?)?.toInt() ?? 0;

  // ---- rps board ----
  int get rpsRound => (board['round'] as num?)?.toInt() ?? 1;
  int get rpsScoreA => (board['scoreA'] as num?)?.toInt() ?? 0;
  int get rpsScoreB => (board['scoreB'] as num?)?.toInt() ?? 0;
  int get rpsTarget => (board['target'] as num?)?.toInt() ?? 3;
  Map<String, dynamic>? get rpsReveal =>
      (board['reveal'] as Map?)?.cast<String, dynamic>();
  bool rpsChosen(bool playerA) {
    final chosen = (board['chosen'] as Map?)?.cast<String, dynamic>();
    return (chosen?[playerA ? 'a' : 'b'] ?? false) == true;
  }
}
