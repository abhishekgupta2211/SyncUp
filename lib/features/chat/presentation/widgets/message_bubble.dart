import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/chat_theme.dart';
import '../../../settings/data/providers/settings_provider.dart';
import '../../../../core/utils/chat_time.dart';
import '../../data/models/message.dart';
import '../../data/models/message_enums.dart';
import '../../data/models/reaction.dart';
import 'heart_status.dart';
import 'media_bubble.dart';
import 'tic_tac_toe.dart';
import 'voice_bubble.dart';

/// A single chat bubble — pink gradient (mine) or surface (peer), with reply
/// chip, reactions, timestamp + heart, swipe-to-reply and long-press actions.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.myId,
    this.repliedMessage,
    this.reactions = const [],
    this.onRetry,
    this.onLongPress,
    this.onSwipeReply,
  });

  final Message message;
  final String myId;
  final Message? repliedMessage;
  final List<Reaction> reactions;
  final VoidCallback? onRetry;
  final VoidCallback? onLongPress;
  final VoidCallback? onSwipeReply;

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine(myId);

    final content = message.deletedForEveryone
        ? _deletedBubble(context, mine)
        : _bubble(context, mine);

    final aligned = Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 3.h),
        child: (message.failed && mine)
            ? Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.refresh, size: 18.r, color: Colors.redAccent),
                    onPressed: onRetry,
                  ),
                  Flexible(child: content),
                ],
              )
            : content,
      ),
    );

    if (message.deletedForEveryone) return aligned;

    return Dismissible(
      key: ValueKey('swipe_${message.messageId}'),
      direction: DismissDirection.startToEnd,
      dismissThresholds: const {DismissDirection.startToEnd: 0.25},
      confirmDismiss: (_) async {
        onSwipeReply?.call();
        return false;
      },
      background: Padding(
        padding: EdgeInsets.only(left: 24.w),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Icon(Icons.reply,
              color: Theme.of(context).colorScheme.primary, size: 22.r),
        ),
      ),
      child: GestureDetector(onLongPress: onLongPress, child: aligned),
    );
  }

  Widget _bubble(BuildContext context, bool mine) {
    final theme = Theme.of(context);
    final chat = theme.extension<ChatTheme>()!;
    final radius = Radius.circular(18.r);

    if (message.isVanish && !mine && !message.seen) {
      return _vanishPlaceholder(context, chat, radius);
    }

    if (message.isSnap) {
      return _snapPlaceholder(context, chat, radius, mine);
    }

    return Animate(
      effects: [
        FadeEffect(duration: 200.ms, curve: Curves.easeOut),
        SlideEffect(
          begin: Offset(mine ? 0.2 : -0.2, 0.1),
          end: Offset.zero,
          duration: 300.ms,
          curve: Curves.easeOutBack,
        ),
        ScaleEffect(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.elasticOut,
        ),
      ],
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: 0.76.sw),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              gradient: mine ? chat.outgoingGradient : null,
              color: mine ? null : chat.incomingBubble,
              borderRadius: BorderRadius.only(
                topLeft: radius,
                topRight: radius,
                bottomLeft: mine ? radius : Radius.circular(4.r),
                bottomRight: mine ? Radius.circular(4.r) : radius,
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (repliedMessage != null) _replyChip(context, mine),
                _content(context, mine, theme, chat),
                SizedBox(height: 3.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ChatTime.time(message.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: mine
                            ? chat.outgoingText.withValues(alpha: 0.8)
                            : chat.timestamp,
                        fontSize: 10.sp,
                      ),
                    ),
                    if (mine) ...[
                      SizedBox(width: 5.w),
                      HeartStatus(state: message.deliveryState(myId), size: 13.r),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (reactions.isNotEmpty) _reactionsRow(context),
        ],
      ),
    );
  }

  Widget _content(
      BuildContext context, bool mine, ThemeData theme, ChatTheme chat) {
    if (message.isVanish) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, size: 16.r, color: mine ? Colors.white : Colors.orange),
          SizedBox(width: 6.w),
          _actualContent(context, mine, theme, chat),
        ],
      );
    }
    return _actualContent(context, mine, theme, chat);
  }

  Widget _actualContent(
      BuildContext context, bool mine, ThemeData theme, ChatTheme chat) {
    switch (message.messageType) {
      case MessageType.image:
        return ImageMessageContent(message: message);
      case MessageType.voice:
        return VoiceMessageContent(message: message, mine: mine);
      default:
        if (message.message.contains('🎮 Tic-Tac-Toe')) {
          return const TicTacToeGame();
        }
        final scale = context.watch<SettingsProvider>().fontScale;
        return Text(
          message.message,
          textScaler: TextScaler.linear(scale),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: mine ? chat.outgoingText : chat.incomingText,
            height: 1.3,
          ),
        );
    }
  }

  Widget _replyChip(BuildContext context, bool mine) {
    final theme = Theme.of(context);
    final chat = theme.extension<ChatTheme>()!;
    final onBubble = mine ? chat.outgoingText : chat.incomingText;
    return Container(
      margin: EdgeInsets.only(bottom: 5.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: onBubble.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8.r),
        border: Border(
          left: BorderSide(color: onBubble.withValues(alpha: 0.7), width: 2.5),
        ),
      ),
      child: Text(
        repliedMessage!.deletedForEveryone
            ? 'Deleted message'
            : repliedMessage!.message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: onBubble.withValues(alpha: 0.85),
          fontSize: 11.5.sp,
        ),
      ),
    );
  }

  Widget _reactionsRow(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = <String, int>{};
    for (final r in reactions) {
      grouped[r.emoji] = (grouped[r.emoji] ?? 0) + 1;
    }
    return Padding(
      padding: EdgeInsets.only(top: 4.h, left: 4.w, right: 4.w),
      child: Wrap(
        spacing: 4.w,
        children: grouped.entries.map((e) {
          return TweenAnimationBuilder<double>(
            key: ValueKey(e.key),
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12.r),
                border:
                    Border.all(color: theme.colorScheme.outline, width: 0.5),
              ),
              child: Text(
                e.value > 1 ? '${e.key} ${e.value}' : e.key,
                style: TextStyle(fontSize: 11.sp),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _snapPlaceholder(BuildContext context, ChatTheme chat, Radius radius, bool mine) {
    final opened = message.seen;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: mine ? null : chat.incomingBubble,
        gradient: mine ? chat.outgoingGradient : null,
        borderRadius: BorderRadius.all(radius),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(opened ? Icons.chat_bubble_outline : Icons.camera_alt, 
               color: mine ? Colors.white : Colors.purpleAccent, size: 20.r),
          SizedBox(width: 10.w),
          Text(
            opened ? 'Snap opened' : (mine ? 'Snap sent' : 'New Snap - Tap to view'),
            style: TextStyle(
              color: mine ? Colors.white : chat.incomingText,
              fontStyle: opened ? FontStyle.italic : FontStyle.normal,
              fontWeight: opened ? FontWeight.normal : FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vanishPlaceholder(BuildContext context, ChatTheme chat, Radius radius) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: chat.incomingBubble,
        borderRadius: BorderRadius.all(radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_delete, color: Colors.orange),
          SizedBox(width: 10.w),
          const Text('Tap to reveal vanish message 🔥', style: TextStyle(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _deletedBubble(BuildContext context, bool mine) {
    final theme = Theme.of(context);
    final chat = theme.extension<ChatTheme>()!;
    return Container(
      constraints: BoxConstraints(maxWidth: 0.76.sw),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: chat.incomingBubble.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block, size: 14.r, color: chat.timestamp),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              mine ? 'You deleted this message' : 'This message was deleted',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: chat.timestamp,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
