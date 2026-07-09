import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/settings_widgets.dart';

/// Help & Support / About.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        children: [
          SizedBox(height: 20.h),
          Center(
            child: Container(
              width: 76.r,
              height: 76.r,
              decoration: BoxDecoration(
                gradient: AppColors.gradientFrom(
                    Theme.of(context).colorScheme.primary),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.favorite, color: Colors.white, size: 38.r),
            ),
          ),
          SizedBox(height: 12.h),
          Center(
            child: Text(AppConfig.appName,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ),
          Center(
            child: Text('Version 1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ),
          SizedBox(height: 4.h),
          Center(
            child: Text(AppConfig.tagline,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          ),
          const SettingsSectionTitle('Get help'),
          const SettingsTile(
            icon: Icons.menu_book_outlined,
            title: 'How LoveChat works',
            subtitle:
                'Add a friend, wait for them to accept, then start chatting.',
          ),
          const SettingsTile(
            icon: Icons.lock_outline,
            title: 'Your privacy',
            subtitle:
                'Only accepted friends can message you. Block anyone anytime.',
          ),
          const SettingsTile(
            icon: Icons.shield_moon_outlined,
            title: 'Safety',
            subtitle: 'Report and block keep your space yours.',
          ),
        ],
      ),
    );
  }
}
