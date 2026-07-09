import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_refs.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../profile/data/models/profile.dart';

/// User directory search + 1:1 conversation creation.
class ContactsRepository {
  ContactsRepository(this._client);

  final SupabaseClient _client;

  Future<List<Profile>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final res = await _client.rpc(
      Rpcs.searchUsers,
      params: {'q': q, 'page_size': 30},
    );
    return (res as List)
        .map((e) => Profile.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Profile>> getSuggestedUsers({int limit = 10}) async {
    final res = await _client.rpc(
      'get_suggested_users',
      params: {'limit_count': limit},
    );
    return (res as List)
        .map((e) => Profile.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns the conversation id for the 1:1 chat with [otherUserId]
  /// (created if it doesn't exist — race-safe server side; friends only).
  Future<String> getOrCreateConversation(String otherUserId) async {
    final res = await _client.rpc(
      Rpcs.getOrCreateConversation,
      params: {'other_user_id': otherUserId},
    );
    return res as String;
  }

  // ---- friendships / blocking ----
  /// One of: none | pending_out | pending_in | friends | blocked.
  Future<String> relationship(String otherId) async {
    final res = await _client
        .rpc(Rpcs.relationshipWith, params: {'other_user': otherId});
    return (res as String?) ?? 'none';
  }

  Future<void> sendRequest(String otherId) =>
      _client.rpc(Rpcs.sendFriendRequest, params: {'addressee': otherId});

  Future<void> acceptRequest(String requesterId) =>
      _client.rpc(Rpcs.acceptFriendRequest, params: {'requester': requesterId});

  Future<void> blockUser(String otherId) =>
      _client.rpc(Rpcs.blockUser, params: {'target': otherId});

  Future<void> unblockUser(String otherId) =>
      _client.rpc(Rpcs.unblockUser, params: {'target': otherId});

  /// Cancel an outgoing request / reject incoming / unfriend.
  Future<void> removeFriendship(String otherId) async {
    final me = SupabaseService.currentUserId!;
    await _client.from(Tables.friendships).delete().or(
          'and(requester_id.eq.$me,addressee_id.eq.$otherId),'
          'and(requester_id.eq.$otherId,addressee_id.eq.$me)',
        );
  }

  /// My accepted friends (used by the games challenge picker).
  Future<List<Profile>> friends() async {
    final me = SupabaseService.currentUserId!;
    final rows = await _client
        .from(Tables.friendships)
        .select('requester_id, addressee_id')
        .eq('status', 'accepted')
        .or('requester_id.eq.$me,addressee_id.eq.$me');
    final ids = [
      for (final r in (rows as List))
        (r['requester_id'] as String) == me
            ? r['addressee_id'] as String
            : r['requester_id'] as String,
    ];
    return _profilesByIds(ids);
  }

  /// Incoming pending requests (people who want to friend me).
  Future<List<Profile>> incomingRequests() =>
      _pendingProfiles(column: 'addressee_id', select: 'requester_id');

  /// Outgoing pending requests (people I asked to friend).
  Future<List<Profile>> outgoingRequests() =>
      _pendingProfiles(column: 'requester_id', select: 'addressee_id');

  /// Profiles I've blocked (for the Privacy → Blocked contacts screen).
  Future<List<Profile>> blockedUsers() async {
    final me = SupabaseService.currentUserId!;
    final rows = await _client
        .from(Tables.userBlocks)
        .select('blocked_id')
        .eq('blocker_id', me);
    final ids = (rows as List).map((r) => r['blocked_id'] as String).toList();
    return _profilesByIds(ids);
  }

  Future<List<Profile>> _pendingProfiles({
    required String column,
    required String select,
  }) async {
    final me = SupabaseService.currentUserId!;
    final rows = await _client
        .from(Tables.friendships)
        .select(select)
        .eq(column, me)
        .eq('status', 'pending');
    final ids = (rows as List).map((r) => r[select] as String).toList();
    return _profilesByIds(ids);
  }

  Future<List<Profile>> _profilesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final profiles =
        await _client.from(Tables.profiles).select().inFilter('id', ids);
    return (profiles as List)
        .map((e) => Profile.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
