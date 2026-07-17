import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../data/models/conversation.dart';
import '../../data/providers/conversation_list_provider.dart';
import '../widgets/conversation_tile.dart';
import 'chat_thread_screen.dart';

class ArchivedChatsPage extends StatelessWidget {
  const ArchivedChatsPage({super.key});

  void _open(BuildContext context, Conversation c) {
    openChat(
      context,
      conversationId: c.id,
      peerId: c.peerId,
      peerName: c.peerName,
      peerUsername: c.peerUsername,
      peerAvatarUrl: c.peerAvatarUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConversationListProvider>();
    final conversations = provider.archivedItems;

    return Scaffold(
      appBar: AppBar(title: const Text('Archived Chats')),
      body: conversations.isEmpty
          ? const EmptyState(
              icon: Icons.archive_outlined,
              title: 'No archived chats',
              subtitle: 'Archived chats stay hidden until you receive a new message.',
            )
          : ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, i) {
                final c = conversations[i];
                return ConversationTile(
                  conversation: c,
                  onTap: () => _open(context, c),
                  onLongPress: () => _showOptions(context, provider, c),
                );
              },
            ),
    );
  }

  void _showOptions(BuildContext context, ConversationListProvider provider, Conversation c) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.unarchive_outlined),
            title: const Text('Unarchive chat'),
            onTap: () {
              provider.archiveConversation(c.id, false);
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete chat', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(ctx);
              _confirmDelete(context, provider, c);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ConversationListProvider provider, Conversation c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete chat?'),
        content: Text('Delete this chat with ${c.peerName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) provider.deleteConversation(c.id);
  }
}
