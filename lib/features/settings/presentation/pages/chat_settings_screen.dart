import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/chat_wallpaper.dart';
import '../../data/providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';
import 'wallpaper_screen.dart';

/// Chat settings — wallpaper, enter-to-send, font size.
class ChatSettingsScreen extends StatelessWidget {
  const ChatSettingsScreen({super.key});

  String _wallpaperLabel(SettingsProvider s) {
    if (s.wallpaperId == 'custom') return 'My photo';
    return wallpaperById(s.wallpaperId).label;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Chat Settings')),
      body: ListView(
        children: [
          const SettingsSectionTitle('Display'),
          SettingsTile(
            icon: Icons.wallpaper_outlined,
            title: 'Wallpaper',
            trailingText: _wallpaperLabel(s),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WallpaperScreen()),
            ),
          ),
          const SettingsSectionTitle('Sending'),
          SettingsSwitchTile(
            icon: Icons.keyboard_return,
            title: 'Enter is send',
            subtitle: 'Pressing enter sends the message',
            value: s.enterToSend,
            onChanged: s.setEnterToSend,
          ),
          const SettingsSectionTitle('Font size'),
          _fontTile(context, s, 0.9, 'Small'),
          _fontTile(context, s, 1.0, 'Default'),
          _fontTile(context, s, 1.15, 'Large'),
        ],
      ),
    );
  }

  Widget _fontTile(
      BuildContext context, SettingsProvider s, double scale, String label) {
    final theme = Theme.of(context);
    final selected = (s.fontScale - scale).abs() < 0.01;
    return ListTile(
      onTap: () => s.setFontScale(scale),
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 2.h),
      leading: Container(
        width: 40.r,
        height: 40.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text('A',
            style: TextStyle(
                fontSize: 13.sp * scale,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary)),
      ),
      title: Text(label, style: theme.textTheme.bodyLarge),
      trailing: selected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : Icon(Icons.circle_outlined,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
    );
  }
}
