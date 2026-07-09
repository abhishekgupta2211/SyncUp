import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/providers/notifications_provider.dart';
import '../pages/notifications_page.dart';

/// Bell icon with a live unread-count badge; opens the notification center.
class NotificationsBell extends StatelessWidget {
  const NotificationsBell({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = context.watch<NotificationsProvider>().unread;
    return IconButton(
      tooltip: 'Notifications',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NotificationsPage()),
      ),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: Icon(Icons.notifications_none, color: theme.colorScheme.primary),
      ),
    );
  }
}
