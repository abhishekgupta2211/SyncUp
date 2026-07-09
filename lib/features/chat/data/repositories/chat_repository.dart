import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_refs.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../models/message.dart';
import '../models/reaction.dart';

/// Data access for a single conversation: message paging, send, mark-read, and
/// the realtime subscription.
class ChatRepository {
  ChatRepository(this._client);

  final SupabaseClient _client;

  static const pageSize = 30;

  /// Newest [pageSize] messages (or older than [before] for pagination).
  Future<List<Message>> fetchMessages(
    String conversationId, {
    DateTime? before,
  }) async {
    var query = _client
        .from(Tables.messages)
        .select()
        .eq('conversation_id', conversationId);

    if (before != null) {
      query = query.lt('created_at', before.toUtc().toIso8601String());
    }

    final rows = await query
        .order('created_at', ascending: false)
        .limit(pageSize);

    return (rows as List)
        .map((e) => Message.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<Message> sendText({
    required String messageId,
    required String conversationId,
    required String receiverId,
    required String text,
    String? replyMessageId,
  }) async {
    final row = await _client
        .from(Tables.messages)
        .insert({
          'id': messageId,
          'conversation_id': conversationId,
          'sender_id': SupabaseService.currentUserId,
          'receiver_id': receiverId,
          'message_type': 'text',
          'message': text,
          'reply_message_id': replyMessageId,
        })
        .select()
        .single();
    return Message.fromMap(row);
  }

  Future<Message> sendMedia({
    required String messageId,
    required String conversationId,
    required String receiverId,
    required String messageType,
    required String mediaUrl,
    String caption = '',
    String? replyMessageId,
    bool isSnap = false, // NEW
  }) async {
    final row = await _client
        .from(Tables.messages)
        .insert({
          'id': messageId,
          'conversation_id': conversationId,
          'sender_id': SupabaseService.currentUserId,
          'receiver_id': receiverId,
          'message_type': messageType,
          'message': caption,
          'media_url': mediaUrl,
          'reply_message_id': replyMessageId,
          'is_snap': isSnap, // NEW
        })
        .select()
        .single();
    return Message.fromMap(row);
  }

  Future<List<Message>> fetchMedia(String conversationId) async {
    final rows = await _client
        .from(Tables.messages)
        .select()
        .eq('conversation_id', conversationId)
        .inFilter('message_type', ['image', 'video'])
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => Message.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Message>> searchMessages(String conversationId, String query) async {
    final rows = await _client
        .from(Tables.messages)
        .select()
        .eq('conversation_id', conversationId)
        .eq('message_type', 'text')
        .ilike('message', '%$query%')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => Message.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Deletes (leaves) the conversation for the current user only — removes my
  /// participant row so it disappears from my list. The peer keeps the chat.
  Future<void> deleteConversationForMe(String conversationId) async {
    await _client
        .from(Tables.participants)
        .delete()
        .eq('conversation_id', conversationId)
        .eq('user_id', SupabaseService.currentUserId!);
  }

  Future<void> markRead(String conversationId) async {
    await _client.rpc(
      Rpcs.markConversationRead,
      params: {'p_conversation_id': conversationId},
    );
  }

  Future<void> deleteForEveryone(String messageId) async {
    // SECURITY DEFINER RPC — reliably persists the flag for the sender's own
    // message (the direct UPDATE path was being silently rejected).
    await _client.rpc(
      Rpcs.deleteMessageForEveryone,
      params: {'p_message_id': messageId},
    );
  }

  Future<void> deleteForMe(String messageId) async {
    await _client.rpc(
      Rpcs.hideMessageForMe,
      params: {'p_message_id': messageId},
    );
  }

  // ---- reactions ----
  Future<List<Reaction>> fetchReactions(List<String> messageIds) async {
    if (messageIds.isEmpty) return [];
    final rows = await _client
        .from(Tables.reactions)
        .select()
        .inFilter('message_id', messageIds);
    return (rows as List)
        .map((e) => Reaction.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> setReaction(String messageId, String emoji) async {
    await _client.from(Tables.reactions).upsert({
      'message_id': messageId,
      'user_id': SupabaseService.currentUserId,
      'emoji': emoji,
    }, onConflict: 'message_id,user_id');
  }

  Future<void> clearReaction(String messageId) async {
    await _client
        .from(Tables.reactions)
        .delete()
        .eq('message_id', messageId)
        .eq('user_id', SupabaseService.currentUserId!);
  }

  RealtimeChannel subscribeReactions(
    String conversationId, {
    required void Function() onChange,
  }) {
    final channel = _client.channel('reactions:$conversationId');
    channel
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: Tables.reactions,
        callback: (_) => onChange(),
      )
      ..subscribe();
    return channel;
  }

  /// Subscribes to inserts & updates for a conversation's messages.
  RealtimeChannel subscribe(
    String conversationId, {
    required void Function(Message) onInsert,
    required void Function(Message) onUpdate,
  }) {
    final channel = _client.channel('messages:$conversationId');
    channel
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: Tables.messages,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'conversation_id',
          value: conversationId,
        ),
        callback: (payload) => onInsert(Message.fromMap(payload.newRecord)),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: Tables.messages,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'conversation_id',
          value: conversationId,
        ),
        callback: (payload) => onUpdate(Message.fromMap(payload.newRecord)),
      )
      ..subscribe();
    return channel;
  }

  Future<void> removeChannel(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}
