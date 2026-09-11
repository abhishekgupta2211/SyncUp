import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_refs.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../models/conversation.dart';

/// App-lifetime (per login) home chat list. Loads my conversations with the
/// peer denormalized, then keeps them live via realtime.
class ConversationListProvider extends ChangeNotifier {
  ConversationListProvider() {
    start();
  }

  final SupabaseClient _client = SupabaseService.client;
  List<Conversation> _items = [];
  bool _loading = true;
  String? _error;
  RealtimeChannel? _convChannel;
  RealtimeChannel? _partChannel;
  RealtimeChannel? _blockChannel;

  List<Conversation> get items => List.unmodifiable(_items.where((c) => !c.isArchived));
  List<Conversation> get archivedItems => List.unmodifiable(_items.where((c) => c.isArchived));
  bool get loading => _loading;
  String? get error => _error;

  String? get _myId => SupabaseService.currentUserId;

  Future<void> archiveConversation(String conversationId, bool archive) async {
    final idx = _items.indexWhere((c) => c.id == conversationId);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(isArchived: archive);
      notifyListeners();
    }
    try {
      await _client
          .from(Tables.participants)
          .update({'is_archived': archive})
          .eq('conversation_id', conversationId)
          .eq('user_id', _myId!);
    } catch (e) {
      debugPrint('[home.archiveConversation] FAILED: $e');
      await load();
    }
  }

  Future<void> start() async {
    await load();
    _subscribe();
  }

  Future<void> load() async {
    final me = _myId;
    if (me == null) {
      _loading = false;
      notifyListeners();
      return;
    }
    try {
      // A) my participant rows + the conversation data
      final parts = await _client
          .from(Tables.participants)
          .select(
              'conversation_id, unread_count, is_archived, conversations(id, last_message_text, last_message_type, last_message_at, created_at)')
          .eq('user_id', me);

      final partList = (parts as List).cast<Map<String, dynamic>>();
      final convIds =
          partList.map((p) => p['conversation_id'] as String).toList();

      if (convIds.isEmpty) {
        _items = [];
        _loading = false;
        _error = null;
        notifyListeners();
        return;
      }

      // B) the OTHER participant's profile for each conversation
      final peers = await _client
          .from(Tables.participants)
          .select('conversation_id, profiles(id, username, display_name, avatar_url)')
          .inFilter('conversation_id', convIds)
          .neq('user_id', me);

      final peerByConv = <String, Map<String, dynamic>>{};
      for (final r in (peers as List).cast<Map<String, dynamic>>()) {
        final p = r['profiles'];
        if (p != null) {
          peerByConv[r['conversation_id'] as String] =
              (p as Map).cast<String, dynamic>();
        }
      }

      // users I've blocked → hide their chats from the list
      final blockedRows = await _client
          .from(Tables.userBlocks)
          .select('blocked_id')
          .eq('blocker_id', me);
      final blocked =
          (blockedRows as List).map((r) => r['blocked_id'] as String).toSet();

      final list = <Conversation>[];
      for (final p in partList) {
        final conv = p['conversations'] as Map<String, dynamic>?;
        final peer = peerByConv[p['conversation_id']];
        if (conv == null || peer == null) continue;
        if (blocked.contains(peer['id'])) continue;
        
        final lastAt = conv['last_message_at'] ?? conv['created_at'];
        
        list.add(Conversation(
          id: conv['id'] as String,
          peerId: peer['id'] as String,
          peerName: (peer['display_name'] ?? '') as String,
          peerUsername: (peer['username'] ?? '') as String,
          peerAvatarUrl: peer['avatar_url'] as String?,
          lastMessageText: conv['last_message_text'] ?? 'New friend! 👋',
          lastMessageType: conv['last_message_type'] as String?,
          lastMessageAt: lastAt == null ? null : DateTime.parse(lastAt.toString()).toLocal(),
          unreadCount: (p['unread_count'] ?? 0) as int,
          isArchived: (p['is_archived'] ?? false) as bool,
        ));
      }
      _sort(list);
      _items = list;
      _error = null;
    } catch (_) {
      _error = 'Could not load chats';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// "Delete chat" — HARD delete. Removes the conversation, all messages,
  /// reactions and media (storage) for BOTH users, freeing storage.
  Future<void> deleteConversation(String conversationId) async {
    _items.removeWhere((c) => c.id == conversationId);
    notifyListeners();
    try {
      await _client.rpc(
        Rpcs.deleteConversation,
        params: {'p_conversation_id': conversationId},
      );
    } catch (e) {
      debugPrint('[home.deleteConversation] FAILED: $e');
      await load(); // reconcile if it failed
    }
  }

  void _subscribe() {
    final me = _myId;
    if (me == null) return;

    _convChannel = _client.channel('home-conv:$me')
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: Tables.conversations,
        callback: (p) => _onConvUpdate(p.newRecord),
      )
      ..subscribe();

    _partChannel = _client.channel('home-part:$me')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: Tables.participants,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: me,
        ),
        callback: _onPartChange,
      )
      ..subscribe();

    _blockChannel = _client.channel('home-block:$me')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: Tables.userBlocks,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'blocker_id',
          value: me,
        ),
        callback: (_) => load(),
      )
      ..subscribe();
  }

  void _onConvUpdate(Map<String, dynamic> row) {
    final id = row['id'] as String?;
    if (id == null) return;
    final idx = _items.indexWhere((c) => c.id == id);
    final lastAt = row['last_message_at'];
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(
        lastMessageText: (row['last_message_text'] ?? '') as String,
        lastMessageType: row['last_message_type'] as String?,
        lastMessageAt: lastAt == null
            ? _items[idx].lastMessageAt
            : DateTime.parse(lastAt.toString()).toLocal(),
      );
      _sort(_items);
      notifyListeners();
    } else if (lastAt != null) {
      // a conversation just got its first message → bring it into the list
      load();
    }
  }

  void _onPartChange(PostgresChangePayload payload) {
    if (payload.eventType == PostgresChangeEvent.insert) {
      load(); // a brand-new conversation I'm now part of
      return;
    }
    if (payload.eventType == PostgresChangeEvent.delete) {
      final id = payload.oldRecord['conversation_id'] as String?;
      if (id != null) {
        _items.removeWhere((c) => c.id == id);
        notifyListeners();
      }
      return;
    }
    final row = payload.newRecord;
    final id = row['conversation_id'] as String?;
    if (id == null) return;
    final idx = _items.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      _items[idx] =
          _items[idx].copyWith(unreadCount: (row['unread_count'] ?? 0) as int);
      notifyListeners();
    }
  }

  void _sort(List<Conversation> list) {
    list.sort((a, b) => (b.lastMessageAt ?? DateTime(0))
        .compareTo(a.lastMessageAt ?? DateTime(0)));
  }

  @override
  void dispose() {
    final cc = _convChannel;
    final pc = _partChannel;
    final bc = _blockChannel;
    if (cc != null) _client.removeChannel(cc);
    if (pc != null) _client.removeChannel(pc);
    if (bc != null) _client.removeChannel(bc);
    super.dispose();
  }
}
