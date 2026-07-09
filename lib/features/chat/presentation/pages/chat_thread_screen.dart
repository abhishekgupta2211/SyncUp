import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../../../core/calls/call_service.dart';
import '../../../../core/presence/presence_provider.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/chat_time.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/models/message.dart';
import '../../data/providers/chat_controller.dart';
import '../../data/repositories/chat_repository.dart';
import '../../../calls/data/repositories/call_log_repository.dart';
import '../../../contacts/data/repositories/contacts_repository.dart';
import 'conversation_media_page.dart';
import '../widgets/chat_date_chip.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/message_actions_sheet.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/wallpaper_background.dart';

Future<void> openChat(
  BuildContext context, {
  required String conversationId,
  required String peerId,
  required String peerName,
  required String peerUsername,
  String? peerAvatarUrl,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ChatThreadScreen(
        conversationId: conversationId,
        peerId: peerId,
        peerName: peerName,
        peerUsername: peerUsername,
        peerAvatarUrl: peerAvatarUrl,
      ),
    ),
  );
}

class ChatThreadScreen extends StatelessWidget {
  const ChatThreadScreen({
    super.key,
    required this.conversationId,
    required this.peerId,
    required this.peerName,
    required this.peerUsername,
    this.peerAvatarUrl,
  });

  final String conversationId;
  final String peerId;
  final String peerName;
  final String peerUsername;
  final String? peerAvatarUrl;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatController>(
      create: (_) => ChatController(
        repository: ChatRepository(SupabaseService.client),
        conversationId: conversationId,
        peerId: peerId,
        myId: SupabaseService.currentUserId!,
      ),
      child: _ChatThreadView(
        conversationId: conversationId,
        peerId: peerId,
        peerName: peerName,
        peerUsername: peerUsername,
        peerAvatarUrl: peerAvatarUrl,
      ),
    );
  }
}

class _ChatThreadView extends StatefulWidget {
  const _ChatThreadView({
    required this.conversationId,
    required this.peerId,
    required this.peerName,
    required this.peerUsername,
    this.peerAvatarUrl,
  });

  final String conversationId;
  final String peerId;
  final String peerName;
  final String peerUsername;
  final String? peerAvatarUrl;

  @override
  State<_ChatThreadView> createState() => _ChatThreadViewState();
}

class _ChatThreadViewState extends State<_ChatThreadView> {
  final _scroll = ScrollController();
  String? _lastId;
  String? _firstId;
  DateTime? _peerLastSeen;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ls =
          await context.read<PresenceProvider>().fetchLastSeen(widget.peerId);
      if (mounted) setState(() => _peerLastSeen = ls);
    });
  }

  void _onScroll() {
    if (_scroll.position.pixels <= 80) {
      context.read<ChatController>().loadMore();
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _comingSoon(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what — coming soon')),
    );
  }

  Future<void> _blockPeer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Block @${widget.peerUsername}?'),
        content: const Text(
            "They won't be able to message you and this chat will be hidden. "
            'You can unblock from search anytime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Block',
                style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ContactsRepository(SupabaseService.client).blockUser(widget.peerId);
      if (mounted) Navigator.of(context).pop(); // leave the now-blocked chat
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not block. Try again.')),
        );
      }
    }
  }

  Widget _callButton({required bool isVideo}) {
    return ZegoSendCallInvitationButton(
      isVideoCall: isVideo,
      onPressed: (code, message, errorInvitees) {
        // Record the placed call so it shows in the Calls tab (RLS lets the
        // peer see it too, as an incoming call).
        if (errorInvitees.isEmpty) {
          CallLogRepository(SupabaseService.client)
              .logOutgoing(peerId: widget.peerId, isVideo: isVideo)
              .ignore();
        }
      },
      invitees: [
        ZegoUIKitUser(
          id: CallService.zegoUserId(widget.peerId),
          name: widget.peerName,
        ),
      ],
      resourceID: 'zego_call',
      buttonSize: Size(40.r, 40.r),
      iconSize: Size(26.r, 26.r),
      icon: ButtonIcon(
        icon: Icon(
          isVideo ? Icons.videocam_outlined : Icons.call_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        backgroundColor: Colors.transparent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.watch<ChatController>();
    final presence = context.watch<PresenceProvider>();
    final myId = SupabaseService.currentUserId!;
    final (statusText, statusColor) = _peerStatus(c, presence, theme);

    // Only auto-scroll to the bottom on first load or a real append while the
    // user is near the bottom — never on a prepend (loadMore older history).
    final msgs = c.messages;
    final newLast = msgs.isEmpty ? null : msgs.last.messageId;
    final newFirst = msgs.isEmpty ? null : msgs.first.messageId;
    if (newLast != _lastId || newFirst != _firstId) {
      final firstLoad = _lastId == null && newLast != null;
      final appended =
          _lastId != null && newLast != _lastId && newFirst == _firstId;
      final nearBottom = !_scroll.hasClients ||
          (_scroll.position.maxScrollExtent - _scroll.position.pixels) < 150;
      _lastId = newLast;
      _firstId = newFirst;
      if (firstLoad || (appended && nearBottom)) _jumpToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            AppAvatar(
              name: widget.peerName,
              avatarUrl: widget.peerAvatarUrl,
              radius: 18.r,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.peerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Row(
                    children: [
                      Text(
                        statusText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (msgs.length > 20) ...[
                        SizedBox(width: 8.w),
                        Icon(Icons.local_fire_department, size: 14.r, color: Colors.orange),
                        Text(' 5', style: TextStyle(fontSize: 10.sp, color: Colors.orange, fontWeight: FontWeight.bold)),
                        SizedBox(width: 12.w),
                        _buildVibeIndicator(msgs),
                      ],
                    ],
                  ),
                  if (msgs.length > 5)
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Row(
                        children: [
                          Icon(Icons.favorite, size: 10.r, color: Colors.pinkAccent),
                          SizedBox(width: 4.w),
                          Container(
                            width: 60.w,
                            height: 4.h,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: (msgs.length / 100).clamp(0.1, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.pinkAccent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '${(msgs.length / 1).clamp(10, 99).toInt()}%',
                            style: TextStyle(fontSize: 8.sp, color: Colors.pinkAccent, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (CallService.enabled) ...[
            _callButton(isVideo: false),
            _callButton(isVideo: true),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.call_outlined),
              color: theme.colorScheme.primary,
              onPressed: () => _comingSoon('Voice call'),
            ),
            IconButton(
              icon: const Icon(Icons.videocam_outlined),
              color: theme.colorScheme.primary,
              onPressed: () => _comingSoon('Video call'),
            ),
          ],
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'block') {
                _blockPeer();
              } else if (v == 'media') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ConversationMediaPage(
                      conversationId: widget.conversationId,
                      peerName: widget.peerName,
                    ),
                  ),
                );
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                value: 'media',
                child: Row(
                  children: [
                    Icon(Icons.perm_media_outlined,
                        size: 20.r, color: theme.colorScheme.primary),
                    SizedBox(width: 10.w),
                    const Text('Media, links, and docs'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block,
                        size: 20.r, color: theme.colorScheme.error),
                    SizedBox(width: 10.w),
                    Text('Block @${widget.peerUsername}'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: WallpaperBackground(
                  child: _buildBody(context, c, myId),
                ),
              ),
              ChatInputBar(
                onSend: c.sendText,
                onTyping: c.setTyping,
                onPickImage: (file, {isSnap = false}) => c.sendImage(file, isSnap: isSnap),
                onSendVoice: c.sendVoice,
                replyToText: c.replyTo == null
                    ? null
                    : (c.replyTo!.deletedForEveryone
                        ? 'Deleted message'
                        : c.replyTo!.message),
                onCancelReply: c.clearReply,
              ),
              if (c.messages.isNotEmpty && !c.messages.last.isMine(myId) && !c.messages.last.isSnap)
                _buildSmartReplies(context, c),
              SizedBox(height: MediaQuery.of(context).padding.bottom > 0 ? 0 : 10.h),
            ],
          ),
          if (msgs.length > 10)
            ...List.generate(3, (index) => Positioned(
              bottom: 100.h + (index * 50.h),
              right: 20.w + (index * 40.w),
              child: Icon(Icons.favorite, color: Colors.pink.withValues(alpha: 0.3), size: 24.r)
                  .animate(onPlay: (controller) => controller.repeat())
                  .moveY(begin: 0, end: -400.h, duration: (3 + index).seconds, curve: Curves.easeInOut)
                  .fade(begin: 0, end: 0.6)
                  .then()
                  .fade(begin: 0.6, end: 0),
            )),
        ],
      ),
    );
  }

  Widget _buildSmartReplies(BuildContext context, ChatController c) {
    final lastMsg = c.messages.last.message.toLowerCase();
    List<String> suggestions = ["Hey!", "How's it going?", "Love it! ❤️"];
    
    if (lastMsg.contains("hi") || lastMsg.contains("hello")) {
      suggestions = ["Hello!", "Hey there!", "Hi! What's up?"];
    } else if (lastMsg.contains("how are you")) {
      suggestions = ["I'm good, you?", "Doing great!", "Awesome!"];
    } else if (lastMsg.contains("photo") || lastMsg.contains("pic")) {
      suggestions = ["Nice pic!", "Looking good!", "Cool! 🔥"];
    }

    return Container(
      height: 40.h,
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        itemCount: suggestions.length,
        itemBuilder: (ctx, i) => Padding(
          padding: EdgeInsets.only(right: 8.w),
          child: ActionChip(
            label: Text(suggestions[i], style: TextStyle(fontSize: 12.sp)),
            onPressed: () => c.sendText(suggestions[i]),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          ),
        ),
      ),
    );
  }

  Widget _buildVibeIndicator(List<Message> msgs) {
    // Advanced AI Mock: Analyze last 10 messages for sentiment
    String vibeEmoji = "😊";
    String vibeText = "Sweet";
    
    final lastMsgs = msgs.take(10).map((m) => m.message.toLowerCase()).join(" ");
    if (lastMsgs.contains("love") || lastMsgs.contains("❤️")) {
      vibeEmoji = "💖"; vibeText = "Romantic";
    } else if (lastMsgs.contains("haha") || lastMsgs.contains("😂")) {
      vibeEmoji = "😂"; vibeText = "Funny";
    } else if (lastMsgs.contains("?") || lastMsgs.contains("how")) {
      vibeEmoji = "🧐"; vibeText = "Curious";
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Text(vibeEmoji, style: TextStyle(fontSize: 10.sp)),
          SizedBox(width: 4.w),
          Text(vibeText, style: TextStyle(fontSize: 8.sp, color: Colors.white70, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  (String, Color) _peerStatus(
    ChatController c,
    PresenceProvider presence,
    ThemeData theme,
  ) {
    final subtle = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    if (c.peerTyping) return ('typing… ❤️', theme.colorScheme.primary);
    if (presence.isOnline(widget.peerId)) return ('online 💗', AppColors.online);
    if (_peerLastSeen != null) {
      return ('last seen ${ChatTime.listLabel(_peerLastSeen!)}', subtle);
    }
    return ('@${widget.peerUsername}', subtle);
  }

  Widget _buildBody(BuildContext context, ChatController c, String myId) {
    final theme = Theme.of(context);
    if (c.loading) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }
    if (c.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('👋', style: TextStyle(fontSize: 44.sp)),
            SizedBox(height: 10.h),
            Text(
              'Say hi to ${widget.peerName}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    final items = _buildItems(c.messages);
    return ListView.builder(
      controller: _scroll,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: items.length +
          (c.loadingMore ? 1 : 0) +
          (c.peerTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (c.loadingMore && index == 0) {
          return Padding(
            padding: EdgeInsets.all(8.h),
            child: Center(
              child: SizedBox(
                width: 18.r,
                height: 18.r,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (c.peerTyping &&
            index == items.length + (c.loadingMore ? 1 : 0)) {
          return const TypingIndicator();
        }
        final item = items[index - (c.loadingMore ? 1 : 0)];
        if (item is _DateItem) return ChatDateChip(label: item.label);
        final msg = (item as _MsgItem).message;
        Message? replied;
        final replyId = msg.replyMessageId;
        if (replyId != null) {
          final ri = c.messages.indexWhere((m) => m.messageId == replyId);
          if (ri >= 0) replied = c.messages[ri];
        }
        return MessageBubble(
          message: msg,
          myId: myId,
          repliedMessage: replied,
          reactions: c.reactionsFor(msg.messageId),
          onRetry: () => c.retry(msg),
          onSwipeReply: () => c.setReply(msg),
          onLongPress: () => showMessageActions(
            context,
            message: msg,
            controller: c,
            myId: myId,
          ),
        );
      },
    );
  }

  List<_Item> _buildItems(List<Message> messages) {
    final items = <_Item>[];
    DateTime? lastDay;
    for (final m in messages) {
      if (lastDay == null || !ChatTime.sameDay(lastDay, m.createdAt)) {
        items.add(_DateItem(ChatTime.dayHeader(m.createdAt)));
        lastDay = m.createdAt;
      }
      items.add(_MsgItem(m));
    }
    return items;
  }
}

sealed class _Item {}

class _DateItem extends _Item {
  _DateItem(this.label);
  final String label;
}

class _MsgItem extends _Item {
  _MsgItem(this.message);
  final Message message;
}
