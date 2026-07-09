import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../data/providers/auth_provider.dart';

/// Shown after signup when "Confirm email" is enabled in Supabase.
class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final email = auth.pendingEmail ?? 'your email';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: auth.busy ? null : () => auth.backToLogin(),
                ),
              ),
              const Spacer(),
              Container(
                width: 96.r,
                height: 96.r,
                decoration: BoxDecoration(
                  gradient: AppColors.pinkGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.pink.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(Icons.mark_email_read_outlined,
                    color: Colors.white, size: 44.r),
              ),
              SizedBox(height: 24.h),
              Text(
                'Verify your email',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 10.h),
              Text(
                'We sent a confirmation link to',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                email,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 14.h),
              Text(
                'Open the link to confirm, then log in to continue.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              if (auth.error != null) ...[
                SizedBox(height: 14.h),
                Text(
                  auth.error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ],
              const Spacer(),
              GradientButton(
                label: "I've verified — Log in",
                loading: auth.busy,
                onPressed: auth.busy ? null : () => auth.backToLogin(),
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: auth.busy ? null : () => auth.resendVerification(),
                child: Text(
                  'Resend email',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}
