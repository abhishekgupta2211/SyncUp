/// A comment on a post. [parentId] non-null = a reply to another comment.
class PostComment {
  final String id;
  final String postId;
  final String userId;
  final String? parentId;
  final String text;
  final DateTime createdAt;

  final String? authorName;
  final String? authorAvatar;

  const PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    this.parentId,
    required this.text,
    required this.createdAt,
    this.authorName,
    this.authorAvatar,
  });

  bool get isReply => parentId != null;

  factory PostComment.fromMap(Map<String, dynamic> m) {
    final a = (m['author'] as Map?)?.cast<String, dynamic>();
    return PostComment(
      id: m['id'] as String,
      postId: m['post_id'] as String,
      userId: m['user_id'] as String,
      parentId: m['parent_id'] as String?,
      text: (m['text'] ?? '') as String,
      createdAt: DateTime.parse(m['created_at'].toString()).toLocal(),
      authorName: a?['display_name'] as String?,
      authorAvatar: a?['avatar_url'] as String?,
    );
  }
}
