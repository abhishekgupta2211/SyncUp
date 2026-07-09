import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Thin accessor around the global Supabase client.
class SupabaseService {
  SupabaseService._();

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      // The key in .env is the new `sb_publishable_...` format.
      publishableKey: Env.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get auth => client.auth;

  static String? get currentUserId => client.auth.currentUser?.id;

  static bool get isSignedIn => client.auth.currentUser != null;
}
