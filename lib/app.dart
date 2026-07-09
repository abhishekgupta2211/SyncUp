import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'core/calls/call_service.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/presentation/pages/auth_gate.dart';
import 'routes.dart';

class LoveChatApp extends StatelessWidget {
  const LoveChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: AppConfig.designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return MaterialApp(
              title: AppConfig.appName,
              navigatorKey: CallService.navigatorKey,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(themeProvider.accent),
              darkTheme: AppTheme.dark(themeProvider.accent),
              themeMode: themeProvider.mode,
              home: const AuthGate(),
              routes: Routes.table,
              onGenerateRoute: Routes.onGenerateRoute,
              onUnknownRoute: Routes.onUnknownRoute,
            );
          },
        );
      },
    );
  }
}
