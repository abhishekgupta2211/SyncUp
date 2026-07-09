import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';

/// Notifications — master toggle + sound / vibrate / preview.
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    final on = s.notifications;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          const SettingsSectionTitle('Notifications'),
          SettingsSwitchTile(
            icon: Icons.notifications_active_outlined,
            title: 'Allow notifications',
            subtitle: 'Get notified about new messages',
            value: on,
            onChanged: s.setNotifications,
          ),
          const SettingsSectionTitle('Message alerts'),
          SettingsSwitchTile(
            icon: Icons.volume_up_outlined,
            title: 'Sound',
            value: on && s.notifSound,
            onChanged: on ? s.setNotifSound : null,
          ),
          SettingsSwitchTile(
            icon: Icons.vibration,
            title: 'Vibrate',
            value: on && s.notifVibrate,
            onChanged: on ? s.setNotifVibrate : null,
          ),
          SettingsSwitchTile(
            icon: Icons.chat_bubble_outline,
            title: 'Show preview',
            subtitle: 'Display message text in the notification',
            value: on && s.notifPreview,
            onChanged: on ? s.setNotifPreview : null,
          ),
        ],
      ),
    );
  }
}
