import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../models/app_notification.dart';
import '../repositories/notification_repository.dart';

/// App-lifetime notification state: the list + live unread count, kept fresh via
/// realtime. Resets on account switch.
class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider() {
    _authSub = SupabaseService.auth.onAuthStateChange.listen((s) {
      switch (s.event) {
        case AuthChangeEvent.signedOut:
          _clear();
        case AuthChangeEvent.signedIn:
          _start();
        case AuthChangeEvent.initialSession:
          if (s.session != null) _start();
        default:
          break;
      }
    });
    _start();
  }

  final NotificationRepository _repo =
      NotificationRepository(SupabaseService.client);
  late final StreamSubscription<AuthState> _authSub;
  RealtimeChannel? _channel;
  List<AppNotification> _items = [];
  bool _loading = true;

  List<AppNotification> get items => List.unmodifiable(_items);
  int get unread => _items.where((n) => !n.read).length;
  bool get loading => _loading;

  Future<void> _start() async {
    await load();
    _subscribe();
  }

  Future<void> load() async {
    try {
      _items = await _repo.fetch();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  void _subscribe() {
    final old = _channel;
    if (old != null) _repo.removeChannel(old);
    _channel = _repo.subscribe(load);
  }

  Future<void> markRead(String id) async {
    _setLocal(id, true);
    try {
      await _repo.markRead(id);
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    _items = [for (final n in _items) n.copyWith(read: true)];
    notifyListeners();
    try {
      await _repo.markAllRead();
    } catch (_) {}
  }

  Future<void> remove(String id) async {
    _items = _items.where((n) => n.id != id).toList();
    notifyListeners();
    try {
      await _repo.remove(id);
    } catch (_) {}
  }

  Future<void> clearAll() async {
    _items = [];
    notifyListeners();
    try {
      await _repo.clearAll();
    } catch (_) {}
  }

  void _setLocal(String id, bool read) {
    _items = [
      for (final n in _items) n.id == id ? n.copyWith(read: read) : n,
    ];
    notifyListeners();
  }

  void _clear() {
    final old = _channel;
    if (old != null) _repo.removeChannel(old);
    _channel = null;
    _items = [];
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub.cancel();
    final old = _channel;
    if (old != null) _repo.removeChannel(old);
    super.dispose();
  }
}
