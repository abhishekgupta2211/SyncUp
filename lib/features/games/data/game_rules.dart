/// Pure client-side helpers that MIRROR the server rules. They power snappy
/// optimistic placement and the winning-line highlight — the server RPC remains
/// the single source of truth for what actually counts.
class GameRules {
  GameRules._();

  // ---- Tic-Tac-Toe (9 cells, row-major) ----
  static const tttLines = <List<int>>[
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8],
    [2, 4, 6],
  ];

  /// The 3 cells of the winning line, or null if none.
  static List<int>? tttWinningLine(List<String> cells) {
    if (cells.length < 9) return null;
    for (final line in tttLines) {
      final a = cells[line[0]];
      if (a.isNotEmpty && a == cells[line[1]] && a == cells[line[2]]) {
        return line;
      }
    }
    return null;
  }

  // ---- Connect Four (6 rows x 7 cols, row-major, row 0 = top) ----
  static const c4Cols = 7;
  static const c4Rows = 6;

  /// The row a disc dropped in [col] would land in, or -1 if the column is full.
  static int c4LandingRow(List<String> cells, int col) {
    if (cells.length < c4Cols * c4Rows) return -1;
    for (var r = c4Rows - 1; r >= 0; r--) {
      if (cells[r * c4Cols + col].isEmpty) return r;
    }
    return -1;
  }

  /// The first 4-in-a-row found anywhere on the board, or null.
  static List<int>? c4WinningLine(List<String> cells) {
    if (cells.length < c4Cols * c4Rows) return null;
    const dirs = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];
    for (var r = 0; r < c4Rows; r++) {
      for (var c = 0; c < c4Cols; c++) {
        final mark = cells[r * c4Cols + c];
        if (mark.isEmpty) continue;
        for (final d in dirs) {
          final line = <int>[];
          var ok = true;
          for (var i = 0; i < 4; i++) {
            final rr = r + d[0] * i;
            final cc = c + d[1] * i;
            if (rr < 0 ||
                rr >= c4Rows ||
                cc < 0 ||
                cc >= c4Cols ||
                cells[rr * c4Cols + cc] != mark) {
              ok = false;
              break;
            }
            line.add(rr * c4Cols + cc);
          }
          if (ok) return line;
        }
      }
    }
    return null;
  }

  // ---- Gomoku (square grid, N in a row) ----
  /// The winning run of [need] cells on a [size]×[size] board, or null.
  static List<int>? nInARow(List<String> cells, int size, int need) {
    const dirs = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final mark = cells[r * size + c];
        if (mark.isEmpty) continue;
        for (final d in dirs) {
          final line = <int>[];
          var ok = true;
          for (var i = 0; i < need; i++) {
            final rr = r + d[0] * i;
            final cc = c + d[1] * i;
            if (rr < 0 ||
                rr >= size ||
                cc < 0 ||
                cc >= size ||
                cells[rr * size + cc] != mark) {
              ok = false;
              break;
            }
            line.add(rr * size + cc);
          }
          if (ok) return line;
        }
      }
    }
    return null;
  }

  // ---- Reversi / Othello ----
  static const _reversiDirs = [
    [-1, -1],
    [-1, 0],
    [-1, 1],
    [0, -1],
    [0, 1],
    [1, -1],
    [1, 0],
    [1, 1],
  ];

  /// Cells that placing [mark] ('B'/'W') at [idx] would flip (empty = illegal).
  static List<int> reversiFlips(
      List<String> cells, int size, int idx, String mark) {
    if (idx < 0 || idx >= cells.length || cells[idx].isNotEmpty) return const [];
    final opp = mark == 'B' ? 'W' : 'B';
    final r0 = idx ~/ size;
    final c0 = idx % size;
    final flips = <int>[];
    for (final d in _reversiDirs) {
      final line = <int>[];
      var r = r0 + d[0];
      var c = c0 + d[1];
      while (r >= 0 && r < size && c >= 0 && c < size) {
        final cell = cells[r * size + c];
        if (cell == opp) {
          line.add(r * size + c);
          r += d[0];
          c += d[1];
        } else {
          if (cell == mark) flips.addAll(line);
          break;
        }
      }
    }
    return flips;
  }

  /// Legal cell indices for [mark] — used to show move hints.
  static Set<int> reversiLegalMoves(List<String> cells, int size, String mark) {
    final moves = <int>{};
    for (var i = 0; i < size * size; i++) {
      if (cells[i].isEmpty && reversiFlips(cells, size, i, mark).isNotEmpty) {
        moves.add(i);
      }
    }
    return moves;
  }
}
