import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/chat_theme.dart';

/// Animated "peer is typing" bubble — three staggered bouncing dots, styled as
/// an incoming message bubble.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = Theme.of(context).extension<ChatTheme>()!;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: chat.incomingBubble,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18.r),
            topRight: Radius.circular(18.r),
            bottomRight: Radius.circular(18.r),
            bottomLeft: Radius.circular(4.r),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [for (int i = 0; i < 3; i++) _dot(i, chat)],
        ),
      ),
    );
  }

  Widget _dot(int i, ChatTheme chat) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final lift = math.sin((_c.value * 2 * math.pi) - i * 0.9).clamp(0.0, 1.0);
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.5.w),
          child: Transform.translate(
            offset: Offset(0, -4.0 * lift),
            child: Container(
              width: 7.r,
              height: 7.r,
              decoration: BoxDecoration(
                color: chat.incomingText.withValues(alpha: 0.35 + 0.45 * lift),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
