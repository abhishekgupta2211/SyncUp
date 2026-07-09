import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../chat/presentation/pages/chat_thread_screen.dart';
import '../../../profile/data/models/profile.dart';
import '../../data/providers/contacts_provider.dart';

/// Search field + results list. Each row is relationship-aware: you can only
/// open a chat once you are friends — otherwise you send / accept a request.
class UserSearchView extends StatefulWidget {
  const UserSearchView({super.key, this.autofocus = false});

  final bool autofocus;

  @override
  State<UserSearchView> createState() => _UserSearchViewState();
}

class _UserSearchViewState extends State<UserSearchView> {
  bool _opening = false;

  Future<void> _open(Profile user) async {
    if (_opening) return;
    setState(() => _opening = true);
    final contacts = context.read<ContactsProvider>();
    final convId = await contacts.startChat(user.id);
    if (!mounted) return;
    setState(() => _opening = false);
    if (convId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(contacts.error ?? 'Could not open chat')),
      );
      return;
    }
    await openChat(
      context,
      conversationId: convId,
      peerId: user.id,
      peerName: user.displayName,
      peerUsername: user.username,
      peerAvatarUrl: user.avatarUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final contacts = context.watch<ContactsProvider>();
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 8.h),
          child: TextField(
            autofocus: widget.autofocus,
            onChanged: contacts.onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search by name or @username',
              prefixIcon: Icon(Icons.search, size: 22),
            ),
          ),
        ),
        Expanded(child: _buildResults(context, contacts)),
        if (_opening) const LinearProgressIndicator(minHeight: 2),
      ],
    );
  }

  Widget _buildResults(BuildContext context, ContactsProvider contacts) {
    final theme = Theme.of(context);
    if (!contacts.hasQuery) {
      return const EmptyState(
        icon: Icons.person_search_outlined,
        title: 'Find people',
        subtitle: 'Search a user, send a friend request, then start chatting.',
      );
    }
    if (contacts.loading) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }
    if (contacts.error != null) {
      return EmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Something went wrong',
        subtitle: contacts.error,
      );
    }
    if (contacts.results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No users found',
        subtitle: 'Try a different name or @username.',
      );
    }
    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      itemCount: contacts.results.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, indent: 76.w, endIndent: 16.w),
      itemBuilder: (context, i) {
        final u = contacts.results[i];
        return _UserResultTile(
          key: ValueKey(u.id),
          user: u,
          onOpenChat: () => _open(u),
        );
      },
    );
  }
}

/// One search result with its own relationship state + action button.
class _UserResultTile extends StatefulWidget {
  const _UserResultTile({
    super.key,
    required this.user,
    required this.onOpenChat,
  });

  final Profile user;
  final VoidCallback onOpenChat;

  @override
  State<_UserResultTile> createState() => _UserResultTileState();
}

class _UserResultTileState extends State<_UserResultTile> {
  String? _rel; // none | pending_out | pending_in | friends | blocked
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadRelationship();
  }

  Future<void> _loadRelationship() async {
    final rel = await context.read<ContactsProvider>().relationship(widget.user.id);
    if (mounted) setState(() => _rel = rel);
  }

  Future<void> _act(Future<void> Function(ContactsProvider c) action,
      String nextRel) async {
    setState(() => _busy = true);
    try {
      await action(context.read<ContactsProvider>());
      if (mounted) setState(() => _rel = nextRel);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final u = widget.user;
    return ListTile(
      onTap: _rel == 'friends' ? widget.onOpenChat : null,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      leading: AppAvatar(name: u.displayName, avatarUrl: u.avatarUrl, radius: 26.r),
      title: Text(
        u.displayName,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('@${u.username}'),
      trailing: _trailing(theme),
    );
  }

  Widget _trailing(ThemeData theme) {
    if (_busy || _rel == null) {
      return SizedBox(
        width: 22.r,
        height: 22.r,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }
    switch (_rel) {
      case 'friends':
        return _iconAction(
          theme,
          icon: Icons.chat_bubble_outline,
          onTap: widget.onOpenChat,
        );
      case 'pending_in':
        return FilledButton(
          onPressed: () =>
              _act((c) => c.acceptRequest(widget.user.id), 'friends'),
          child: const Text('Accept'),
        );
      case 'pending_out':
        return OutlinedButton(
          onPressed: () =>
              _act((c) => c.removeFriendship(widget.user.id), 'none'),
          child: const Text('Requested'),
        );
      case 'blocked':
        return TextButton(
          onPressed: () =>
              _act((c) => c.unblockUser(widget.user.id), 'none'),
          child: Text('Unblock',
              style: TextStyle(color: theme.colorScheme.error)),
        );
      default: // none
        return FilledButton.tonalIcon(
          onPressed: () =>
              _act((c) => c.sendRequest(widget.user.id), 'pending_out'),
          icon: Icon(Icons.person_add_alt_1, size: 18.r),
          label: const Text('Add'),
        );
    }
  }

  Widget _iconAction(ThemeData theme,
      {required IconData icon, required VoidCallback onTap}) {
    return IconButton(
      onPressed: onTap,
      icon: Container(
        width: 38.r,
        height: 38.r,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, size: 18.r, color: theme.colorScheme.primary),
      ),
    );
  }
}
