import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../chat/data/providers/conversation_list_provider.dart';
import '../../../shell/presentation/pages/home_shell_page.dart';
import '../../data/providers/auth_provider.dart';
import 'auth_page.dart';
import 'splash_page.dart';
import 'username_setup_page.dart';
import 'verify_email_page.dart';

/// Routes to the correct screen based on [AuthProvider.status].
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    final Widget child = switch (status) {
      AuthStatus.initializing => const SplashPage(),
      AuthStatus.unauthenticated => const AuthPage(),
      AuthStatus.awaitingVerification => const VerifyEmailPage(),
      AuthStatus.needsUsername => const UsernameSetupPage(),
      AuthStatus.authenticated => ChangeNotifierProvider<ConversationListProvider>(
          create: (_) => ConversationListProvider(),
          child: const HomeShellPage(),
        ),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOut,
      child: KeyedSubtree(key: ValueKey(status), child: child),
    );
  }
}
