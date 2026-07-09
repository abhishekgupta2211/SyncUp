import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';

/// A frosted result card shown over the board when the match ends.
class GameResultOverlay extends StatelessWidget {
  const GameResultOverlay({
    super.key,
    required this.headline,
    required this.subtitle,
    required this.outcome,
    required this.onPlayAgain,
    required this.onClose,
    this.busy = false,
  });

  final String headline;
  final String subtitle;
  final GameOutcome outcome;
  final VoidCallback onPlayAgain;
  final VoidCallback onClose;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = switch (outcome) {
      GameOutcome.won => (Icons.emoji_events_rounded, const Color(0xFFF59E0B)),
      GameOutcome.lost => (Icons.sentiment_dissatisfied_rounded,
          theme.colorScheme.onSurface.withValues(alpha: 0.7)),
      GameOutcome.draw => (Icons.handshake_rounded, theme.colorScheme.primary),
    };

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        alignment: Alignment.center,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 40.w),
          padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 22.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78.r,
                height: 78.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.gradientFrom(color),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 42.r),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.4, 0.4),
                    end: const Offset(1, 1),
                    duration: 520.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 220.ms),
              SizedBox(height: 18.h),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 6.h),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              SizedBox(height: 22.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : onClose,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r)),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: FilledButton(
                      onPressed: busy ? null : onPlayAgain,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r)),
                      ),
                      child: busy
                          ? SizedBox(
                              width: 20.r,
                              height: 20.r,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text('Play again'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 260.ms),
    );
  }
}

enum GameOutcome { won, lost, draw }
