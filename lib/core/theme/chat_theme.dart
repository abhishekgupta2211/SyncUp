import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Live, theme-aware tokens for chat surfaces (bubbles, heart status, badges).
///
/// Read via `Theme.of(context).extension<ChatTheme>()!` so a theme/mode swap
/// recolours the chat instantly with no widget rebuilds in the call sites.
class ChatTheme extends ThemeExtension<ChatTheme> {
  final Color incomingBubble;
  final Color incomingText;
  final Color outgoingText;
  final Gradient outgoingGradient;
  final Color heartEmpty;
  final Color heartFilled;
  final Color onlineDot;
  final Color unreadBadge;
  final Color timestamp;

  const ChatTheme({
    required this.incomingBubble,
    required this.incomingText,
    required this.outgoingText,
    required this.outgoingGradient,
    required this.heartEmpty,
    required this.heartFilled,
    required this.onlineDot,
    required this.unreadBadge,
    required this.timestamp,
  });

  /// Builds the chat tokens for a given [accent] + [brightness] so a user's
  /// accent choice recolours sent bubbles, hearts and badges instantly.
  factory ChatTheme.fromAccent(Color accent, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ChatTheme(
      incomingBubble:
          isDark ? AppColors.darkReceivedBubble : AppColors.lightReceivedBubble,
      incomingText:
          isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      outgoingText: Colors.white,
      outgoingGradient: AppColors.gradientFrom(accent),
      heartEmpty: isDark ? Colors.white : const Color(0xFFB9B9C9),
      heartFilled: accent,
      onlineDot: AppColors.online,
      unreadBadge: accent,
      timestamp:
          isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
    );
  }

  @override
  ChatTheme copyWith({
    Color? incomingBubble,
    Color? incomingText,
    Color? outgoingText,
    Gradient? outgoingGradient,
    Color? heartEmpty,
    Color? heartFilled,
    Color? onlineDot,
    Color? unreadBadge,
    Color? timestamp,
  }) {
    return ChatTheme(
      incomingBubble: incomingBubble ?? this.incomingBubble,
      incomingText: incomingText ?? this.incomingText,
      outgoingText: outgoingText ?? this.outgoingText,
      outgoingGradient: outgoingGradient ?? this.outgoingGradient,
      heartEmpty: heartEmpty ?? this.heartEmpty,
      heartFilled: heartFilled ?? this.heartFilled,
      onlineDot: onlineDot ?? this.onlineDot,
      unreadBadge: unreadBadge ?? this.unreadBadge,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  ChatTheme lerp(ThemeExtension<ChatTheme>? other, double t) {
    if (other is! ChatTheme) return this;
    return ChatTheme(
      incomingBubble: Color.lerp(incomingBubble, other.incomingBubble, t)!,
      incomingText: Color.lerp(incomingText, other.incomingText, t)!,
      outgoingText: Color.lerp(outgoingText, other.outgoingText, t)!,
      outgoingGradient: Gradient.lerp(outgoingGradient, other.outgoingGradient, t)!,
      heartEmpty: Color.lerp(heartEmpty, other.heartEmpty, t)!,
      heartFilled: Color.lerp(heartFilled, other.heartFilled, t)!,
      onlineDot: Color.lerp(onlineDot, other.onlineDot, t)!,
      unreadBadge: Color.lerp(unreadBadge, other.unreadBadge, t)!,
      timestamp: Color.lerp(timestamp, other.timestamp, t)!,
    );
  }
}
