import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/gradient_logo.dart';
import '../../data/providers/auth_provider.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLogin = true;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() => _isLogin = !_isLogin);
    context.read<AuthProvider>().clearError();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    if (_isLogin) {
      await auth.signIn(_email.text, _password.text);
    } else {
      await auth.signUp(_email.text, _password.text);
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
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
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
      borderRadius: BorderRadius.circular(28.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 26.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Center(child: GradientLogo(size: 72)),
                SizedBox(height: 18.h),
                Text(
                  _isLogin ? 'Welcome back' : 'Create your account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  _isLogin
                      ? 'Log in to continue to ${AppConfig.appName}'
                      : 'Sign up to start connecting',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 26.h),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    prefixIcon: Icon(Icons.alternate_email, size: 20),
                  ),
                  validator: Validators.email,
                ),
                SizedBox(height: 14.h),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: Validators.password,
                ),
                if (auth.error != null) ...[
                  SizedBox(height: 14.h),
                  _ErrorBanner(message: auth.error!),
                ],
                SizedBox(height: 24.h),
                GradientButton(
                  label: _isLogin ? 'Log in' : 'Sign up',
                  loading: auth.busy,
                  onPressed: auth.busy ? null : _submit,
                ),
                SizedBox(height: 18.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin
                          ? "Don't have an account? "
                          : 'Already have an account? ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13.sp,
                      ),
                    ),
                    GestureDetector(
                      onTap: auth.busy ? null : _toggleMode,
                      child: Text(
                        _isLogin ? 'Sign up' : 'Log in',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated gradient + floating blobs behind the auth card.
class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF241F52), Color(0xFF15133A), Color(0xFF0B0E24)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80.h,
            left: -70.w,
            child: _blob(const Color(0xFF6C63FF), 280.r)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(
                    begin: 0,
                    end: 24.h,
                    duration: 4000.ms,
                    curve: Curves.easeInOut),
          ),
          Positioned(
            bottom: -70.h,
            right: -60.w,
            child: _blob(const Color(0xFF3B82F6), 240.r)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(
                    begin: 0,
                    end: -22.h,
                    duration: 4600.ms,
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
              color.withValues(alpha: 0.45),
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
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 18.r),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
