import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../profile/data/models/profile.dart';
import '../../data/repositories/contacts_repository.dart';

/// Friend requests: incoming (Accept / Reject) and outgoing (Cancel).
class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  final _repo = ContactsRepository(SupabaseService.client);

  List<Profile> _incoming = [];
  List<Profile> _outgoing = [];
  bool _loading = true;
  final _busy = <String>{}; // ids with an in-flight action

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _repo.incomingRequests(),
        _repo.outgoingRequests(),
      ]);
      if (!mounted) return;
      setState(() {
        _incoming = results[0];
        _outgoing = results[1];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(String id, Future<void> Function() action) async {
    setState(() => _busy.add(id));
    try {
      await action();
    } catch (_) {
      _toast('Something went wrong. Try again.');
    }
    if (!mounted) return;
    _busy.remove(id);
    await _load();
  }

  void _toast(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Friend Requests')),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : (_incoming.isEmpty && _outgoing.isEmpty)
              ? const EmptyState(
                  icon: Icons.group_add_outlined,
                  title: 'No requests',
                  subtitle:
                      'Friend requests you send and receive will appear here.',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: EdgeInsets.only(bottom: 24.h),
                    children: [
                      if (_incoming.isNotEmpty) ...[
                        _sectionLabel('Received'),
                        ..._incoming.map((u) => _tile(u, incoming: true)),
                      ],
                      if (_outgoing.isNotEmpty) ...[
                        _sectionLabel('Sent'),
                        ..._outgoing.map((u) => _tile(u, incoming: false)),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _sectionLabel(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 6.h),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _tile(Profile u, {required bool incoming}) {
    final theme = Theme.of(context);
    final busy = _busy.contains(u.id);
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      leading: AppAvatar(name: u.displayName, avatarUrl: u.avatarUrl, radius: 26.r),
      title: Text(u.displayName,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text('@${u.username}'),
      trailing: busy
          ? SizedBox(
              width: 22.r,
              height: 22.r,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : incoming
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: theme.colorScheme.error),
                      tooltip: 'Reject',
                      onPressed: () =>
                          _run(u.id, () => _repo.removeFriendship(u.id)),
                    ),
                    FilledButton(
                      onPressed: () =>
                          _run(u.id, () => _repo.acceptRequest(u.id)),
                      child: const Text('Accept'),
                    ),
                  ],
                )
              : OutlinedButton(
                  onPressed: () =>
                      _run(u.id, () => _repo.removeFriendship(u.id)),
                  child: const Text('Cancel'),
                ),
    );
  }
}
