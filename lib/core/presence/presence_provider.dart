import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_refs.dart';
import '../supabase/supabase_service.dart';

/// Global online presence (who is currently online) + last-seen stamping.
///
/// Each signed-in client tracks itself on a shared Realtime presence channel.
/// App-lifetime (registered in `main`, created lazily after login).
class PresenceProvider extends ChangeNotifier with WidgetsBindingObserver {
  PresenceProvider() {
    WidgetsBinding.instance.addObserver(this);
    _authSub = _client.auth.onAuthStateChange.listen((s) {
      switch (s.event) {
        case AuthChangeEvent.signedOut:
          _stop();
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.initialSession:
          _start();
        default:
          break;
      }
    });
    _start();
  }

  final SupabaseClient _client = SupabaseService.client;
  late final StreamSubscription<AuthState> _authSub;
  RealtimeChannel? _channel;
  Set<String> _online = {};

  Set<String> get online => _online;
  bool isOnline(String userId) => _online.contains(userId);

  void _start() {
    final me = SupabaseService.currentUserId;
    if (me == null || _channel != null) return;
    final channel = _client.channel('online-users');
    channel
      ..onPresenceSync((_) => _recompute())
      ..onPresenceJoin((_) => _recompute())
      ..onPresenceLeave((_) => _recompute())
      ..subscribe((status, _) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          await channel.track({'user_id': me});
        }
      });
    _channel = channel;
  }

  void _recompute() {
    final ids = <String>{};
    final ch = _channel;
    if (ch != null) {
      for (final state in ch.presenceState()) {
        for (final p in state.presences) {
          final uid = p.payload['user_id'];
          if (uid is String) ids.add(uid);
        }
      }
    }
    _online = ids;
    notifyListeners();
  }

  Future<DateTime?> fetchLastSeen(String userId) async {
    try {
      final row = await _client
          .from(Tables.profiles)
          .select('last_seen')
          .eq('id', userId)
          .maybeSingle();
      final ls = row?['last_seen'];
      return ls == null ? null : DateTime.parse(ls.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  Future<void> _stampLastSeen() async {
    final me = SupabaseService.currentUserId;
    if (me == null) return;
    try {
      await _client
          .from(Tables.profiles)
          .update({'last_seen': DateTime.now().toUtc().toIso8601String()})
          .eq('id', me);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _start();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stampLastSeen();
    }
  }

  void _stop() {
    final ch = _channel;
    if (ch != null) {
      ch.untrack();
      _client.removeChannel(ch);
    }
    _channel = null;
    _online = {};
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub.cancel();
    final ch = _channel;
    if (ch != null) {
      ch.untrack();
      _client.removeChannel(ch);
    }
    super.dispose();
  }
}
