import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.primary.withValues(alpha: 0.05),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- Modern Tech Logo ---
            _SyncUpLogo()
                .animate()
                .fadeIn(duration: 800.ms)
                .scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut, duration: 1200.ms)
                .shimmer(delay: 1500.ms, duration: 2.seconds),
            
            SizedBox(height: 32.h),
            
            // --- App Name with Spacing ---
            Text(
              'SYNCUP',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
                color: theme.colorScheme.primary,
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
            
            SizedBox(height: 8.h),
            
            Text(
              'THE AI SOCIAL HUB',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ).animate().fadeIn(delay: 800.ms),
            
            SizedBox(height: 100.h),
            
            // --- Loading Indicator ---
            SizedBox(
              width: 40.w,
              child: LinearProgressIndicator(
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
            ).animate().fadeIn(delay: 1.seconds),
          ],
        ),
      ),
    );
  }
}

class _SyncUpLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 100.r,
      height: 100.r,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Center(
        child: Icon(
          Icons.sync_rounded,
          size: 60.r,
          color: Colors.white,
        ),
      ),
    );
  }
}
