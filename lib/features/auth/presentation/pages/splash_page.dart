import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0C),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.15),
              const Color(0xFF0C0C0C),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- Premium Rider Icon Animation ---
            _RiderLogo()
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .shimmer(duration: 2.seconds, color: Colors.white24)
                .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds, curve: Curves.easeInOut),
            
            SizedBox(height: 48.h),
            
            // --- App Name: REVV RIDE ---
            Text(
              'REVV RIDE',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                color: Colors.white,
              ),
            ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.3, end: 0, curve: Curves.easeOutBack),
            
            SizedBox(height: 12.h),
            
            // --- Slogan: Born to Ride. Built to Connect. ---
            Text(
              'Born to Ride. Built to Connect.',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            )
            .animate(delay: 500.ms)
            .fadeIn(duration: 1.seconds)
            .blur(begin: const Offset(5, 5), end: Offset.zero, duration: 800.ms),
            
            SizedBox(height: 120.h),
            
            // --- Technical Progress Bar ---
            Container(
              width: 200.w,
              height: 2.h,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(seconds: 2),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return FractionallySizedBox(
                        widthFactor: value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiderLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 140.r,
      height: 140.r,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(40.r),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.motorcycle_rounded,
            size: 84.r,
            color: Colors.white,
          ),
          Positioned(
            bottom: 20.r,
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
