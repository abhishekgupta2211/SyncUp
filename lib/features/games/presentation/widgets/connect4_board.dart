import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/game_rules.dart';
import '../../data/providers/game_match_provider.dart';
import 'turn_banner.dart';

/// The Connect Four board: a 7×6 grid on a rounded, primary-tinted panel.
///
/// Tapping anywhere in a column drops a disc into it (row 0 = top). Input is
/// accepted only on my turn while no RPC is in flight and the column isn't full.
/// Newly-filled discs pop in with an elastic scale; the winning four glow white.
class ConnectFourBoard extends StatelessWidget {
  const ConnectFourBoard({super.key});

  // Fixed colours per symbol (identical for both players).
  static const _discA = AppColors.pink; // purple
  static const _discB = Color(0xFFF59E0B); // amber

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GameMatchProvider>();
    final m = p.match;
    final me = p.me;
    final theme = Theme.of(context);

    final myTurn = m.isMyTurn(me);
    final canPlay = myTurn && !p.sending && !m.status.isOver;
    final winLine = GameRules.c4WinningLine(m.cells);
    final winSet = winLine == null ? const <int>{} : winLine.toSet();

    final label =
        myTurn ? 'Your turn' : "${m.opponentName(me) ?? 'Opponent'}'s turn";

    void drop(int col) {
      if (!canPlay) return;
      if (GameRules.c4LandingRow(m.cells, col) < 0) return; // column full
      HapticFeedback.lightImpact();
      p.dropColumn(col);
    }

    return Column(
      children: [
        TurnBanner(isMyTurn: myTurn, label: label),
        SizedBox(height: 20.h),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 380.w),
              child: AspectRatio(
                aspectRatio: GameRules.c4Cols / GameRules.c4Rows, // 7 / 6
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(22.r),
                  ),
                  child: Row(
                    children: [
                      for (var col = 0; col < GameRules.c4Cols; col++)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => drop(col),
                            child: Column(
                              children: [
                                for (var row = 0;
                                    row < GameRules.c4Rows;
                                    row++)
                                  Expanded(
                                    child: _Hole(
                                      mark: _markAt(m.cells, row, col),
                                      winning: winSet.contains(
                                          row * GameRules.c4Cols + col),
                                      emptyColor: theme.scaffoldBackgroundColor,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _markAt(List<String> cells, int row, int col) {
    final i = row * GameRules.c4Cols + col;
    return i >= 0 && i < cells.length ? cells[i] : '';
  }
}

/// A single circular slot: an empty dark hole, or a filled disc that pops in
/// (elastic scale) and glows when it's part of the winning line.
class _Hole extends StatelessWidget {
  const _Hole({
    required this.mark,
    required this.winning,
    required this.emptyColor,
  });

  final String mark; // '' | 'A' | 'B'
  final bool winning;
  final Color emptyColor;

  @override
  Widget build(BuildContext context) {
    final filled = mark.isNotEmpty;

    Widget circle = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? null : emptyColor,
        gradient: filled
            ? AppColors.gradientFrom(
                mark == 'A' ? ConnectFourBoard._discA : ConnectFourBoard._discB,
              )
            : null,
        border: winning
            ? Border.all(color: Colors.white, width: 2.5.r)
            : null,
        boxShadow: winning
            ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.55),
                  blurRadius: 12.r,
                  spreadRadius: 1.r,
                ),
              ]
            : null,
      ),
    );

    if (filled) {
      // Key on the mark so a freshly-filled hole re-runs the pop animation.
      circle = TweenAnimationBuilder<double>(
        key: ValueKey(mark),
        tween: Tween(begin: 0.6, end: 1.0),
        duration: const Duration(milliseconds: 260),
        curve: Curves.elasticOut,
        builder: (_, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: circle,
      );
    }

    return Padding(
      padding: EdgeInsets.all(3.r),
      child: circle,
    );
  }
}
