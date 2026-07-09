import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../contacts/data/repositories/contacts_repository.dart';
import '../../../profile/data/models/profile.dart';

/// Privacy → Blocked contacts: list of users you've blocked, each with Unblock.
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final _repo = ContactsRepository(SupabaseService.client);
  List<Profile> _blocked = [];
  bool _loading = true;
  final _busy = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _repo.blockedUsers();
      if (mounted) {
        setState(() {
          _blocked = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unblock(Profile u) async {
    setState(() => _busy.add(u.id));
    try {
      await _repo.unblockUser(u.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not unblock. Try again.')),
        );
      }
    }
    if (!mounted) return;
    _busy.remove(u.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked contacts')),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : _blocked.isEmpty
              ? const EmptyState(
                  icon: Icons.block,
                  title: 'No blocked contacts',
                  subtitle:
                      'People you block from a chat appear here. Unblock anytime.',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    itemCount: _blocked.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, indent: 76.w, endIndent: 16.w),
                    itemBuilder: (context, i) {
                      final u = _blocked[i];
                      final busy = _busy.contains(u.id);
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 4.h),
                        leading: AppAvatar(
                            name: u.displayName,
                            avatarUrl: u.avatarUrl,
                            radius: 26.r),
                        title: Text(u.displayName,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        subtitle: Text('@${u.username}'),
                        trailing: busy
                            ? SizedBox(
                                width: 22.r,
                                height: 22.r,
                                child: const CircularProgressIndicator(
                                    strokeWidth: 2))
                            : OutlinedButton(
                                onPressed: () => _unblock(u),
                                child: const Text('Unblock'),
                              ),
                      );
                    },
                  ),
                ),
    );
  }
}
