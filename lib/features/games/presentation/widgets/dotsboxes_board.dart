import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/providers/game_match_provider.dart';
import 'turn_banner.dart';

/// The Dots & Boxes board: 5×5 dots forming a 4×4 grid of boxes.
///
/// A score row and turn banner sit above a square board of 9 interleaved rows
/// (5 dot-rows, 4 box-rows). Dots and vertical edges are a fixed width; the
/// horizontal edges and boxes flex to fill the rest. Tapping an undrawn edge
/// claims it; completing a box (server-decided) keeps the turn yours.
///
/// Edge colours are fixed by symbol (not by viewer): drawn edges use the
/// primary accent, box owners are 'A' → purple, 'B' → amber.
class DotsBoxesBoard extends StatelessWidget {
  const DotsBoxesBoard({super.key});

  static const _ownerA = AppColors.pink; // purple
  static const _ownerB = Color(0xFFF59E0B); // amber

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GameMatchProvider>();
    final m = p.match;
    final me = p.me;

    final myTurn = m.isMyTurn(me);
    final canPlay = myTurn && !p.sending && !m.status.isOver;

    final amA = m.amPlayerA(me);
    final myScore = amA ? m.dbScoreA : m.dbScoreB;
    final oppScore = amA ? m.dbScoreB : m.dbScoreA;
    final oppName = m.opponentName(me) ?? 'Opponent';

    final h = m.dbH;
    final v = m.dbV;
    final boxes = m.dbBoxes;

    void play(String edge, int idx) {
      if (!canPlay) return;
      HapticFeedback.lightImpact();
      p.sendMove({'edge': edge, 'index': idx});
    }

    return Column(
      children: [
        _ScoreRow(
          myScore: myScore,
          oppScore: oppScore,
          oppName: oppName,
        ),
        SizedBox(height: 12.h),
        TurnBanner(
          isMyTurn: myTurn,
          label: myTurn ? 'Your turn' : "$oppName's turn",
        ),
        SizedBox(height: 20.h),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 340.w),
              child: AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final dotSize = 11.r;
                    return Column(
                      children: [
                        for (var r = 0; r < 5; r++) ...[
                          _dotRow(context, r, dotSize, h, play, canPlay),
                          if (r < 4)
                            Expanded(
                              child: _boxRow(
                                context,
                                r,
                                dotSize,
                                v,
                                boxes,
                                play,
                                canPlay,
                              ),
                            ),
                        ],
                      ],
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

  // A dot-row: dot, hEdge, dot, hEdge, ... dot. Fixed height = dot size.
  Widget _dotRow(
    BuildContext context,
    int r,
    double dotSize,
    List<bool> h,
    void Function(String, int) play,
    bool canPlay,
  ) {
    final children = <Widget>[];
    for (var c = 0; c < 4; c++) {
      children.add(_Dot(size: dotSize));
      final idx = r * 4 + c;
      final drawn = idx < h.length && h[idx];
      children.add(
        Expanded(
          child: _HEdge(
            drawn: drawn,
            thickness: dotSize,
            onTap: (!drawn && canPlay) ? () => play('h', idx) : null,
          ),
        ),
      );
    }
    children.add(_Dot(size: dotSize));
    return SizedBox(
      height: dotSize,
      child: Row(children: children),
    );
  }

  // A box-row: vEdge, box, vEdge, box, ... vEdge. Flexes to fill vertical space.
  Widget _boxRow(
    BuildContext context,
    int r,
    double dotSize,
    List<bool> v,
    List<String> boxes,
    void Function(String, int) play,
    bool canPlay,
  ) {
    final children = <Widget>[];
    for (var c = 0; c < 4; c++) {
      final vIdx = r * 5 + c;
      final vDrawn = vIdx < v.length && v[vIdx];
      children.add(
        _VEdge(
          drawn: vDrawn,
          width: dotSize,
          onTap: (!vDrawn && canPlay) ? () => play('v', vIdx) : null,
        ),
      );
      final bIdx = r * 4 + c;
      final owner = bIdx < boxes.length ? boxes[bIdx] : '';
      children.add(Expanded(child: _Box(owner: owner)));
    }
    // trailing vertical edge (c == 4)
    final vIdx = r * 5 + 4;
    final vDrawn = vIdx < v.length && v[vIdx];
    children.add(
      _VEdge(
        drawn: vDrawn,
        width: dotSize,
        onTap: (!vDrawn && canPlay) ? () => play('v', vIdx) : null,
      ),
    );
    return Row(children: children);
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.myScore,
    required this.oppScore,
    required this.oppName,
  });

  final int myScore;
  final int oppScore;
  final String oppName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    final baseStyle = theme.textTheme.titleMedium;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('You ', style: baseStyle?.copyWith(color: muted)),
        Text(
          '$myScore',
          style: baseStyle?.copyWith(
            color: primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text('  –  ', style: baseStyle?.copyWith(color: muted)),
        Text(
          '$oppScore',
          style: baseStyle?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(' $oppName', style: baseStyle?.copyWith(color: muted)),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// A horizontal edge between two dots. Fills the row-height so undrawn edges are
/// easy to tap; the visible line is a thin centered bar.
class _HEdge extends StatelessWidget {
  const _HEdge({
    required this.drawn,
    required this.thickness,
    required this.onTap,
  });

  final bool drawn;
  final double thickness;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final line = _EdgeLine(
      drawn: drawn,
      horizontal: true,
      color: theme.colorScheme.primary,
      hairline: theme.colorScheme.onSurface.withValues(alpha: 0.12),
    );

    if (onTap == null) {
      return SizedBox(height: thickness, child: Center(child: line));
    }
    // Generous vertical padding so the thin hairline is easy to hit.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: thickness,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 2.r),
          child: Center(child: line),
        ),
      ),
    );
  }
}

/// A vertical edge between two dots. Fixed width (= dot size); fills the box-row
/// height. Undrawn edges get horizontal padding for an easy tap target.
class _VEdge extends StatelessWidget {
  const _VEdge({
    required this.drawn,
    required this.width,
    required this.onTap,
  });

  final bool drawn;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final line = _EdgeLine(
      drawn: drawn,
      horizontal: false,
      color: theme.colorScheme.primary,
      hairline: theme.colorScheme.onSurface.withValues(alpha: 0.12),
    );

    if (onTap == null) {
      return SizedBox(width: width, child: Center(child: line));
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.r),
          child: Center(child: line),
        ),
      ),
    );
  }
}

/// The visible line for an edge — a solid primary bar when drawn, a faint
/// hairline when not. Animates the fill in when it flips to drawn.
class _EdgeLine extends StatelessWidget {
  const _EdgeLine({
    required this.drawn,
    required this.horizontal,
    required this.color,
    required this.hairline,
  });

  final bool drawn;
  final bool horizontal;
  final Color color;
  final Color hairline;

  @override
  Widget build(BuildContext context) {
    final thick = 4.r;
    final thin = 1.5.r;

    Widget bar = Container(
      width: horizontal ? double.infinity : (drawn ? thick : thin),
      height: horizontal ? (drawn ? thick : thin) : double.infinity,
      decoration: BoxDecoration(
        color: drawn ? color : hairline,
        borderRadius: BorderRadius.circular(thick),
      ),
    );

    if (drawn) {
      bar = TweenAnimationBuilder<double>(
        key: const ValueKey('drawn'),
        tween: Tween(begin: 0.7, end: 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.elasticOut,
        builder: (_, scale, child) => Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: child,
        ),
        child: bar,
      );
    }
    return bar;
  }
}

/// A single box cell. Transparent when unclaimed; tinted in the owner's colour
/// with a small centered dot when claimed.
class _Box extends StatelessWidget {
  const _Box({required this.owner});

  final String owner; // '' | 'A' | 'B'

  @override
  Widget build(BuildContext context) {
    final owned = owner.isNotEmpty;
    final ownerColor =
        owner == 'A' ? DotsBoxesBoard._ownerA : DotsBoxesBoard._ownerB;

    Widget content = Container(
      color: owned ? ownerColor.withValues(alpha: 0.35) : Colors.transparent,
      alignment: Alignment.center,
      child: owned
          ? Container(
              width: 10.r,
              height: 10.r,
              decoration: BoxDecoration(
                color: ownerColor,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );

    if (owned) {
      content = TweenAnimationBuilder<double>(
        key: ValueKey(owner),
        tween: Tween(begin: 0.7, end: 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.elasticOut,
        builder: (_, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: content,
      );
    }
    return content;
  }
}
