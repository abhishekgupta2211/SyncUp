import 'package:flutter/material.dart';

/// The games available in SyncUp Games.
enum GameType {
  tictactoe,
  connect4,
  gomoku,
  reversi,
  dotsboxes,
  rps;

  static GameType fromDb(String v) => switch (v) {
        'connect4' => GameType.connect4,
        'gomoku' => GameType.gomoku,
        'reversi' => GameType.reversi,
        'dotsboxes' => GameType.dotsboxes,
        'rps' => GameType.rps,
        _ => GameType.tictactoe,
      };

  String get db => switch (this) {
        GameType.tictactoe => 'tictactoe',
        GameType.connect4 => 'connect4',
        GameType.gomoku => 'gomoku',
        GameType.reversi => 'reversi',
        GameType.dotsboxes => 'dotsboxes',
        GameType.rps => 'rps',
      };

  String get label => switch (this) {
        GameType.tictactoe => 'Tic-Tac-Toe',
        GameType.connect4 => 'Connect Four',
        GameType.gomoku => 'Gomoku',
        GameType.reversi => 'Reversi',
        GameType.dotsboxes => 'Dots & Boxes',
        GameType.rps => 'Rock Paper Scissors',
      };

  String get tagline => switch (this) {
        GameType.tictactoe => 'Three in a row',
        GameType.connect4 => 'Drop four to win',
        GameType.gomoku => 'Five in a row',
        GameType.reversi => 'Flip to conquer',
        GameType.dotsboxes => 'Close the box',
        GameType.rps => 'Best of 5 · quick duel',
      };

  IconData get icon => switch (this) {
        GameType.tictactoe => Icons.close_rounded,
        GameType.connect4 => Icons.grid_view_rounded,
        GameType.gomoku => Icons.blur_on_rounded,
        GameType.reversi => Icons.contrast_rounded,
        GameType.dotsboxes => Icons.border_all_rounded,
        GameType.rps => Icons.back_hand_rounded,
      };
}

/// Match lifecycle. `finished` with a null winner means a draw.
enum GameStatus {
  active,
  finished,
  abandoned;

  static GameStatus fromDb(String v) => switch (v) {
        'finished' => GameStatus.finished,
        'abandoned' => GameStatus.abandoned,
        _ => GameStatus.active,
      };

  bool get isOver => this != GameStatus.active;
}
