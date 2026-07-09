/// Message content types — mirror the Postgres `message_type_enum`.
enum MessageType {
  text,
  emoji,
  image,
  video,
  voice,
  document,
  location,
  gif,
  sticker;

  static MessageType fromDb(Object? value) {
    final s = value?.toString();
    return MessageType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => MessageType.text,
    );
  }
}

/// Outgoing delivery state — drives the heart status (♡ white → 🩷 pink).
enum DeliveryState { sending, sent, seen, failed }
