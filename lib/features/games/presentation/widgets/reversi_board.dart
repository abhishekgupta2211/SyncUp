import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/game_rules.dart';
import '../../data/providers/game_match_provider.dart';
import 'turn_banner.dart';

/// The Reversi / Othello board: a live score row over a turn banner and a
/// centered 8×8 grid on a rounded, primary-tinted panel.
///
/// Disc colours are fixed by symbol (identical for both players): 'B' is a dark
/// disc, 'W' a white one. On my turn the legal moves are hinted with a hollow
/// ring on each empty landing cell. Newly-flipped discs pop in with an elastic
/// scale (keyed by the cell value). Moves are non-optimistic — the authoritative
/// board arrives via realtime — so we only send after a legality check.
class ReversiBoard extends StatelessWidget {
  const ReversiBoard({super.key});

  static const _size = 8;

  // Fixed disc colours per symbol (identical for both players).
  static const _discB = Color(0xFF12141A); // dark disc
  static const _discW = Colors.white; // white disc

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GameMatchProvider>();
    final m = p.match;
    final me = p.me;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final myTurn = m.isMyTurn(me);
    final canPlay = myTurn && !p.sending && !m.status.isOver;

    final cells = m.cells;
    final myMark = m.myMark(me);
    final oppMark = myMark == 'B' ? 'W' : 'B';
    final myCount = cells.where((c) => c == myMark).length;
    final oppCount = cells.where((c) => c == oppMark).length;

    final legal = myTurn
        ? GameRules.reversiLegalMoves(cells, _size, myMark)
        : const <int>{};

    final label =
        myTurn ? 'Your turn' : "${m.opponentName(me) ?? 'Opponent'}'s turn";

    void tap(int i) {
      if (!canPlay || !legal.contains(i)) return;
      HapticFeedback.lightImpact();
      p.sendMove({'cell': i});
    }

    return Column(
      children: [
        _ScoreRow(
          myCount: myCount,
          oppCount: oppCount,
          opponentName: m.opponentName(me) ?? 'Opponent',
        ),
        SizedBox(height: 12.h),
        TurnBanner(isMyTurn: myTurn, label: label),
        SizedBox(height: 20.h),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 360.w),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: GridView.count(
                    crossAxisCount: _size,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: List.generate(_size * _size, (i) {
                      return _Cell(
                        value: i < cells.length ? cells[i] : '',
                        isHint: legal.contains(i),
                        onTap: canPlay && legal.contains(i)
                            ? () => tap(i)
                            : null,
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// "You  {my}  –  {opp}  {opponentName}" — my number is primary and bold.
class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.myCount,
    required this.oppCount,
    required this.opponentName,
  });

  final int myCount;
  final int oppCount;
  final String opponentName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    final labelStyle = theme.textTheme.labelLarge?.copyWith(color: muted);
    final numberStyle = theme.textTheme.titleMedium
        ?.copyWith(fontWeight: FontWeight.w700, color: muted);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('You', style: labelStyle),
        SizedBox(width: 8.w),
        Text(
          '$myCount',
          style: numberStyle?.copyWith(color: primary),
        ),
        SizedBox(width: 8.w),
        Text('–', style: numberStyle),
        SizedBox(width: 8.w),
        Text('$oppCount', style: numberStyle),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            opponentName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: labelStyle,
          ),
        ),
      ],
    );
  }
}

/// A single board square: thin dark separators, an optional legal-move ring on
/// an empty cell, or a disc that pops in (elastic scale, keyed by its value).
class _Cell extends StatelessWidget {
  const _Cell({
    required this.value,
    required this.isHint,
    required this.onTap,
  });

  final String value; // '' | 'B' | 'W'
  final bool isHint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final filled = value.isNotEmpty;

    Widget? content;
    if (filled) {
      content = _Disc(value: value);
    } else if (isHint) {
      content = Center(
        child: Container(
          width: 10.r,
          height: 10.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: primary.withValues(alpha: 0.5),
              width: 1.5.r,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.darkBorder.withValues(alpha: 0.6),
            width: 0.5,
          ),
        ),
        alignment: Alignment.center,
        child: content,
      ),
    );
  }
}

/// A circular disc that pops in with an elastic scale. Keying on the value makes
/// a freshly-flipped cell re-run the animation when it changes colour.
class _Disc extends StatelessWidget {
  const _Disc({required this.value});

  final String value; // 'B' | 'W'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isB = value == 'B';

    final disc = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isB ? ReversiBoard._discB : ReversiBoard._discW,
        border: isB
            ? Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                width: 1,
              )
            : null,
        boxShadow: isB
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 4.r,
                  offset: Offset(0, 1.r),
                ),
              ],
      ),
    );

    return Padding(
      padding: EdgeInsets.all(4.r),
      child: TweenAnimationBuilder<double>(
        key: ValueKey(value),
        tween: Tween(begin: 0.7, end: 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.elasticOut,
        builder: (_, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: disc,
      ),
    );
  }
}
