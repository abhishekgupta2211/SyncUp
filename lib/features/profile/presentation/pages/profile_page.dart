import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../../settings/presentation/pages/appearance_screen.dart';
import '../../../settings/presentation/pages/notification_settings_screen.dart';
import '../../../settings/presentation/pages/privacy_settings_screen.dart';
import '../../data/models/profile.dart';
import 'edit_profile_screen.dart';
import 'garage_page.dart';
import 'maintenance_page.dart';
import 'achievements_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = context.watch<AuthProvider>().profile;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // --- Modern Profile Header ---
          SliverAppBar(
            expandedHeight: 280.h,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Placeholder for cover image
                  Container(color: AppColors.asphalt),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24.h,
                    left: 20.w,
                    right: 20.w,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AppAvatar(
                          name: profile?.displayName ?? 'Rider',
                          avatarUrl: profile?.avatarUrl,
                          radius: 50.r,
                          isVip: profile?.isVip ?? false,
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    profile?.displayName ?? 'Rider Name',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  if (profile?.isVerified == true) ...[
                                    SizedBox(width: 6.w),
                                    const Icon(Icons.verified, size: 20, color: Colors.blueAccent),
                                  ],
                                ],
                              ),
                              Text(
                                profile?.atUsername ?? '@rider',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (profile?.ridingStyle != null) 
                                Text(
                                  '${profile!.ridingStyle} | ${profile.experienceYears}Y Exp',
                                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70),
                                ),
                            ],
                          ),
                        ),
                        IconButton.filled(
                          onPressed: () => _openEdit(context, profile!),
                          icon: const Icon(Icons.edit_rounded, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(label: 'RIDES', value: profile?.totalRides.toString() ?? '0'),
                  _StatItem(label: 'KM', value: profile?.totalDistanceKm.toStringAsFixed(1) ?? '0'),
                  _StatItem(label: 'XP', value: profile?.xpPoints.toString() ?? '0'),
                  _StatItem(label: 'LEVEL', value: profile?.socialLevel.toString() ?? '1'),
                ],
              ),
            ),
          ),
          
          // --- Achievements Badges ---
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: _buildBadges(profile),
            ),
          ),

          // --- Rider Bio ---
          if (profile?.bio != null && profile!.bio!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THE RIDER',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      profile.bio!,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),

          // --- Main Menu ---
          SliverToBoxAdapter(
            child: Column(
              children: [
                _MenuTile(
                  icon: Icons.motorcycle_rounded,
                  label: 'My Garage',
                  onTap: () => _push(context, const GaragePage()),
                ),
                _MenuTile(
                  icon: Icons.history_rounded,
                  label: 'Ride History',
                  onTap: () {},
                ),
                _MenuTile(
                  icon: Icons.build_circle_rounded,
                  label: 'Maintenance',
                  onTap: () => _push(context, const MaintenancePage()),
                ),
                _MenuTile(
                  icon: Icons.emoji_events_outlined,
                  label: 'Achievements',
                  onTap: () => _push(context, const AchievementsPage()),
                ),
                const Divider(),
                _MenuTile(
                  icon: Icons.lock_outline_rounded,
                  label: 'Privacy',
                  onTap: () => _push(context, const PrivacySettingsScreen()),
                ),
                _MenuTile(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifications',
                  onTap: () => _push(context, const NotificationSettingsScreen()),
                ),
                _MenuTile(
                  icon: Icons.palette_outlined,
                  label: 'Appearance',
                  onTap: () => _push(context, const AppearanceScreen()),
                ),
                SizedBox(height: 12.h),
                ListTile(
                  onTap: () => _confirmSignOut(context),
                  contentPadding: EdgeInsets.symmetric(horizontal: 24.w),
                  leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
                  title: Text(
                    'Logout',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadges(Profile? profile) {
    if (profile == null) return const SizedBox();
    final km = profile.totalDistanceKm;
    
    return Wrap(
      spacing: 8.w,
      children: [
        if (profile.totalRides >= 1) _badge(Icons.stars, 'First Ride', Colors.amber),
        if (km >= 100) _badge(Icons.speed, 'Centurion', Colors.blue),
        if (km >= 1000) _badge(Icons.landscape, 'Vagabond', Colors.purple),
        if (profile.experienceYears >= 5) _badge(Icons.verified_user, 'Veteran', Colors.green),
      ],
    );
  }

  Widget _badge(IconData icon, String label, Color color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
      backgroundColor: color.withValues(alpha: 0.6),
      padding: EdgeInsets.zero,
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
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to end your session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().signOut();
    }
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 4.h),
      leading: Container(
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, size: 22.r, color: theme.colorScheme.primary),
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
    );
  }
}
