/// Maps to the `public.message_reactions` table.
class Reaction {
  final String messageId;
  final String userId;
  final String emoji;

  const Reaction({
    required this.messageId,
    required this.userId,
    required this.emoji,
  });

  factory Reaction.fromMap(Map<String, dynamic> m) => Reaction(
        messageId: m['message_id'] as String,
        userId: m['user_id'] as String,
        emoji: (m['emoji'] ?? '') as String,
      );
}
