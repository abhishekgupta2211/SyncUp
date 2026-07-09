import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../models/post.dart';
import '../repositories/feed_repository.dart';

/// App-lifetime feed state: the friend-only post list, kept fresh via realtime.
class FeedProvider extends ChangeNotifier {
  FeedProvider() {
    _authSub = SupabaseService.auth.onAuthStateChange.listen((s) {
      switch (s.event) {
        case AuthChangeEvent.signedOut:
          _clear();
        case AuthChangeEvent.signedIn:
          _start();
        case AuthChangeEvent.initialSession:
          if (s.session != null) _start();
        default:
          break;
      }
    });
    _start();
  }

  final FeedRepository _repo = FeedRepository(SupabaseService.client);
  late final StreamSubscription<AuthState> _authSub;
  RealtimeChannel? _channel;
  List<Post> _posts = [];
  bool _loading = true;

  List<Post> get posts => List.unmodifiable(_posts);
  bool get loading => _loading;

  Future<void> _start() async {
    await load();
    _subscribe();
  }

  Future<void> load() async {
    try {
      _posts = await _repo.fetchFeed();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  void _subscribe() {
    final old = _channel;
    if (old != null) _repo.removeChannel(old);
    _channel = _repo.subscribeFeed(load);
  }

  Future<void> toggleLike(Post post) async {
    final wasLiked = post.likedByMe;
    _replace(post.copyWith(
      likedByMe: !wasLiked,
      likeCount: (post.likeCount + (wasLiked ? -1 : 1)).clamp(0, 1 << 30),
    ));
    try {
      await _repo.toggleLike(post.id, wasLiked);
    } catch (_) {
      _replace(post); // revert
    }
  }

  Future<void> toggleBookmark(Post post) async {
    final wasBookmarked = post.isBookmarked;
    _replace(post.copyWith(isBookmarked: !wasBookmarked));
    try {
      await _repo.toggleBookmark(post.id, wasBookmarked);
    } catch (_) {
      _replace(post); // revert
    }
  }

  Future<Post?> createTextPost(String text) => _create(() =>
      _repo.createPost(kind: 'text', text: text));

  Future<Post?> createMediaPost({
    required String kind, // 'image' | 'video'
    required Uint8List bytes,
    required String ext,
    required String contentType,
    String? text,
    Map<String, dynamic>? mediaMeta,
  }) =>
      _create(() async {
        final url = await _repo.uploadPostMedia(bytes, ext,
            contentType: contentType);
        return _repo.createPost(
            kind: kind, text: text, mediaUrl: url, mediaMeta: mediaMeta);
      });

  Future<Post?> _create(Future<Post> Function() run) async {
    try {
      final post = await run();
      _posts = [post, ..._posts];
      notifyListeners();
      return post;
    } catch (_) {
      return null;
    }
  }

  Future<void> deletePost(String id) async {
    _posts = _posts.where((p) => p.id != id).toList();
    notifyListeners();
    try {
      await _repo.deletePost(id);
    } catch (_) {}
  }

  /// Refresh a single post's comment count after the comments sheet closes.
  void bumpCommentCount(String postId, int delta) {
    final i = _posts.indexWhere((p) => p.id == postId);
    if (i < 0) return;
    _posts[i] = _posts[i]
        .copyWith(commentCount: (_posts[i].commentCount + delta).clamp(0, 1 << 30));
    notifyListeners();
  }

  void _replace(Post post) {
    final i = _posts.indexWhere((p) => p.id == post.id);
    if (i < 0) return;
    _posts[i] = post;
    notifyListeners();
  }

  void _clear() {
    final old = _channel;
    if (old != null) _repo.removeChannel(old);
    _channel = null;
    _posts = [];
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub.cancel();
    final old = _channel;
    if (old != null) _repo.removeChannel(old);
    super.dispose();
  }
}
