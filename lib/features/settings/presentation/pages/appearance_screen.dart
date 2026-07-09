import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../widgets/settings_widgets.dart';

/// Appearance — light / dark / system theme + a user-selectable accent colour.
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        children: [
          const SettingsSectionTitle('Theme'),
          _modeTile(context, tp, ThemeMode.system, 'System default',
              Icons.brightness_auto_outlined),
          _modeTile(context, tp, ThemeMode.light, 'Light',
              Icons.light_mode_outlined),
          _modeTile(
              context, tp, ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
          const SettingsSectionTitle('Accent color'),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
            child: Wrap(
              spacing: 16.w,
              runSpacing: 16.h,
              children: [
                for (final c in AppColors.accentPresets)
                  _accentSwatch(context, tp, c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeTile(BuildContext context, ThemeProvider tp, ThemeMode mode,
      String label, IconData icon) {
    final theme = Theme.of(context);
    final selected = tp.mode == mode;
    return ListTile(
      onTap: () => tp.setMode(mode),
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 2.h),
      leading: Container(
        width: 40.r,
        height: 40.r,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, size: 20.r, color: theme.colorScheme.primary),
      ),
      title: Text(label, style: theme.textTheme.bodyLarge),
      trailing: selected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : Icon(Icons.circle_outlined,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
    );
  }

  Widget _accentSwatch(BuildContext context, ThemeProvider tp, Color color) {
    final selected = tp.accent.toARGB32() == color.toARGB32();
    return GestureDetector(
      onTap: () => tp.setAccent(color),
      child: Container(
        width: 48.r,
        height: 48.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AppColors.gradientFrom(color),
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: selected
            ? Icon(Icons.check, color: Colors.white, size: 22.r)
            : null,
      ),
    );
  }
}
