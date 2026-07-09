import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../../settings/presentation/pages/appearance_screen.dart';
import '../../../settings/presentation/pages/chat_settings_screen.dart';
import '../../../settings/presentation/pages/data_storage_screen.dart';
import '../../../settings/presentation/pages/help_screen.dart';
import '../../../settings/presentation/pages/notification_settings_screen.dart';
import '../../../settings/presentation/pages/privacy_settings_screen.dart';
import '../../data/models/profile.dart';
import 'edit_profile_screen.dart';

/// Profile tab — avatar, name, status line, and settings menu. Phase 0 shows a
/// placeholder identity; real profile data lands with auth (Phase 1).
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = context.watch<AuthProvider>().profile;
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.only(bottom: 24.h),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 4.h),
            child: Text(
              'Profile',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Center(
            child: GestureDetector(
              onTap:
                  profile == null ? null : () => _openEdit(context, profile),
              child: Stack(
                children: [
                  AppAvatar(
                    name: profile?.displayName ?? 'Your Name',
                    avatarUrl: profile?.avatarUrl,
                    radius: 52.r,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                      child: Icon(Icons.edit, size: 14.r, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (profile?.moodEmoji != null) ...[
            SizedBox(height: 8.h),
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(profile!.moodEmoji!, style: TextStyle(fontSize: 18.sp)),
                    if (profile.moodText != null) ...[
                      SizedBox(width: 6.w),
                      Text(profile.moodText!, style: theme.textTheme.labelMedium),
                    ],
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: 14.h),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profile?.displayName ?? 'Your Name',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (profile?.isVerified == true) ...[
                  SizedBox(width: 4.w),
                  Icon(Icons.verified, size: 18.r, color: Colors.blue),
                ],
                if (profile?.isVip == true) ...[
                  SizedBox(width: 4.w),
                  Icon(Icons.stars, size: 18.r, color: Colors.amber),
                ],
              ],
            ),
          ),
          if (profile != null) ...[
            SizedBox(height: 2.h),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    profile.atUsername,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (profile.isVip) ...[
                    SizedBox(width: 12.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 12.r, color: Colors.amber),
                          SizedBox(width: 4.w),
                          Text('1.2k Views', style: TextStyle(fontSize: 10.sp, color: Colors.amber, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          SizedBox(height: 6.h),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Text(
                profile?.statusLine ?? 'Hey there! I am using LoveChat 💗',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          if (profile?.bio != null && profile!.bio!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 32.w),
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                profile.bio!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
          if (profile?.interests != null && profile!.interests.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                alignment: WrapAlignment.center,
                children: profile.interests.map((interest) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      interest,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          SizedBox(height: 24.h),
          _MenuTile(
              icon: Icons.person_outline,
              label: 'Account',
              onTap: () {
                if (profile != null) _openEdit(context, profile);
              }),
          _MenuTile(
              icon: Icons.lock_outline,
              label: 'Privacy',
              onTap: () => _push(context, const PrivacySettingsScreen())),
          _MenuTile(
              icon: Icons.notifications_none,
              label: 'Notifications',
              onTap: () => _push(context, const NotificationSettingsScreen())),
          _MenuTile(
              icon: Icons.chat_bubble_outline,
              label: 'Chat Settings',
              onTap: () => _push(context, const ChatSettingsScreen())),
          _MenuTile(
              icon: Icons.data_usage_outlined,
              label: 'Data and Storage',
              onTap: () => _push(context, const DataStorageScreen())),
          _MenuTile(
              icon: Icons.palette_outlined,
              label: 'Appearance',
              onTap: () => _push(context, const AppearanceScreen())),
          _MenuTile(
              icon: Icons.help_outline,
              label: 'Help & Support',
              onTap: () => _push(context, const HelpScreen())),
          SizedBox(height: 8.h),
          ListTile(
            onTap: () => _confirmSignOut(context),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 20.w, vertical: 2.h),
            leading: Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.logout, size: 20.r, color: AppColors.danger),
            ),
            title: Text(
              'Log out',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _openEdit(BuildContext context, Profile profile) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile)),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can log back in any time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().signOut();
    }
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 2.h),
      leading: Container(
        width: 40.r,
        height: 40.r,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, size: 20.r, color: theme.colorScheme.primary),
      ),
      title: Text(label, style: theme.textTheme.bodyLarge),
      trailing: Icon(Icons.chevron_right,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
    );
  }
}
