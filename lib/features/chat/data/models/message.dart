import 'message_enums.dart';

/// Maps to the `public.messages` table (+ client-only optimistic flags).
class Message {
  final String messageId; 
  final String conversationId;
  final String senderId;
  final String receiverId;
  final MessageType messageType;
  final String message;
  final String? mediaUrl;
  final String? localPath; 
  final String? replyMessageId;
  final bool seen;
  final bool delivered;
  final bool deletedForEveryone;
  final bool isVanish; 
  final bool isSnap; // NEW: Snap Support
  final List<String> deletedForMe;
  final DateTime createdAt;
  final DateTime updatedAt;

  final bool pending; 
  final bool failed;

  const Message({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.messageType,
    required this.message,
    this.mediaUrl,
    this.localPath,
    this.replyMessageId,
    this.seen = false,
    this.delivered = false,
    this.deletedForEveryone = false,
    this.isVanish = false,
    this.isSnap = false, // NEW
    this.deletedForMe = const [],
    required this.createdAt,
    required this.updatedAt,
    this.pending = false,
    this.failed = false,
  });

  factory Message.fromMap(Map<String, dynamic> m) {
    return Message(
      messageId: m['id'] as String,
      conversationId: m['conversation_id'] as String,
      senderId: m['sender_id'] as String,
      receiverId: m['receiver_id'] as String,
      messageType: MessageType.fromDb(m['message_type']),
      message: (m['message'] ?? '') as String,
      mediaUrl: m['media_url'] as String?,
      replyMessageId: m['reply_message_id'] as String?,
      seen: (m['seen'] ?? false) as bool,
      delivered: (m['delivered'] ?? false) as bool,
      deletedForEveryone: (m['deleted_for_everyone'] ?? false) as bool,
      isVanish: (m['is_vanish'] ?? false) as bool,
      isSnap: (m['is_snap'] ?? false) as bool, // NEW
      deletedForMe:
          ((m['deleted_for_me'] ?? const []) as List).map((e) => e.toString()).toList(),
      createdAt:
          DateTime.parse(m['created_at'].toString()).toLocal(),
      updatedAt:
          DateTime.parse(m['updated_at'].toString()).toLocal(),
    );
  }

  bool isMine(String myId) => senderId == myId;

  DeliveryState deliveryState(String myId) {
    if (failed) return DeliveryState.failed;
    if (pending) return DeliveryState.sending;
    if (seen) return DeliveryState.seen;
    return DeliveryState.sent;
  }

  Message copyWith({
    bool? seen,
    bool? delivered,
    bool? deletedForEveryone,
    bool? isVanish,
    bool? isSnap, // NEW
    List<String>? deletedForMe,
    DateTime? updatedAt,
    bool? pending,
    bool? failed,
    String? localPath,
  }) {
    return Message(
      messageId: messageId,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      messageType: messageType,
      message: message,
      mediaUrl: mediaUrl,
      localPath: localPath ?? this.localPath,
      replyMessageId: replyMessageId,
      seen: seen ?? this.seen,
      delivered: delivered ?? this.delivered,
      deletedForEveryone: deletedForEveryone ?? this.deletedForEveryone,
      isVanish: isVanish ?? this.isVanish,
      isSnap: isSnap ?? this.isSnap, // NEW
      deletedForMe: deletedForMe ?? this.deletedForMe,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pending: pending ?? this.pending,
      failed: failed ?? this.failed,
    );
  }
}
