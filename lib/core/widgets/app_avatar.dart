import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';

/// Circular avatar: shows the network image when available, otherwise a
/// gradient circle with the user's initials. Optional online dot.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.radius = 24,
    this.showOnline = false,
    this.isOnline = false,
    this.isVip = false,
    this.hasStory = false, // NEW
  });

  final String name;
  final String? avatarUrl;
  final double radius;
  final bool showOnline;
  final bool isOnline;
  final bool isVip;
  final bool hasStory;

  String get _initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return (parts.first.characters.first + parts[1].characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;
    Widget avatar = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasImage
            ? null
            : AppColors.gradientFrom(Theme.of(context).colorScheme.primary),
        image: hasImage
            ? DecorationImage(
                image: NetworkImage(avatarUrl!), fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: hasImage
          ? null
          : Text(
              _initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.8,
              ),
            ),
    );

    if (hasStory) {
      avatar = Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.purple, Colors.pink, Colors.orange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, shape: BoxShape.circle),
          child: avatar,
        ),
      );
    }

    if (isVip) {
      avatar = Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: radius * 2 + 6,
            height: radius * 2 + 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [Colors.amber, Colors.orange, Colors.yellow, Colors.amber],
              ),
            ),
          ).animate(onPlay: (c) => c.repeat()).rotate(duration: 3.seconds),
          avatar,
        ],
      );
    }

    if (!showOnline) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.5,
              height: radius * 0.5,
              decoration: BoxDecoration(
                color: AppColors.online,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
