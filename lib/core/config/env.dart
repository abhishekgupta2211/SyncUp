import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed access to `.env` values (loaded in `main` before `runApp`).
class Env {
  Env._();

  static String _v(String key) => (dotenv.env[key] ?? '').trim();

  static String get supabaseUrl => _v('SUPABASE_URL');
  static String get supabaseAnonKey => _v('SUPABASE_ANON_KEY');

  static int get zegoAppId => int.tryParse(_v('ZEGO_APP_ID')) ?? 0;
  static String get zegoAppSign => _v('ZEGO_APP_SIGN');

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
