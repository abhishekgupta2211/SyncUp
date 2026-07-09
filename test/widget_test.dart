import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:lovechat/core/config/app_config.dart';
import 'package:lovechat/core/theme/app_colors.dart';
import 'package:lovechat/core/theme/app_theme.dart';
import 'package:lovechat/features/auth/presentation/pages/splash_page.dart';

void main() {
  testWidgets('Splash renders brand name and tagline', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          theme: AppTheme.dark(AppColors.pink),
          home: const SplashPage(),
        ),
      ),
    );
    // Advance past the splash's staggered entrance delays so flutter_animate's
    // delay timers fire before the tree is torn down (they are decorative).
    await tester.pump(const Duration(milliseconds: 1300));

    expect(find.text(AppConfig.appName), findsOneWidget);
    expect(find.text(AppConfig.tagline), findsOneWidget);
  });
}
