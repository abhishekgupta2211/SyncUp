import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/providers/games_lobby_provider.dart';
import '../pages/games_page.dart';

/// A draggable, edge-snapping "Games" bubble that floats over the Chats page.
/// Tap it to open the Games hub; it shows a badge when a match awaits your move.
class GamesFab extends StatefulWidget {
  const GamesFab({super.key});

  @override
  State<GamesFab> createState() => _GamesFabState();
}

class _GamesFabState extends State<GamesFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob;
  Offset? _pos;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = 58.r;
    final margin = 16.w;
    return LayoutBuilder(
      builder: (context, c) {
        final maxX = c.maxWidth - size;
        final maxY = c.maxHeight - size;
        _pos ??= Offset(maxX - margin, maxY - margin - 12.h);
        final pos = Offset(
          _pos!.dx.clamp(0.0, maxX),
          _pos!.dy.clamp(0.0, maxY),
        );
        return Stack(
          children: [
            AnimatedPositioned(
              duration:
                  _dragging ? Duration.zero : const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              left: pos.dx,
              top: pos.dy,
              width: size,
              height: size,
              child: GestureDetector(
                onTap: _open,
                onPanStart: (_) => setState(() => _dragging = true),
                onPanUpdate: (d) =>
                    setState(() => _pos = (_pos ?? pos) + d.delta),
                onPanEnd: (_) => _snap(c, size, margin),
                child: AnimatedBuilder(
                  animation: _bob,
                  builder: (context, child) {
                    final dy = _dragging
                        ? 0.0
                        : math.sin(_bob.value * 2 * math.pi) * 3.0;
                    return Transform.translate(
                        offset: Offset(0, dy), child: child);
                  },
                  child: _bubble(context, size),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _snap(BoxConstraints c, double size, double margin) {
    final p = _pos;
    if (p == null) return;
    final maxX = c.maxWidth - size;
    final maxY = c.maxHeight - size;
    final toLeft = (p.dx + size / 2) < c.maxWidth / 2;
    setState(() {
      _dragging = false;
      _pos = Offset(
        toLeft ? margin : maxX - margin,
        p.dy.clamp(margin, maxY - margin),
      );
    });
  }

  void _open() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GamesHubPage()),
    );
  }

  Widget _bubble(BuildContext context, double size) {
    final theme = Theme.of(context);
    final turns = context.watch<GamesLobbyProvider>().myTurnCount;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: AppColors.gradientFrom(theme.colorScheme.primary),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(Icons.sports_esports_rounded,
              color: Colors.white, size: 28.r),
        ),
        if (turns > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: EdgeInsets.all(4.r),
              constraints: BoxConstraints(minWidth: 20.r, minHeight: 20.r),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
                border: Border.all(
                    color: theme.scaffoldBackgroundColor, width: 2),
              ),
              child: Text(
                '$turns',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
