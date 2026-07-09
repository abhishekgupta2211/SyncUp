import 'package:intl/intl.dart';

/// Time/date formatting helpers for chat lists and bubbles.
class ChatTime {
  ChatTime._();

  /// Bubble/list timestamp: "5:08 PM".
  static String time(DateTime dt) => DateFormat('h:mm a').format(dt.toLocal());

  /// Chat-list relative label: time today, "Yesterday", weekday, else dd/MM/yy.
  static String listLabel(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(local.year, local.month, local.day);
    final diff = today.difference(that).inDays;
    if (diff <= 0) return DateFormat('h:mm a').format(local);
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(local);
    return DateFormat('dd/MM/yy').format(local);
  }

  /// Floating date header: "Today" / "Yesterday" / "12 June 2026".
  static String dayHeader(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(local.year, local.month, local.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('d MMMM yyyy').format(local);
  }

  static bool sameDay(DateTime a, DateTime b) {
    final x = a.toLocal();
    final y = b.toLocal();
    return x.year == y.year && x.month == y.month && x.day == y.day;
  }
}
