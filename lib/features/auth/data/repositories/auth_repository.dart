import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_refs.dart';
import '../../../profile/data/models/profile.dart';

/// Wraps Supabase Auth + the `profiles` table for the auth feature.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signInWithMagicLink(String email) {
    return _client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: 'io.supabase.lovechat://login-callback/',
    );
  }

  Future<AuthResponse> signInAnonymously() {
    return _client.auth.signInAnonymously();
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<Profile?> fetchProfile(String userId) async {
    final data = await _client
        .from(Tables.profiles)
        .select()
        .eq('id', userId)
        .maybeSingle();
    return data == null ? null : Profile.fromMap(data);
  }

  Future<bool> isUsernameAvailable(String username, String myId) async {
    final rows = await _client
        .from(Tables.profiles)
        .select('id')
        .eq('username', username)
        .neq('id', myId);
    return (rows as List).isEmpty;
  }

  /// Completes onboarding by writing the chosen handle to the (trigger-created)
  /// profile row. Returns the updated profile.
  Future<Profile> completeProfile({
    required String userId,
    required String username,
    required String displayName,
    String? ridingStyle,
    int experienceYears = 0,
  }) async {
    final updated = await _client
        .from(Tables.profiles)
        .upsert({
          'id': userId,
          'username': username,
          'display_name': displayName,
          'riding_style': ridingStyle,
          'experience_years': experienceYears,
        })
        .select()
        .single();
    return Profile.fromMap(updated);
  }

  /// Updates an existing profile (edit screen). Only [avatarUrl] is optional —
  /// pass null to keep the current photo. RLS allows id = auth.uid().
  Future<Profile> updateProfile({
    required String userId,
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
    final payload = <String, dynamic>{
      'display_name': displayName,
      'username': username,
      'status_line': statusLine,
      'bio': bio,
      'interests': interests,
      'theme_song_name': themeSongName,
      'theme_song_artist': themeSongArtist,
      'theme_song_url': themeSongUrl,
      'theme_song_cover': themeSongCover,
      'riding_style': ridingStyle,
      'experience_years': experienceYears,
      'blood_group': bloodGroup,
      'allergies': allergies,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
    };
    if (avatarUrl != null) payload['avatar_url'] = avatarUrl;
    final updated = await _client
        .from(Tables.profiles)
        .update(payload)
        .eq('id', userId)
        .select()
        .single();
    return Profile.fromMap(updated);
  }
}
