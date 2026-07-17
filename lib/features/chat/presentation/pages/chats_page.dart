import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../ai/presentation/pages/ai_chat_page.dart';
import '../../../calls/presentation/pages/calls_page.dart';
import '../../../contacts/presentation/pages/discovery_page.dart';
import 'lounge_list_page.dart';
import '../../../games/presentation/widgets/games_fab.dart';
import '../../../contacts/presentation/pages/new_chat_page.dart';
import '../../../contacts/presentation/pages/requests_page.dart';
import '../../../notifications/presentation/widgets/notifications_bell.dart';
import '../../data/models/conversation.dart';
import '../../data/providers/conversation_list_provider.dart';
import '../widgets/conversation_tile.dart';
import '../widgets/notes_bar.dart';
import 'chat_thread_screen.dart';
import 'archived_chats_page.dart';

/// Chats tab — header, search, stories row, and the live conversation list.
class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  String _query = '';

  List<Conversation> _filter(List<Conversation> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((c) =>
            c.peerName.toLowerCase().contains(q) ||
            c.peerUsername.toLowerCase().contains(q))
        .toList();
  }

  void _openNewChat() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NewChatPage()),
    );
  }

  void _open(Conversation c) {
    openChat(
      context,
      conversationId: c.id,
      peerId: c.peerId,
      peerName: c.peerName,
      peerUsername: c.peerUsername,
      peerAvatarUrl: c.peerAvatarUrl,
    );
  }

  Future<void> _showOptions(Conversation c) async {
    final theme = Theme.of(context);
    final provider = context.read<ConversationListProvider>();
    
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.archive_outlined),
            title: const Text('Archive chat'),
            onTap: () {
              provider.archiveConversation(c.id, true);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Chat with ${c.peerName} archived')),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            title: Text('Delete chat', style: TextStyle(color: theme.colorScheme.error)),
            onTap: () {
              Navigator.pop(ctx);
              _confirmDelete(c);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Conversation c) async {
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete chat?'),
        content: Text('Permanently delete this chat with ${c.peerName} and all '
            'its messages & media — for both of you. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<ConversationListProvider>().deleteConversation(c.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ConversationListProvider>();
    final conversations = _filter(provider.items);

    return Stack(
      children: [
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 12.w, 4.h),
                child: Row(
                  children: [
                    Text(
                      'Chats',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.forum_outlined,
                          color: theme.colorScheme.primary),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoungeListPage()),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.explore_outlined,
                          color: theme.colorScheme.primary),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DiscoveryPage()),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.auto_awesome,
                          color: theme.colorScheme.primary),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AIChatPage()),
                      ),
                    ),
                    const NotificationsBell(),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert,
                          color: theme.colorScheme.onSurface),
                      onSelected: (v) {
                        if (v == 'new') {
                          _openNewChat();
                        } else if (v == 'requests') {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const RequestsPage()));
                        } else if (v == 'calls') {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const Scaffold(body: CallsPage())));
                        } else if (v == 'archived') {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const ArchivedChatsPage()));
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'new',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.edit_square),
                            title: Text('New chat'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'calls',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.call_outlined),
                            title: Text('Calls'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'requests',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.group_add_outlined),
                            title: Text('Friend requests'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'archived',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.archive_outlined),
                            title: Text('Archived chats'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 8.h),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    prefixIcon: Icon(Icons.search, size: 22),
                  ),
                ),
              ),
              const NotesBar(),
              SizedBox(height: 4.h),
              Expanded(child: _buildList(context, provider, conversations)),
            ],
          ),
        ),
        const GamesFab(),
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    ConversationListProvider provider,
    List<Conversation> conversations,
  ) {
    final theme = Theme.of(context);
    if (provider.loading) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }
    if (provider.items.isEmpty) {
      return const EmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'No chats yet',
        subtitle: 'Tap the pencil or + to find a friend and say hi 💗',
      );
    }
    if (conversations.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matches',
        subtitle: 'No conversation matches your search.',
      );
    }
    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (context, i) {
          final c = conversations[i];
          return ConversationTile(
            conversation: c,
            onTap: () => _open(c),
            onLongPress: () => _showOptions(c),
          );
        },
      ),
    );
  }
}

