import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The SyncUp mark: a purple→indigo gradient rounded square with two connected
/// chat bubbles (conversation + sync).
class GradientLogo extends StatelessWidget {
  const GradientLogo({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppColors.pinkGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.pink.withValues(alpha: 0.5),
            blurRadius: size * 0.4,
            offset: Offset(0, size * 0.14),
          ),
        ],
      ),
      child: Icon(Icons.forum_rounded, color: Colors.white, size: size * 0.5),
    );
  }
}
