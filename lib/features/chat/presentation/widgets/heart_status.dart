import 'package:flutter/material.dart';

import '../../../../core/theme/chat_theme.dart';
import '../../data/models/message_enums.dart';

/// Heart delivery indicator on outgoing messages:
/// sending → faint outline · sent → white outline ♡ · seen → filled pink 🩷.
class HeartStatus extends StatelessWidget {
  const HeartStatus({super.key, required this.state, this.size = 14});

  final DeliveryState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final chat = Theme.of(context).extension<ChatTheme>()!;

    final (IconData icon, Color color) = switch (state) {
      DeliveryState.sending => (
          Icons.favorite_border,
          chat.heartEmpty.withValues(alpha: 0.5)
        ),
      DeliveryState.sent => (Icons.favorite_border, chat.heartEmpty),
      DeliveryState.seen => (Icons.favorite, chat.heartFilled),
      DeliveryState.failed => (Icons.error_outline, Colors.redAccent),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: Icon(
        icon,
        key: ValueKey(state),
        size: size,
        color: color,
      ),
    );
  }
}
