import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/game_rules.dart';
import '../../data/providers/game_match_provider.dart';
import 'turn_banner.dart';

/// The Tic-Tac-Toe board: a turn banner over a centered 3x3 grid.
///
/// Symbol colours are fixed by symbol (not by viewer) so both players always
/// see 'X' in the primary gradient and 'O' in indigo. Placement elastically
/// scales in; the winning line is glow-highlighted.
class TicTacToeBoard extends StatelessWidget {
  const TicTacToeBoard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GameMatchProvider>();
    final m = p.match;
    final me = p.me;

    final myTurn = m.isMyTurn(me);
    final win = GameRules.tttWinningLine(m.cells);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TurnBanner(
          isMyTurn: myTurn,
          label: myTurn
              ? 'Your turn'
              : "${m.opponentName(me) ?? 'Opponent'}'s turn",
        ),
        SizedBox(height: 28.h),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 360.w),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.count(
                  crossAxisCount: 3,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  mainAxisSpacing: 10.r,
                  crossAxisSpacing: 10.r,
                  children: List.generate(9, (i) {
                    final canTap = myTurn && !p.sending && m.cells[i].isEmpty;
                    return _Cell(
                      value: m.cells[i],
                      isWinning: win?.contains(i) ?? false,
                      onTap: canTap
                          ? () {
                              HapticFeedback.lightImpact();
                              p.placeCell(i);
                            }
                          : null,
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.value,
    required this.isWinning,
    required this.onTap,
  });

  final String value;
  final bool isWinning;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final baseFill =
        isDark ? AppColors.darkSurfaceAlt : theme.colorScheme.surfaceContainerHighest;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isWinning ? primary.withValues(alpha: 0.16) : baseFill,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isWinning
                ? primary.withValues(alpha: 0.6)
                : theme.colorScheme.onSurface.withValues(alpha: 0.08),
            width: isWinning ? 1.6 : 1,
          ),
          boxShadow: isWinning
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: value.isEmpty ? null : _Mark(value: value),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    Widget symbol;
    if (value == 'X') {
      symbol = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) =>
            AppColors.gradientFrom(primary).createShader(bounds),
        child: Icon(Icons.close_rounded, size: 48.r, color: Colors.white),
      );
    } else {
      symbol = Icon(
        Icons.radio_button_unchecked,
        size: 44.r,
        color: AppColors.magenta,
      );
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey(value),
      tween: Tween(begin: 0.7, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: symbol,
    );
  }
}
