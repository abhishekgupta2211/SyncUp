import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/game_rules.dart';
import '../../data/providers/game_match_provider.dart';
import 'turn_banner.dart';

/// The Gomoku board: a turn banner over a centered dense grid (11×11), where
/// five-in-a-row wins.
///
/// Stone colours are fixed by symbol (not by viewer) so both players always see
/// 'X' as a purple gradient stone and 'O' as an amber stone. A freshly-placed
/// stone pops in with an elastic scale; the winning run glows white. Input is
/// accepted only on my turn while no RPC is in flight and the tapped cell is
/// empty. Placement is optimistic via [GameMatchProvider.placeCell].
class GomokuBoard extends StatelessWidget {
  const GomokuBoard({super.key});

  // Fixed colours per symbol (identical for both players).
  static const _stoneX = AppColors.pink; // purple gradient stone
  static const _stoneO = Color(0xFFF59E0B); // amber stone

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GameMatchProvider>();
    final m = p.match;
    final me = p.me;

    final size = m.boardSize; // 11
    final myTurn = m.isMyTurn(me);
    final canPlay = myTurn && !p.sending && !m.status.isOver;

    final win = GameRules.nInARow(m.cells, size, 5);
    final winSet = win == null ? const <int>{} : win.toSet();

    final label =
        myTurn ? 'Your turn' : "${m.opponentName(me) ?? 'Opponent'}'s turn";

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TurnBanner(isMyTurn: myTurn, label: label),
        SizedBox(height: 24.h),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 360.w),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceAlt,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: size * size,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: size,
                  ),
                  itemBuilder: (context, i) {
                    final value = m.cells[i];
                    final canTap = canPlay && value.isEmpty;
                    return _Cell(
                      value: value,
                      isWinning: winSet.contains(i),
                      onTap: canTap
                          ? () {
                              HapticFeedback.lightImpact();
                              p.placeCell(i);
                            }
                          : null,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A single grid intersection: a thin-bordered square (Go-grid look) holding an
/// optional stone. The stone pops in (elastic scale) and glows white when it is
/// part of the winning run.
class _Cell extends StatelessWidget {
  const _Cell({
    required this.value,
    required this.isWinning,
    required this.onTap,
  });

  final String value; // '' | 'X' | 'O'
  final bool isWinning;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filled = value.isNotEmpty;

    Widget? stone;
    if (filled) {
      stone = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.gradientFrom(
            value == 'X' ? GomokuBoard._stoneX : GomokuBoard._stoneO,
          ),
          border:
              isWinning ? Border.all(color: Colors.white, width: 2.r) : null,
          boxShadow: isWinning
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.5),
                    blurRadius: 10.r,
                    spreadRadius: 1.r,
                  ),
                ]
              : null,
        ),
      );

      // Key on the value so a freshly-placed stone re-runs the pop animation.
      stone = TweenAnimationBuilder<double>(
        key: ValueKey(value),
        tween: Tween(begin: 0.7, end: 1.0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.elasticOut,
        builder: (_, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: stone,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
          ),
        ),
        padding: EdgeInsets.all(3.r),
        child: stone,
      ),
    );
  }
}
