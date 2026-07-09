/// Maps to the `public.stories` table (one image segment).
class Story {
  final String id;
  final String userId;
  final String mediaUrl;
  final String mediaType;
  final String? caption;
  final DateTime createdAt;
  final DateTime expiresAt;

  const Story({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.mediaType,
    this.caption,
    required this.createdAt,
    required this.expiresAt,
  });

  factory Story.fromMap(Map<String, dynamic> m) => Story(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        mediaUrl: (m['media_url'] ?? '') as String,
        mediaType: (m['media_type'] ?? 'image') as String,
        caption: m['caption'] as String?,
        createdAt: DateTime.parse(m['created_at'].toString()).toLocal(),
        expiresAt: DateTime.parse(m['expires_at'].toString()).toLocal(),
      );
}

/// A user's active stories, grouped for the tray.
class UserStories {
  final String userId;
  final String name;
  final String username;
  final String? avatarUrl;
  final List<Story> stories; // oldest → newest

  const UserStories({
    required this.userId,
    required this.name,
    required this.username,
    this.avatarUrl,
    required this.stories,
  });

  DateTime get latestAt => stories.last.createdAt;
}

/// A viewer of a story (for the seen-by sheet).
class StoryViewer {
  final String userId;
  final String name;
  final String? avatarUrl;
  final DateTime viewedAt;

  const StoryViewer({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.viewedAt,
  });
}

/// A comment on a story.
class StoryComment {
  final String id;
  final String userId;
  final String name;
  final String? avatarUrl;
  final String text;
  final DateTime createdAt;

  const StoryComment({
    required this.id,
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.text,
    required this.createdAt,
  });
}
