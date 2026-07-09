import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_refs.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../models/app_notification.dart';

/// Reads + mutates the current user's notifications.
class NotificationRepository {
  NotificationRepository(this._client);

  final SupabaseClient _client;

  String get _me => SupabaseService.currentUserId!;

  Future<List<AppNotification>> fetch() async {
    final rows = await _client
        .from(Tables.notifications)
        .select(
            '*, actor:profiles!notifications_actor_id_fkey(display_name, avatar_url)')
        .eq('user_id', _me)
        .order('created_at', ascending: false)
        .limit(60);
    return (rows as List)
        .map((e) => AppNotification.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(String id) =>
      _client.from(Tables.notifications).update({'read': true}).eq('id', id);

  Future<void> markAllRead() => _client
      .from(Tables.notifications)
      .update({'read': true})
      .eq('user_id', _me)
      .eq('read', false);

  Future<void> remove(String id) =>
      _client.from(Tables.notifications).delete().eq('id', id);

  Future<void> clearAll() =>
      _client.from(Tables.notifications).delete().eq('user_id', _me);

  RealtimeChannel subscribe(void Function() onChange) {
    final channel = _client.channel('notif:$_me')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: Tables.notifications,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: _me,
        ),
        callback: (_) => onChange(),
      )
      ..subscribe();
    return channel;
  }

  Future<void> removeChannel(RealtimeChannel channel) =>
      _client.removeChannel(channel);
}
