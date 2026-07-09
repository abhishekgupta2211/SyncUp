import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/calls/call_service.dart';
import '../../../../core/push/push_service.dart';
import '../../../profile/data/models/profile.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus {
  initializing,
  unauthenticated,
  awaitingVerification,
  needsUsername,
  authenticated,
}

/// App-lifetime auth state. Drives the [AuthGate] routing:
/// splash → login/signup → (verify email) → @username onboarding → home.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repo) {
    _sub = _repo.authStateChanges.listen(_onAuthState);
  }

  final AuthRepository _repo;
  late final StreamSubscription<AuthState> _sub;

  AuthStatus _status = AuthStatus.initializing;
  Profile? _profile;
  String? _pendingEmail;
  String? _error;
  bool _busy = false;

  AuthStatus get status => _status;
  Profile? get profile => _profile;
  String? get pendingEmail => _pendingEmail;
  String? get error => _error;
  bool get busy => _busy;

  // ---- Auth state stream ----
  Future<void> _onAuthState(AuthState state) async {
    switch (state.event) {
      case AuthChangeEvent.initialSession:
        if (state.session == null) {
          _set(AuthStatus.unauthenticated);
        } else {
          await _loadProfileAndRoute();
        }
        break;
      case AuthChangeEvent.signedIn:
        await _loadProfileAndRoute();
        break;
      case AuthChangeEvent.signedOut:
        _profile = null;
        _set(AuthStatus.unauthenticated);
        break;
      default:
        break;
    }
  }

  Future<void> _loadProfileAndRoute() async {
    final uid = _repo.currentUser?.id;
    if (uid == null) {
      _set(AuthStatus.unauthenticated);
      return;
    }
    try {
      var profile = await _repo.fetchProfile(uid);
      // The signup trigger creates the row; guard a tiny race with one retry.
      if (profile == null) {
        await Future.delayed(const Duration(milliseconds: 400));
        profile = await _repo.fetchProfile(uid);
      }
      _profile = profile;
      if (profile == null || profile.isPlaceholder) {
        _set(AuthStatus.needsUsername);
      } else {
        _set(AuthStatus.authenticated);
        unawaited(CallService.onUserLogin(uid, profile.displayName));
      }
    } catch (_) {
      // Transient load failure for a user who has a valid session: let them
      // into the app rather than forcing the onboarding screen (which would
      // overwrite an existing profile). Onboarding only triggers on a
      // SUCCESSFUL fetch that returns null / a placeholder profile.
      _set(AuthStatus.authenticated);
      final id = _repo.currentUser?.id;
      if (id != null) {
        unawaited(CallService.onUserLogin(id, _profile?.displayName ?? ''));
      }
    }
  }

  // ---- Actions ----
  Future<void> signUp(String email, String password) async {
    _begin();
    try {
      final res = await _repo.signUp(email: email.trim(), password: password);
      if (res.session == null) {
        // "Confirm email" is ON → no session until verified.
        _pendingEmail = email.trim();
        _set(AuthStatus.awaitingVerification);
      } else {
        // Session already exists → route now (idempotent if signedIn also fires).
        await _loadProfileAndRoute();
      }
    } on AuthException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Sign up failed. Please try again.';
    } finally {
      _end();
    }
  }

  Future<void> signIn(String email, String password) async {
    _begin();
    try {
      await _repo.signIn(email: email.trim(), password: password);
      // signedIn event routes via _onAuthState.
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('not confirmed') || msg.contains('email not confirmed')) {
        _pendingEmail = email.trim();
        _set(AuthStatus.awaitingVerification);
      } else {
        _error = e.message;
      }
    } catch (_) {
      _error = 'Login failed. Please try again.';
    } finally {
      _end();
    }
  }

  Future<void> resendVerification() async {
    if (_pendingEmail == null) return;
    _begin();
    try {
      await _repo.resendSignupEmail(_pendingEmail!);
    } on AuthException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not resend the email. Try again shortly.';
    } finally {
      _end();
    }
  }

  /// Returns true on success.
  Future<bool> completeOnboarding(String username, String displayName) async {
    final uid = _repo.currentUser?.id;
    if (uid == null) return false;
    _begin();
    try {
      final handle = username.trim().toLowerCase();
      final available = await _repo.isUsernameAvailable(handle, uid);
      if (!available) {
        _error = 'That @username is already taken';
        return false;
      }
      _profile = await _repo.completeProfile(
        userId: uid,
        username: handle,
        displayName: displayName.trim(),
      );
      _set(AuthStatus.authenticated);
      unawaited(CallService.onUserLogin(uid, _profile!.displayName));
      return true;
    } on PostgrestException catch (e) {
      _error = e.code == '23505'
          ? 'That @username is already taken'
          : (e.message);
      return false;
    } catch (_) {
      _error = 'Could not save your profile. Try again.';
      return false;
    } finally {
      _end();
    }
  }

  /// Saves edits from the Edit Profile screen. Pass [avatarUrl] only when a new
  /// photo was uploaded. Returns true on success; sets [error] otherwise.
  Future<bool> saveProfile({
    required String displayName,
    required String username,
    required String statusLine,
    String? bio,
    List<String>? interests,
    String? avatarUrl,
  }) async {
    final uid = _repo.currentUser?.id;
    if (uid == null) return false;
    _begin();
    try {
      final handle = username.trim().toLowerCase();
      if (_profile == null || handle != _profile!.username) {
        final available = await _repo.isUsernameAvailable(handle, uid);
        if (!available) {
          _error = 'That @username is already taken';
          return false;
        }
      }
      _profile = await _repo.updateProfile(
        userId: uid,
        displayName: displayName.trim(),
        username: handle,
        statusLine: statusLine.trim(),
        bio: bio?.trim(),
        interests: interests,
        avatarUrl: avatarUrl,
      );
      return true;
    } on PostgrestException catch (e) {
      _error = e.code == '23505'
          ? 'That @username is already taken'
          : e.message;
      return false;
    } catch (_) {
      _error = 'Could not save your profile. Try again.';
      return false;
    } finally {
      _end();
    }
  }

  void backToLogin() {
    _pendingEmail = null;
    _error = null;
    _set(AuthStatus.unauthenticated);
  }

  Future<void> signOut() async {
    _begin();
    try {
      await PushService.unregister(); // drop the token while still authenticated
      await CallService.onUserLogout();
      await _repo.signOut();
    } finally {
      _end();
    }
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  // ---- helpers ----
  void _begin() {
    _busy = true;
    _error = null;
    notifyListeners();
  }

  void _end() {
    _busy = false;
    notifyListeners();
  }

  void _set(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
