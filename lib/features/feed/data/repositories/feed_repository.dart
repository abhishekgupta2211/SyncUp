import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/supabase/supabase_refs.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../models/post.dart';
import '../models/post_comment.dart';

/// Reads the feed + mutates posts, likes and comments (all friend-gated by RLS).
class FeedRepository {
  FeedRepository(this._client);

  final SupabaseClient _client;
  final _uuid = const Uuid();

  String get _me => SupabaseService.currentUserId!;

  static const _authorEmbed =
      'author:profiles!posts_author_id_fkey(display_name, username, avatar_url)';
  static const _commentAuthorEmbed =
      'author:profiles!post_comments_user_id_fkey(display_name, avatar_url)';

  Future<List<Post>> fetchFeed({int limit = 50}) async {
    final rows = await _client
        .from(Tables.posts)
        .select('*, $_authorEmbed')
        .order('created_at', ascending: false)
        .limit(limit);
    final posts = (rows as List)
        .map((e) => Post.fromMap(e as Map<String, dynamic>))
        .toList();
    if (posts.isEmpty) return posts;

    final liked = <String>{};
    final bookmarked = <String>{};
    try {
      final likeRows = await _client
          .from(Tables.postLikes)
          .select('post_id')
          .eq('user_id', _me)
          .inFilter('post_id', posts.map((p) => p.id).toList());
      for (final r in (likeRows as List)) {
        liked.add(r['post_id'] as String);
      }

      final bookmarkRows = await _client
          .from('post_bookmarks')
          .select('post_id')
          .eq('user_id', _me)
          .inFilter('post_id', posts.map((p) => p.id).toList());
      for (final r in (bookmarkRows as List)) {
        bookmarked.add(r['post_id'] as String);
      }
    } catch (_) {}
    return [for (final p in posts) p.copyWith(
      likedByMe: liked.contains(p.id),
      isBookmarked: bookmarked.contains(p.id),
    )];
  }

  Future<void> toggleBookmark(String postId, bool currentlyBookmarked) async {
    if (currentlyBookmarked) {
      await _client
          .from('post_bookmarks')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', _me);
    } else {
      await _client
          .from('post_bookmarks')
          .insert({'post_id': postId, 'user_id': _me});
    }
  }

  Future<String> uploadPostMedia(
    Uint8List bytes,
    String ext, {
    String contentType = 'application/octet-stream',
  }) async {
    final path = '$_me/${_uuid.v4()}.$ext';
    await _client.storage.from(Buckets.posts).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return _client.storage.from(Buckets.posts).getPublicUrl(path);
  }

  Future<Post> createPost({
    required String kind,
    String? text,
    String? mediaUrl,
    Map<String, dynamic>? mediaMeta,
  }) async {
    final row = await _client
        .from(Tables.posts)
        .insert({
          'author_id': _me,
          'kind': kind,
          'text': (text != null && text.isNotEmpty) ? text : null,
          'media_url': mediaUrl,
          'media_meta': mediaMeta,
        })
        .select('*, $_authorEmbed')
        .single();
    return Post.fromMap(row);
  }

  Future<void> toggleLike(String postId, bool currentlyLiked) async {
    if (currentlyLiked) {
      await _client
          .from(Tables.postLikes)
          .delete()
          .eq('post_id', postId)
          .eq('user_id', _me);
    } else {
      await _client
          .from(Tables.postLikes)
          .insert({'post_id': postId, 'user_id': _me});
    }
  }

  Future<void> deletePost(String id) =>
      _client.from(Tables.posts).delete().eq('id', id);

  Future<List<PostComment>> fetchComments(String postId) async {
    final rows = await _client
        .from(Tables.postComments)
        .select('*, $_commentAuthorEmbed')
        .eq('post_id', postId)
        .order('created_at', ascending: true);
    return (rows as List)
        .map((e) => PostComment.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<PostComment> addComment(
    String postId,
    String text, {
    String? parentId,
  }) async {
    final row = await _client
        .from(Tables.postComments)
        .insert({
          'post_id': postId,
          'user_id': _me,
          'text': text,
          'parent_id': parentId,
        })
        .select('*, $_commentAuthorEmbed')
        .single();
    return PostComment.fromMap(row);
  }

  Future<void> deleteComment(String id) =>
      _client.from(Tables.postComments).delete().eq('id', id);

  RealtimeChannel subscribeFeed(void Function() onChange) {
    final channel = _client.channel('feed:$_me')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: Tables.posts,
        callback: (_) => onChange(),
      )
      ..subscribe();
    return channel;
  }

  Future<void> removeChannel(RealtimeChannel channel) =>
      _client.removeChannel(channel);
}
