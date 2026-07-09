import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/services/translation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/message.dart';
import '../../data/providers/chat_controller.dart';

const _quickEmojis = ['❤️', '😂', '👍', '😮', '😢', '🙏'];

/// Long-press menu: quick reactions + reply / copy / delete actions.
Future<void> showMessageActions(
  BuildContext context, {
  required Message message,
  required ChatController controller,
  required String myId,
}) {
  final mine = message.senderId == myId;
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return SafeArea(
        child: Container(
          margin: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(22.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ... reactions row unchanged ...
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final e in _quickEmojis)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          controller.toggleReaction(message.messageId, e);
                          Navigator.pop(sheetContext);
                        },
                        child: Text(e, style: TextStyle(fontSize: 26.sp)),
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.colorScheme.outline),
              if (!message.deletedForEveryone)
                _ActionRow(
                  icon: Icons.reply,
                  label: 'Reply',
                  onTap: () {
                    controller.setReply(message);
                    Navigator.pop(sheetContext);
                  },
                ),
              if (!message.deletedForEveryone && message.message.isNotEmpty) ...[
                _ActionRow(
                  icon: Icons.translate,
                  label: 'Translate to Hindi',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final translated = await TranslationService.translate(message.message, 'hi');
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Translation'),
                          content: Text(translated),
                          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                        ),
                      );
                    }
                  },
                ),
                _ActionRow(
                  icon: Icons.copy_outlined,
                  label: 'Copy',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message.message));
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
              _ActionRow(
                icon: Icons.delete_outline,
                label: 'Delete for me',
                onTap: () {
                  controller.deleteForMe(message);
                  Navigator.pop(sheetContext);
                },
              ),
              if (mine && !message.deletedForEveryone)
                _ActionRow(
                  icon: Icons.delete_forever_outlined,
                  label: 'Delete for everyone',
                  danger: true,
                  onTap: () {
                    controller.deleteForEveryone(message);
                    Navigator.pop(sheetContext);
                  },
                ),
              SizedBox(height: 6.h),
            ],
          ),
        ),
      );
    },
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = danger ? AppColors.danger : theme.colorScheme.onSurface;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color, size: 22.r),
      title: Text(label, style: theme.textTheme.bodyLarge?.copyWith(color: color)),
    );
  }
}
