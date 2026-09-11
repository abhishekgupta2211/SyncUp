import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/calls/call_service.dart';
import 'core/presence/presence_provider.dart';
import 'core/push/push_service.dart';
import 'core/supabase/supabase_service.dart';
import 'core/theme/theme_provider.dart';
import 'features/ai/data/providers/ai_provider.dart';
import 'features/auth/data/providers/auth_provider.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/chat/data/providers/conversation_list_provider.dart';
import 'features/feed/data/providers/feed_provider.dart';
import 'features/games/data/providers/games_lobby_provider.dart';
import 'features/notifications/data/providers/notifications_provider.dart';
import 'features/settings/data/providers/settings_provider.dart';
import 'features/stories/data/providers/story_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock the whole app to portrait — no landscape layouts to overflow.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // No .env bundled — continue (Supabase/Zego features self-gate on keys).
  }
  await SupabaseService.initialize();
  await CallService.initApp();
  await PushService.init(); // no-ops until google-services.json is present

  final prefs = await SharedPreferences.getInstance();
  final themeProvider = ThemeProvider(prefs)..load();
  final settingsProvider = SettingsProvider(prefs);
  final authRepository = AuthRepository(SupabaseService.client);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        Provider<AuthRepository>.value(value: authRepository),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authRepository),
        ),
        ChangeNotifierProvider<PresenceProvider>(
          create: (_) => PresenceProvider(),
        ),
        ChangeNotifierProvider<StoryProvider>(
          create: (_) => StoryProvider(),
        ),
        ChangeNotifierProvider<NotificationsProvider>(
          create: (_) => NotificationsProvider(),
        ),
        ChangeNotifierProvider<GamesLobbyProvider>(
          create: (_) => GamesLobbyProvider(),
        ),
        ChangeNotifierProvider<FeedProvider>(
          create: (_) => FeedProvider(),
        ),
        ChangeNotifierProvider<AIProvider>(
          create: (_) => AIProvider(),
        ),
        ChangeNotifierProvider<ConversationListProvider>(
          create: (_) => ConversationListProvider(),
        ),
      ],
      child: const LoveChatApp(),
    ),
  );
}
