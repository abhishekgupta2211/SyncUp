import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../data/providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';
import 'blocked_users_screen.dart';

/// Privacy — last seen, online status, read receipts.
class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(
        children: [
          const SettingsSectionTitle('Who can see my info'),
          SettingsSwitchTile(
            icon: Icons.visibility_outlined,
            title: 'Last seen',
            subtitle: 'Show when you were last online',
            value: s.showLastSeen,
            onChanged: s.setShowLastSeen,
          ),
          SettingsSwitchTile(
            icon: Icons.circle,
            title: 'Online status',
            subtitle: 'Show a green dot when you are active',
            value: s.showOnline,
            onChanged: s.setShowOnline,
          ),
          SettingsSwitchTile(
            icon: Icons.done_all,
            title: 'Read receipts',
            subtitle: 'Send and receive the seen ❤️',
            value: s.readReceipts,
            onChanged: s.setReadReceipts,
          ),
          const SettingsSectionTitle('Blocking'),
          SettingsTile(
            icon: Icons.block,
            title: 'Blocked contacts',
            subtitle: "Manage who you've blocked",
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
            child: Text(
              'These preferences are saved on this device.',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}
