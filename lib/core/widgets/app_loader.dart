import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';

/// Branded loader — a pulsing pink→magenta gradient heart.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.size = 40, this.label});

  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heart = ShaderMask(
      shaderCallback: (rect) =>
          AppColors.gradientFrom(theme.colorScheme.primary).createShader(rect),
      child: Icon(Icons.favorite, size: size.r, color: Colors.white),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(0.78, 0.78),
          end: const Offset(1.12, 1.12),
          duration: 650.ms,
          curve: Curves.easeInOut,
        )
        .fadeIn(duration: 400.ms);

    if (label == null) return Center(child: heart);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          heart,
          SizedBox(height: 12.h),
          Text(
            label!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small inline pulsing heart (for buttons / tiles).
class MiniLoader extends StatelessWidget {
  const MiniLoader({super.key, this.size = 18, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.r,
      height: size.r,
      child: CircularProgressIndicator(
        strokeWidth: 2.2,
        valueColor:
            AlwaysStoppedAnimation(color ?? Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
