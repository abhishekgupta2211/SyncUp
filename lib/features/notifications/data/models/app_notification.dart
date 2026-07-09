import 'dart:convert';

/// One in-app notification row (with the actor's profile joined).
class AppNotification {
  final String id;
  final String type; // friend_request | friend_accept | story_like | story_comment | reaction | call | game_invite
  final String title;
  final String? body;
  final String? actorId;
  final String? actorName;
  final String? actorAvatarUrl;
  final Map<String, dynamic>? data; // deep-link payload (e.g. {match_id, game})
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.actorId,
    this.actorName,
    this.actorAvatarUrl,
    this.data,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> m) {
    final actor = m['actor'] as Map<String, dynamic>?;
    return AppNotification(
      id: m['id'] as String,
      type: (m['type'] ?? '') as String,
      title: (m['title'] ?? '') as String,
      body: m['body'] as String?,
      actorId: m['actor_id'] as String?,
      actorName: actor?['display_name'] as String?,
      actorAvatarUrl: actor?['avatar_url'] as String?,
      data: _decodeData(m['data']),
      read: (m['read'] ?? false) as bool,
      createdAt: DateTime.parse(m['created_at'].toString()).toLocal(),
    );
  }

  static Map<String, dynamic>? _decodeData(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.cast<String, dynamic>();
    if (raw is String && raw.isNotEmpty) {
      final d = jsonDecode(raw);
      if (d is Map) return d.cast<String, dynamic>();
    }
    return null;
  }

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        actorId: actorId,
        actorName: actorName,
        actorAvatarUrl: actorAvatarUrl,
        data: data,
        read: read ?? this.read,
        createdAt: createdAt,
      );
}
