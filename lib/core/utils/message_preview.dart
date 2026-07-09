/// Renders a conversation's last-message preview for the chat list.
class MessagePreview {
  MessagePreview._();

  /// [type] is the raw `last_message_type` string from the DB.
  static String of({required String? type, required String text}) {
    switch (type) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎬 Video';
      case 'voice':
        return '🎤 Voice message';
      case 'document':
        return '📄 Document';
      case 'location':
        return '📍 Location';
      case 'gif':
        return 'GIF';
      case 'sticker':
        return 'Sticker';
      case 'text':
      case 'emoji':
      default:
        return text;
    }
  }
}
