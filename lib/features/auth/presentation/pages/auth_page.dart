import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/validators.dart';
import '../../data/providers/auth_provider.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    
    final auth = context.read<AuthProvider>();
    final success = await auth.requestMagicLink(_email.text);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ignition link sent to your email! 🚀')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Stack(
        children: [
          const _AuthBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                child: _glassCard(theme, auth)
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(
                        begin: 0.08,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOut),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard(ThemeData theme, AuthProvider auth) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(32.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 80.r,
                    height: 80.r,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Icon(Icons.motorcycle_rounded, size: 48.r, color: Colors.white),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Join RevvRide',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Enter your email to start your journey. No password needed! 🏁',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 32.h),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Email address',
                    prefixIcon: Icon(Icons.alternate_email_rounded, color: Colors.white70),
                  ),
                  validator: Validators.email,
                ),
                if (auth.error != null) ...[
                  SizedBox(height: 16.h),
                  _ErrorBanner(message: auth.error!),
                ],
                SizedBox(height: 32.h),
                _ActionButton(
                  label: 'Start Engine',
                  loading: auth.busy,
                  onPressed: auth.busy ? null : _submit,
                ),
                SizedBox(height: 16.h),
                TextButton(
                  onPressed: auth.busy ? null : () => auth.signInGuest(),
                  child: Text(
                    'Explore as Guest',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 56.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        ),
        child: loading
            ? SizedBox(
                width: 24.r,
                height: 24.r,
                child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              )
            : Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0C0C0C),
      child: Stack(
        children: [
          Positioned(
            top: -100.h,
            left: -100.w,
            child: _blob(const Color(0xFFFF5722), 400.r)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(
                    begin: 0,
                    end: 30.h,
                    duration: 5000.ms,
                    curve: Curves.easeInOut),
          ),
          Positioned(
            bottom: -80.h,
            right: -80.w,
            child: _blob(const Color(0xFF37474F), 350.r)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(
                    begin: 0,
                    end: -25.h,
                    duration: 6000.ms,
                    curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }

  Widget _blob(Color color, double size) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              color.withValues(alpha: 0.3),
              color.withValues(alpha: 0.0),
            ]),
          ),
        ),
      );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 20.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
