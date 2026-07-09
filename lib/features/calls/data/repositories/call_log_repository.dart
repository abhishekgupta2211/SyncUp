import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_refs.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../models/call_log.dart';

/// Reads + writes the `call_logs` table. The CALLER records the call; RLS then
/// lets both parties see it (caller as outgoing, callee as incoming — the
/// direction is derived per-viewer in [fetchLogs]).
class CallLogRepository {
  CallLogRepository(this._client);

  final SupabaseClient _client;

  String get _me => SupabaseService.currentUserId!;

  /// Records an outgoing call to [peerId] (voice or video).
  Future<void> logOutgoing({
    required String peerId,
    required bool isVideo,
  }) async {
    await _client.from(Tables.callLogs).insert({
      'caller_id': _me,
      'callee_id': peerId,
      'type': isVideo ? 'video' : 'voice',
      'direction': 'outgoing',
    });
  }

  /// The current user's call history (both placed and received).
  Future<List<CallLog>> fetchLogs() async {
    final me = _me;
    final rows = await _client
        .from(Tables.callLogs)
        .select(
            '*, caller:profiles!call_logs_caller_id_fkey(id, display_name, avatar_url), '
            'callee:profiles!call_logs_callee_id_fkey(id, display_name, avatar_url)')
        .or('caller_id.eq.$me,callee_id.eq.$me')
        .order('started_at', ascending: false)
        .limit(50);

    return (rows as List).cast<Map<String, dynamic>>().map((r) {
      final outgoing = r['caller_id'] == me;
      final peer =
          (outgoing ? r['callee'] : r['caller']) as Map<String, dynamic>?;
      return CallLog(
        id: r['id'] as String,
        peerId: (peer?['id'] ?? '') as String,
        peerName: (peer?['display_name'] ?? 'User') as String,
        peerAvatarUrl: peer?['avatar_url'] as String?,
        type: (r['type'] ?? 'voice') as String,
        outgoing: outgoing,
        missed: r['direction'] == 'missed',
        startedAt: DateTime.parse(r['started_at'].toString()).toLocal(),
      );
    }).toList();
  }
}
