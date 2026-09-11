import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/validators.dart';
import '../../data/providers/auth_provider.dart';

/// Forced after first signup/login: pick a display name, @username, and riding style.
class UsernameSetupPage extends StatefulWidget {
  const UsernameSetupPage({super.key});

  @override
  State<UsernameSetupPage> createState() => _UsernameSetupPageState();
}

class _UsernameSetupPageState extends State<UsernameSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _experience = TextEditingController(text: '0');
  
  String _ridingStyle = 'City Rider';
  final List<String> _styles = [
    'City Rider',
    'Tourer',
    'Adventure Rider',
    'Sports Rider',
    'Cruiser',
    'Off-road Rider',
  ];

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _experience.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    
    final auth = context.read<AuthProvider>();
    final ok = await auth.completeOnboarding(
      username: _username.text,
      displayName: _name.text,
      ridingStyle: _ridingStyle,
      experienceYears: int.tryParse(_experience.text) ?? 0,
    );
    
    if (!ok && mounted) {
      _formKey.currentState!.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Final Prep for RevvRide 🏁',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Configure your rider profile to join the community.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                SizedBox(height: 32.h),
                
                _label(theme, 'Rider Name'),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Abhishek Gupta',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: Validators.displayName,
                ),
                SizedBox(height: 20.h),
                
                _label(theme, 'Unique Handle'),
                TextFormField(
                  controller: _username,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                    LengthLimitingTextInputFormatter(30),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'username',
                    prefixText: '@ ',
                    prefixStyle: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  validator: Validators.username,
                ),
                SizedBox(height: 24.h),
                
                _label(theme, 'Primary Motorcycle'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(hintText: 'Brand (e.g. Royal Enfield)', prefixIcon: Icon(Icons.stars_rounded)),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(hintText: 'Model (e.g. Himalayan)'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(theme, 'Experience (Years)'),
                          TextFormField(
                            controller: _experience,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              hintText: '0',
                              prefixIcon: Icon(Icons.history_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(theme, 'Riding Style'),
                          DropdownButtonFormField<String>(
                            initialValue: _ridingStyle,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            items: _styles.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14)))).toList(),
                            onChanged: (v) => setState(() => _ridingStyle = v!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                if (auth.error != null) ...[
                  SizedBox(height: 20.h),
                  Text(
                    auth.error!,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
                  ),
                ],
                
                SizedBox(height: 40.h),
                
                _SubmitButton(
                  label: 'Complete Setup',
                  loading: auth.busy,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(ThemeData theme, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, left: 4.w),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.label, required this.onPressed, this.loading = false});
  final String label;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 56.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: theme.colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        ),
        child: loading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                label.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
      ),
    );
  }
}
