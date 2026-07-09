import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/utils/chat_time.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../games/data/repositories/game_repository.dart';
import '../../../games/presentation/pages/games_page.dart';
import '../../data/models/app_notification.dart';
import '../../data/providers/notifications_provider.dart';

/// The in-app notification center — a live list of alerts with mark-read,
/// swipe-to-delete, mark-all-read and clear-all.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    // Mark all as read when the user views the notifications list.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<NotificationsProvider>();
    final items = provider.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (items.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'read') provider.markAllRead();
                if (v == 'clear') provider.clearAll();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'read', child: Text('Mark all as read')),
                PopupMenuItem(value: 'clear', child: Text('Clear all')),
              ],
            ),
        ],
      ),
      body: provider.loading
          ? Center(
              child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : items.isEmpty
              ? const EmptyState(
                  icon: Icons.notifications_none,
                  title: "You're all caught up",
                  subtitle:
                      'Friend requests, story likes and more will show up here.',
                )
              : RefreshIndicator(
                  onRefresh: provider.load,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => Divider(
                        height: 1, indent: 76.w, endIndent: 16.w),
                    itemBuilder: (context, i) =>
                        _tile(context, theme, provider, items[i]),
                  ),
                ),
    );
  }

  Widget _tile(BuildContext context, ThemeData theme,
      NotificationsProvider provider, AppNotification n) {
    final (icon, color) = _iconFor(n.type, theme);
    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => provider.remove(n.id),
      background: Container(
        color: theme.colorScheme.error.withValues(alpha: 0.85),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24.w),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: ListTile(
        onTap: () => _openNotification(context, provider, n),
        tileColor:
            n.read ? null : theme.colorScheme.primary.withValues(alpha: 0.06),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        leading: SizedBox(
          width: 46.r,
          height: 46.r,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AppAvatar(
                  name: n.actorName ?? 'User',
                  avatarUrl: n.actorAvatarUrl,
                  radius: 23.r),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: theme.scaffoldBackgroundColor, width: 2),
                  ),
                  child: Icon(icon, size: 11.r, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        title: Text.rich(
          TextSpan(children: [
            TextSpan(
              text: n.actorName ?? n.title,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (n.body != null)
              TextSpan(
                text: ' ${n.body}',
                style: theme.textTheme.bodyMedium,
              ),
          ]),
        ),
        subtitle: Text(ChatTime.listLabel(n.createdAt)),
        trailing: n.read
            ? null
            : Container(
                width: 9.r,
                height: 9.r,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }

  Future<void> _openNotification(
    BuildContext context,
    NotificationsProvider provider,
    AppNotification n,
  ) async {
    // markRead is already called in markAllRead at initState, 
    // but we can call it again just in case.
    provider.markRead(n.id);
    if (n.type != 'game_invite') return;
    final matchId = n.data?['match_id'] as String?;
    if (matchId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final match =
          await GameRepository(SupabaseService.client).fetchMatch(matchId);
      if (!context.mounted) return;
      openGame(context, match);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open the game.')),
      );
    }
  }

  (IconData, Color) _iconFor(String type, ThemeData theme) {
    switch (type) {
      case 'friend_request':
        return (Icons.person_add_alt_1, theme.colorScheme.primary);
      case 'friend_accept':
        return (Icons.how_to_reg, const Color(0xFF22C55E));
      case 'game_invite':
        return (Icons.sports_esports, theme.colorScheme.primary);
      case 'story_like':
        return (Icons.favorite, const Color(0xFFEC4899));
      case 'story_comment':
        return (Icons.chat_bubble, theme.colorScheme.primary);
      case 'reaction':
        return (Icons.emoji_emotions, const Color(0xFFF59E0B));
      case 'call':
        return (Icons.call, const Color(0xFF22C55E));
      default:
        return (Icons.notifications, theme.colorScheme.primary);
    }
  }
}
