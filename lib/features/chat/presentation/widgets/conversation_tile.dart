import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/presence/presence_provider.dart';
import '../../../../core/theme/chat_theme.dart';
import '../../../../core/utils/chat_time.dart';
import '../../../../core/utils/message_preview.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/models/conversation.dart';

class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    this.onTap,
    this.onLongPress,
  });

  final Conversation conversation;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chat = theme.extension<ChatTheme>()!;
    final unread = conversation.unreadCount;
    final hasUnread = unread > 0;
    final online = context.watch<PresenceProvider>().isOnline(conversation.peerId);
    final preview = MessagePreview.of(
      type: conversation.lastMessageType,
      text: conversation.lastMessageText,
    );

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
        child: Row(
          children: [
            AppAvatar(
              name: conversation.peerName,
              avatarUrl: conversation.peerAvatarUrl,
              radius: 27.r,
              showOnline: true,
              isOnline: online,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.peerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight:
                          hasUnread ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  if (conversation.peerName.length % 7 == 0) // Simulation
                    Text(
                      'typing...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate(onPlay: (c) => c.repeat()).fade(duration: 500.ms)
                  else
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: hasUnread
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.85)
                            : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        fontWeight:
                            hasUnread ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (conversation.lastMessageAt != null)
                  Text(
                    ChatTime.listLabel(conversation.lastMessageAt!),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: hasUnread
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight:
                          hasUnread ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                SizedBox(height: 6.h),
                if (hasUnread)
                  Container(
                    constraints: BoxConstraints(minWidth: 20.r),
                    height: 20.r,
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    decoration: BoxDecoration(
                      color: chat.unreadBadge,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.sp,
                      ),
                    ),
                  )
                else
                  SizedBox(height: 20.r),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
