import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_service.dart';
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

class PushService {
  PushService._();

  static bool _ready = false;
  static String? _token;
  static StreamSubscription<AuthState>? _authSub;

  static Future<void> init() async {
    if (_ready) return;
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase not configured — push disabled: $e');
      return;
    }
    _ready = true;

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.instance.onTokenRefresh.listen((t) {
      _token = t;
      _register(t);
    });

    // Register/unregister the token as the account changes.
    _authSub = SupabaseService.auth.onAuthStateChange.listen((s) {
      switch (s.event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.initialSession:
          if (SupabaseService.currentUserId != null) registerForCurrentUser();
        default:
          break;
      }
    });

    if (SupabaseService.currentUserId != null) {
      await registerForCurrentUser();
    }
  }

  /// Fetch (if needed) and persist this device's token for the current user.
  static Future<void> registerForCurrentUser() async {
    if (!_ready) return;
    try {
      final t = _token ?? await FirebaseMessaging.instance.getToken();
      if (t == null) return;
      _token = t;
      await _register(t);
    } catch (e) {
      debugPrint('push register failed: $e');
    }
  }

  static Future<void> _register(String token) async {
    if (SupabaseService.currentUserId == null) return;
    try {
      await SupabaseService.client.rpc('register_device_token', params: {
        'p_token': token,
        'p_platform': Platform.isIOS ? 'ios' : 'android',
      });
    } catch (e) {
      debugPrint('register_device_token failed: $e');
    }
  }

  /// Drop this device's token — call BEFORE signing out (while still authed).
  static Future<void> unregister() async {
    if (!_ready) return;
    final t = _token;
    if (t == null) return;
    try {
      await SupabaseService.client
          .rpc('unregister_device_token', params: {'p_token': t});
    } catch (_) {}
  }

  static void dispose() {
    _authSub?.cancel();
    _authSub = null;
  }
}
