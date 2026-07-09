import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/providers/game_match_provider.dart';

/// Rock-Paper-Scissors board: a simultaneous best-of-N duel.
///
/// Both players lock a choice each round; the DB reveals the result the moment
/// both have chosen. Local state remembers the choice I tapped this round so the
/// picked card stays highlighted while I wait for my opponent.
class RpsBoard extends StatefulWidget {
  const RpsBoard({super.key});

  @override
  State<RpsBoard> createState() => _RpsBoardState();
}

class _RpsBoardState extends State<RpsBoard> {
  String? _myChoice;
  int _choiceRound = -1;

  static const List<_RpsOption> _options = [
    _RpsOption('rock', '✊', 'Rock'),
    _RpsOption('paper', '✋', 'Paper'),
    _RpsOption('scissors', '✌️', 'Scissors'),
  ];

  String _emoji(String choice) =>
      _options.firstWhere((o) => o.value == choice).emoji;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.watch<GameMatchProvider>();
    final m = p.match;
    final me = p.me;

    // Reset the remembered choice when a new round begins.
    if (_choiceRound != m.rpsRound) {
      _choiceRound = m.rpsRound;
      _myChoice = null;
    }

    final amPlayerA = m.amPlayerA(me);
    final myScore = amPlayerA ? m.rpsScoreA : m.rpsScoreB;
    final oppScore = amPlayerA ? m.rpsScoreB : m.rpsScoreA;
    final target = m.rpsTarget;
    final round = m.rpsRound;
    final oppName = m.opponentName(me) ?? 'Opponent';

    // Gate on the server truth (the provider sets this optimistically and
    // reverts on failure) so a failed choice never soft-locks the round.
    final iChose = m.rpsChosen(amPlayerA);
    final oppChose = m.rpsChosen(!amPlayerA);
    final isOver = m.status.isOver;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _scoreHeader(theme, myScore, oppScore, oppName),
            SizedBox(height: 6.h),
            Text(
              'Best of ${(target * 2) - 1} · Round $round',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 24.h),
            _revealArea(theme, m.rpsReveal, amPlayerA),
            SizedBox(height: 24.h),
            _choiceRow(
              theme: theme,
              p: p,
              iChose: iChose,
              oppChose: oppChose,
              isOver: isOver,
            ),
            SizedBox(height: 18.h),
            _waitingLine(theme, iChose, oppChose, isOver, oppName),
          ],
        ),
      ),
    );
  }

  Widget _scoreHeader(
    ThemeData theme,
    int myScore,
    int oppScore,
    String oppName,
  ) {
    final primary = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'You',
              style: theme.textTheme.titleMedium?.copyWith(
                color: primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              '$myScore',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Text(
                '–',
                style: theme.textTheme.headlineSmall?.copyWith(color: muted),
              ),
            ),
            Text(
              '$oppScore',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: 10.w),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 120.w),
              child: Text(
                oppName,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _revealArea(
    ThemeData theme,
    Map<String, dynamic>? reveal,
    bool amPlayerA,
  ) {
    if (reveal == null) {
      // Placeholder keeps the layout from jumping before the first reveal.
      return SizedBox(
        height: 96.h,
        child: Center(
          child: Text(
            'Make your move',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    final myPick = (amPlayerA ? reveal['a'] : reveal['b']) as String?;
    final oppPick = (amPlayerA ? reveal['b'] : reveal['a']) as String?;
    final winner = reveal['winner'] as String?;
    final mySide = amPlayerA ? 'a' : 'b';
    final draw = winner == 'draw';
    final iWonRound = winner == mySide;

    final (String line, Color color) = draw
        ? ('Draw', theme.colorScheme.onSurface.withValues(alpha: 0.6))
        : iWonRound
            ? ('You won the round!', AppColors.online)
            : ('You lost the round', AppColors.danger);

    return Container(
      height: 96.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceAlt.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _revealPick(theme, _emoji(myPick ?? 'rock'), 'You'),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              'vs',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _revealPick(theme, _emoji(oppPick ?? 'rock'), 'Them'),
          SizedBox(width: 16.w),
          Flexible(
            child: Text(
              line,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    )
        .animate(key: ValueKey(reveal['round']))
        .scale(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1, 1),
          duration: 300.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 200.ms);
  }

  Widget _revealPick(ThemeData theme, String emoji, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: TextStyle(fontSize: 32.sp)),
        SizedBox(height: 2.h),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _choiceRow({
    required ThemeData theme,
    required GameMatchProvider p,
    required bool iChose,
    required bool oppChose,
    required bool isOver,
  }) {
    final disabled = iChose || p.sending || isOver;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final o in _options) ...[
          _choiceCard(
            theme: theme,
            option: o,
            selected: _myChoice == o.value,
            disabled: disabled,
            onTap: disabled ? null : () => _pick(p, o.value),
          ),
          if (o != _options.last) SizedBox(width: 12.w),
        ],
      ],
    );
  }

  Widget _choiceCard({
    required ThemeData theme,
    required _RpsOption option,
    required bool selected,
    required bool disabled,
    required VoidCallback? onTap,
  }) {
    final primary = theme.colorScheme.primary;
    final dim = disabled && !selected;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: 160.ms,
        opacity: dim ? 0.45 : 1,
        child: Container(
          width: 96.w,
          padding: EdgeInsets.symmetric(vertical: 18.h),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.gradientFrom(primary) : null,
            color: selected ? null : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: selected
                  ? primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.08),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(option.emoji, style: TextStyle(fontSize: 40.sp)),
              SizedBox(height: 8.h),
              Text(
                option.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected ? Colors.white : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _waitingLine(
    ThemeData theme,
    bool iChose,
    bool oppChose,
    bool isOver,
    String oppName,
  ) {
    if (isOver || !iChose) return SizedBox(height: 20.h);

    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    if (oppChose) {
      return SizedBox(
        height: 20.h,
        child: Text(
          'Revealing…',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return SizedBox(
      height: 20.h,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14.r,
            height: 14.r,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(muted),
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            'Waiting for $oppName…',
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }

  void _pick(GameMatchProvider p, String choice) {
    setState(() => _myChoice = choice);
    HapticFeedback.selectionClick();
    p.chooseRps(choice);
  }
}

class _RpsOption {
  const _RpsOption(this.value, this.emoji, this.label);
  final String value;
  final String emoji;
  final String label;
}
