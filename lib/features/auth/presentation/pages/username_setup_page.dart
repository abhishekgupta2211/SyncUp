import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../data/providers/auth_provider.dart';

/// Forced after first signup/login: pick a display name + unique @username.
class UsernameSetupPage extends StatefulWidget {
  const UsernameSetupPage({super.key});

  @override
  State<UsernameSetupPage> createState() => _UsernameSetupPageState();
}

class _UsernameSetupPageState extends State<UsernameSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final ok = await context
        .read<AuthProvider>()
        .completeOnboarding(_username.text, _name.text);
    if (!ok && mounted) {
      // error is shown inline via the provider
      _formKey.currentState!.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Set up your profile',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Choose how others find and see you on LoveChat.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                SizedBox(height: 28.h),
                Text('Display name',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Abhishek Gupta',
                    prefixIcon: Icon(Icons.badge_outlined, size: 20),
                  ),
                  validator: Validators.displayName,
                ),
                SizedBox(height: 18.h),
                Text('Username',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _username,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                    LengthLimitingTextInputFormatter(30),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'username',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(left: 14, right: 6),
                      child: Text('@',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                    prefixIconConstraints:
                        BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                  validator: Validators.username,
                ),
                SizedBox(height: 6.h),
                Text(
                  'a–z, 0–9 and underscore. This is unique and permanent-ish.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                if (auth.error != null) ...[
                  SizedBox(height: 14.h),
                  Text(
                    auth.error!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                ],
                SizedBox(height: 28.h),
                GradientButton(
                  label: 'Continue',
                  loading: auth.busy,
                  onPressed: auth.busy ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
