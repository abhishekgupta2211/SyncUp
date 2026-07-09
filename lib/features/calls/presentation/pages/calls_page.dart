import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/utils/chat_time.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/models/call_log.dart';
import '../../data/repositories/call_log_repository.dart';

/// Calls tab — recent voice/video call history (All / Missed) from call_logs.
class CallsPage extends StatefulWidget {
  const CallsPage({super.key});

  @override
  State<CallsPage> createState() => _CallsPageState();
}

class _CallsPageState extends State<CallsPage> {
  final _repo = CallLogRepository(SupabaseService.client);
  List<CallLog> _logs = [];
  bool _loading = true;
  int _filter = 0;
  static const _filters = ['All', 'Missed'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final logs = await _repo.fetchLogs();
      if (mounted) {
        setState(() {
          _logs = logs;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<CallLog> get _filtered =>
      _filter == 1 ? _logs.where((l) => l.missed).toList() : _logs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 8.h),
            child: Text(
              'Calls',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
            child: Row(
              children: List.generate(_filters.length, (i) {
                final selected = i == _filter;
                return Padding(
                  padding: EdgeInsets.only(right: 10.w),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding:
                          EdgeInsets.symmetric(horizontal: 18.w, vertical: 9.h),
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      child: Text(
                        _filters[i],
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: selected
                              ? Colors.white
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(child: _body(theme)),
        ],
      ),
    );
  }

  Widget _body(ThemeData theme) {
    if (_loading) {
      return Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary));
    }
    final list = _filtered;
    if (list.isEmpty) {
      return EmptyState(
        icon: _filter == 1 ? Icons.call_missed : Icons.call_outlined,
        title: _filter == 1 ? 'No missed calls' : 'No calls yet',
        subtitle: 'Your voice and video calls will show up here.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        itemCount: list.length,
        separatorBuilder: (_, _) =>
            Divider(height: 1, indent: 76.w, endIndent: 16.w),
        itemBuilder: (context, i) => _tile(theme, list[i]),
      ),
    );
  }

  Widget _tile(ThemeData theme, CallLog l) {
    final (dirIcon, dirColor, dirLabel) = l.missed
        ? (Icons.call_missed, theme.colorScheme.error, 'Missed')
        : l.outgoing
            ? (Icons.call_made, theme.colorScheme.primary, 'Outgoing')
            : (Icons.call_received, const Color(0xFF22C55E), 'Incoming');

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      leading:
          AppAvatar(name: l.peerName, avatarUrl: l.peerAvatarUrl, radius: 26.r),
      title: Text(
        l.peerName,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: l.missed ? theme.colorScheme.error : null,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(dirIcon, size: 15.r, color: dirColor),
          SizedBox(width: 4.w),
          Text('$dirLabel · ${ChatTime.listLabel(l.startedAt)}'),
        ],
      ),
      trailing: Icon(
        l.isVideo ? Icons.videocam_outlined : Icons.call_outlined,
        color: theme.colorScheme.primary,
        size: 22.r,
      ),
    );
  }
}
