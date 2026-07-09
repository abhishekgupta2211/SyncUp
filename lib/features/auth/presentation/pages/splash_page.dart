import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_logo.dart';

/// Premium animated splash shown while the session is being restored.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A2358), Color(0xFF181640), Color(0xFF0C0F26)],
          ),
        ),
        child: Stack(
          children: [
            // ---- soft floating blobs ----
            Positioned(
              top: -60.h,
              left: -70.w,
              child: _blobCircle(const Color(0xFF6C63FF), 300.r)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(
                      begin: 0,
                      end: 26.h,
                      duration: 3600.ms,
                      curve: Curves.easeInOut),
            ),
            Positioned(
              bottom: -50.h,
              right: -60.w,
              child: _blobCircle(const Color(0xFF3B82F6), 260.r)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(
                      begin: 0,
                      end: -24.h,
                      duration: 4200.ms,
                      curve: Curves.easeInOut),
            ),
            Positioned(
              top: 220.h,
              right: -40.w,
              child: _blobCircle(const Color(0xFF8B5CF6), 180.r)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveX(
                      begin: 0,
                      end: -20.w,
                      duration: 5000.ms,
                      curve: Curves.easeInOut),
            ),

            // ---- center content ----
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // glow + logo
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 190.r,
                        height: 190.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            AppColors.pink.withValues(alpha: 0.55),
                            AppColors.pink.withValues(alpha: 0.0),
                          ]),
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(
                              begin: 0.82,
                              end: 1.12,
                              duration: 1600.ms,
                              curve: Curves.easeInOut),
                      const GradientLogo(size: 96)
                          .animate()
                          .scale(
                              begin: const Offset(0, 0),
                              end: const Offset(1, 1),
                              duration: 900.ms,
                              curve: Curves.elasticOut)
                          .fadeIn(duration: 400.ms),
                    ],
                  ),
                  SizedBox(height: 26.h),
                  Text(
                    AppConfig.appName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ).animate().fadeIn(delay: 450.ms, duration: 500.ms),
                  SizedBox(height: 8.h),
                  Text(
                    AppConfig.tagline,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 800.ms, duration: 500.ms)
                      .slideY(
                          begin: 0.6,
                          end: 0,
                          delay: 800.ms,
                          duration: 500.ms,
                          curve: Curves.easeOut),
                ],
              ),
            ),

            // ---- loader ----
            Positioned(
              left: 0,
              right: 0,
              bottom: 70.h,
              child: Center(
                child: SizedBox(
                  width: 26.r,
                  height: 26.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor:
                        AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.85)),
                  ),
                ).animate().fadeIn(delay: 1200.ms),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blobCircle(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            color.withValues(alpha: 0.45),
            color.withValues(alpha: 0.0),
          ]),
        ),
      ),
    );
  }
}
