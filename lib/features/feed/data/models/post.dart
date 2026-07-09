import 'dart:convert';

/// One feed post (permanent, friend-only). kind = text | image | video.
class Post {
  final String id;
  final String authorId;
  final String kind;
  final String? text;
  final String? mediaUrl;
  final Map<String, dynamic>? mediaMeta;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;

  // author embed
  final String? authorName;
  final String? authorUsername;
  final String? authorAvatar;

  // viewer state
  final bool likedByMe;
  final bool isBookmarked; // NEW

  const Post({
    required this.id,
    required this.authorId,
    required this.kind,
    this.text,
    this.mediaUrl,
    this.mediaMeta,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    this.authorName,
    this.authorUsername,
    this.authorAvatar,
    this.likedByMe = false,
    this.isBookmarked = false, // NEW
  });

  bool get isImage => kind == 'image';
  bool get isVideo => kind == 'video';
  bool get isText => kind == 'text';
  bool isMine(String me) => authorId == me;

  factory Post.fromMap(Map<String, dynamic> m, {bool likedByMe = false, bool isBookmarked = false}) {
    final a = (m['author'] as Map?)?.cast<String, dynamic>();
    return Post(
      id: m['id'] as String,
      authorId: m['author_id'] as String,
      kind: (m['kind'] ?? 'text') as String,
      text: m['text'] as String?,
      mediaUrl: m['media_url'] as String?,
      mediaMeta: _decode(m['media_meta']),
      likeCount: (m['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (m['comment_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(m['created_at'].toString()).toLocal(),
      authorName: a?['display_name'] as String?,
      authorUsername: a?['username'] as String?,
      authorAvatar: a?['avatar_url'] as String?,
      likedByMe: likedByMe,
      isBookmarked: isBookmarked, // NEW
    );
  }

  static Map<String, dynamic>? _decode(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.cast<String, dynamic>();
    if (raw is String && raw.isNotEmpty) {
      final d = jsonDecode(raw);
      if (d is Map) return d.cast<String, dynamic>();
    }
    return null;
  }

  Post copyWith({int? likeCount, int? commentCount, bool? likedByMe, bool? isBookmarked}) => Post(
        id: id,
        authorId: authorId,
        kind: kind,
        text: text,
        mediaUrl: mediaUrl,
        mediaMeta: mediaMeta,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount ?? this.commentCount,
        createdAt: createdAt,
        authorName: authorName,
        authorUsername: authorUsername,
        authorAvatar: authorAvatar,
        likedByMe: likedByMe ?? this.likedByMe,
        isBookmarked: isBookmarked ?? this.isBookmarked,
      );
}
