import 'package:flutter/material.dart';

import 'features/auth/presentation/pages/auth_gate.dart';

/// Named-route registry. Argument-carrying screens (chat thread, story viewer)
/// are pushed directly via MaterialPageRoute by their callers.
///
/// Anything that falls through routes back to [AuthGate] so the auth-scoped
/// providers (ConversationListProvider etc.) are always established.
class Routes {
  Routes._();

  static Map<String, WidgetBuilder> get table => {};

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) => null;

  static Route<dynamic> onUnknownRoute(RouteSettings settings) =>
      MaterialPageRoute(builder: (_) => const AuthGate());
}
