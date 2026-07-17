/// A 1:1 conversation as seen by the current user (peer denormalized).
class Conversation {
  final String id;
  final String peerId;
  final String peerName;
  final String peerUsername;
  final String? peerAvatarUrl;
  final String lastMessageText;
  final String? lastMessageType;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isArchived; // NEW

  const Conversation({
    required this.id,
    required this.peerId,
    required this.peerName,
    required this.peerUsername,
    this.peerAvatarUrl,
    this.lastMessageText = '',
    this.lastMessageType,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isArchived = false, // NEW
  });

  Conversation copyWith({
    String? lastMessageText,
    String? lastMessageType,
    DateTime? lastMessageAt,
    int? unreadCount,
    String? peerName,
    String? peerAvatarUrl,
    bool? isArchived, // NEW
  }) {
    return Conversation(
      id: id,
      peerId: peerId,
      peerName: peerName ?? this.peerName,
      peerUsername: peerUsername,
      peerAvatarUrl: peerAvatarUrl ?? this.peerAvatarUrl,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isArchived: isArchived ?? this.isArchived, // NEW
    );
  }
}
