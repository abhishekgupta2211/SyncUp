import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/chat_wallpaper.dart';
import '../../../settings/data/providers/settings_provider.dart';

/// Paints the selected chat wallpaper (preset gradient/solid or a user image)
/// behind [child]. A scrim keeps message bubbles readable over photos.
class WallpaperBackground extends StatelessWidget {
  const WallpaperBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    if (s.wallpaperId == 'default') return child;

    if (s.wallpaperId == 'custom' && s.wallpaperPath != null) {
      final file = File(s.wallpaperPath!);
      if (file.existsSync()) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(file, fit: BoxFit.cover),
            Container(
              color: theme.colorScheme.surface.withValues(alpha: 0.35),
            ),
            child,
          ],
        );
      }
      return child;
    }

    final w = wallpaperById(s.wallpaperId);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: w.gradient, color: w.color),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(painter: _SparklePainter()),
            ).animate(onPlay: (c) => c.repeat()).fade(duration: 2.seconds, begin: 0.2, end: 0.8),
          ),
          child,
        ],
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    // Drawing a few fixed dots for performance instead of using Random
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.1), 1, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.3), 1.5, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.7), 1.2, paint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.9), 1, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.5), 1.4, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
