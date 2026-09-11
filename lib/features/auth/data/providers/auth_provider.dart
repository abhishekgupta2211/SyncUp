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

/// App-lifetime auth state. Drives the [AuthGate] routing.
/// Passwordless magic link version.
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
          await loadProfile();
        }
        break;
      case AuthChangeEvent.signedIn:
        await loadProfile();
        break;
      case AuthChangeEvent.signedOut:
        _profile = null;
        _set(AuthStatus.unauthenticated);
        break;
      default:
        break;
    }
  }

  Future<void> loadProfile() async {
    final uid = _repo.currentUser?.id;
    if (uid == null) {
      _set(AuthStatus.unauthenticated);
      return;
    }
    try {
      var profile = await _repo.fetchProfile(uid);
      if (profile == null) {
        await Future.delayed(const Duration(milliseconds: 500));
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
      _set(AuthStatus.authenticated);
    }
  }

  // ---- Actions ----
  Future<bool> requestMagicLink(String email) async {
    _begin();
    try {
      await _repo.signInWithMagicLink(email.trim());
      _pendingEmail = email.trim();
      _set(AuthStatus.awaitingVerification);
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Failed to send login link. Try again.';
      return false;
    } finally {
      _end();
    }
  }

  Future<void> signInGuest() async {
    _begin();
    try {
      await _repo.signInAnonymously();
      // _onAuthState will handle the rest
    } catch (e) {
      _error = e.toString();
    } finally {
      _end();
    }
  }

  Future<void> resendVerification() async {
    if (_pendingEmail == null) return;
    await requestMagicLink(_pendingEmail!);
  }

  /// Returns true on success.
  Future<bool> completeOnboarding({
    required String username,
    required String displayName,
    String? ridingStyle,
    int experienceYears = 0,
  }) async {
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
        ridingStyle: ridingStyle,
        experienceYears: experienceYears,
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

  Future<bool> saveProfile({
    required String displayName,
    required String username,
    required String statusLine,
    String? bio,
    List<String>? interests,
    String? themeSongName,
    String? themeSongArtist,
    String? themeSongUrl,
    String? themeSongCover,
    String? avatarUrl,
    String? ridingStyle,
    int? experienceYears,
    String? bloodGroup,
    String? allergies,
    String? emergencyContactName,
    String? emergencyContactPhone,
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
        themeSongName: themeSongName,
        themeSongArtist: themeSongArtist,
        themeSongUrl: themeSongUrl,
        themeSongCover: themeSongCover,
        avatarUrl: avatarUrl,
        ridingStyle: ridingStyle,
        experienceYears: experienceYears,
        bloodGroup: bloodGroup,
        allergies: allergies,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
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
      await PushService.unregister();
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
