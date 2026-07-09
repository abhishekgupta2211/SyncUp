import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A pill showing whose turn it is, with a pulsing dot when it's yours.
class TurnBanner extends StatelessWidget {
  const TurnBanner({super.key, required this.isMyTurn, required this.label});

  final bool isMyTurn;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isMyTurn
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.6);

    Widget dot = Container(
      width: 9.r,
      height: 9.r,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    if (isMyTurn) {
      dot = dot
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.4, 1.4),
            duration: 900.ms,
            curve: Curves.easeInOut,
          );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: isMyTurn
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dot,
          SizedBox(width: 8.w),
          Text(
            label,
            style: theme.textTheme.labelLarge
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
