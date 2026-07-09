import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/supabase/supabase_refs.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../models/story.dart';

class StoryRepository {
  final SupabaseClient _c = SupabaseService.client;
  static const _uuid = Uuid();

  String get _me => SupabaseService.currentUserId!;

  Future<void> postStory(XFile file) async {
    final id = _uuid.v4();
    final raw = await file.readAsBytes();
    final compressed = await FlutterImageCompress.compressWithList(
      raw,
      quality: 72,
      minWidth: 1080,
      minHeight: 1080,
    );
    final path = '$_me/$id.jpg';
    await _c.storage.from(Buckets.stories).uploadBinary(
          path,
          compressed,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
    final url = _c.storage.from(Buckets.stories).getPublicUrl(path);
    await _c.from(Tables.stories).insert({
      'id': id,
      'user_id': _me,
      'media_url': url,
      'media_type': 'image',
    });
  }

  /// Active (non-expired) stories visible to me, grouped per user (mine first).
  Future<List<UserStories>> fetchActiveStories() async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final rows = await _c
        .from(Tables.stories)
        // Disambiguate: stories→profiles also reachable via likes/comments/views,
        // so pin the direct user_id FK or PostgREST throws PGRST201.
        .select(
            '*, profiles!stories_user_id_fkey(id, username, display_name, avatar_url)')
        .gt('expires_at', nowIso)
        .order('created_at', ascending: true);

    final byUser = <String, List<Story>>{};
    final authors = <String, Map<String, dynamic>>{};
    for (final r in (rows as List).cast<Map<String, dynamic>>()) {
      final s = Story.fromMap(r);
      (byUser[s.userId] ??= []).add(s);
      final p = r['profiles'];
      if (p != null) authors[s.userId] = (p as Map).cast<String, dynamic>();
    }

    final groups = <UserStories>[];
    byUser.forEach((userId, stories) {
      final a = authors[userId];
      groups.add(UserStories(
        userId: userId,
        name: (a?['display_name'] ?? 'User') as String,
        username: (a?['username'] ?? '') as String,
        avatarUrl: a?['avatar_url'] as String?,
        stories: stories,
      ));
    });
    // mine first, then most-recent first
    groups.sort((x, y) {
      if (x.userId == _me) return -1;
      if (y.userId == _me) return 1;
      return y.latestAt.compareTo(x.latestAt);
    });
    return groups;
  }

  Future<void> deleteStory(String storyId) async {
    await _c.from(Tables.stories).delete().eq('id', storyId);
    try {
      await _c.storage.from(Buckets.stories).remove(['$_me/$storyId.jpg']);
    } catch (_) {}
  }

  Future<Set<String>> fetchMySeen() async {
    final rows =
        await _c.from(Tables.storyViews).select('story_id').eq('viewer_id', _me);
    return (rows as List).map((r) => r['story_id'] as String).toSet();
  }

  Future<void> recordView(String storyId) async {
    await _c.from(Tables.storyViews).upsert(
      {'story_id': storyId, 'viewer_id': _me},
      onConflict: 'story_id,viewer_id',
    );
  }

  Future<List<StoryViewer>> fetchViewers(String storyId) async {
    final rows = await _c
        .from(Tables.storyViews)
        .select('viewed_at, profiles(id, display_name, avatar_url)')
        .eq('story_id', storyId)
        .order('viewed_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>().map((r) {
      final p = (r['profiles'] as Map?)?.cast<String, dynamic>();
      return StoryViewer(
        userId: (p?['id'] ?? '') as String,
        name: (p?['display_name'] ?? 'User') as String,
        avatarUrl: p?['avatar_url'] as String?,
        viewedAt: DateTime.parse(r['viewed_at'].toString()).toLocal(),
      );
    }).toList();
  }

  Future<({int count, bool liked})> fetchLikeState(String storyId) async {
    final rows =
        await _c.from(Tables.storyLikes).select('user_id').eq('story_id', storyId);
    final list = (rows as List).cast<Map<String, dynamic>>();
    return (count: list.length, liked: list.any((r) => r['user_id'] == _me));
  }

  Future<void> setLike(String storyId, bool like) async {
    if (like) {
      await _c.from(Tables.storyLikes).upsert(
        {'story_id': storyId, 'user_id': _me},
        onConflict: 'story_id,user_id',
      );
    } else {
      await _c
          .from(Tables.storyLikes)
          .delete()
          .eq('story_id', storyId)
          .eq('user_id', _me);
    }
  }

  Future<List<StoryComment>> fetchComments(String storyId) async {
    final rows = await _c
        .from(Tables.storyComments)
        .select('*, profiles(display_name, avatar_url)')
        .eq('story_id', storyId)
        .order('created_at', ascending: true);
    return (rows as List).cast<Map<String, dynamic>>().map((r) {
      final p = (r['profiles'] as Map?)?.cast<String, dynamic>();
      return StoryComment(
        id: r['id'] as String,
        userId: r['user_id'] as String,
        name: (p?['display_name'] ?? 'User') as String,
        avatarUrl: p?['avatar_url'] as String?,
        text: (r['text'] ?? '') as String,
        createdAt: DateTime.parse(r['created_at'].toString()).toLocal(),
      );
    }).toList();
  }

  Future<void> addComment(String storyId, String text) async {
    await _c.from(Tables.storyComments).insert({
      'story_id': storyId,
      'user_id': _me,
      'text': text.trim(),
    });
  }
}
