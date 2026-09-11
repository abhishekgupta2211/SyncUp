import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../data/models/profile.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = context.watch<AuthProvider>().profile;
    return Scaffold(
      appBar: AppBar(title: const Text('ACHIEVEMENTS')),
      body: profile == null 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: EdgeInsets.all(24.r),
            children: [
              _header(theme, profile),
              SizedBox(height: 32.h),
              Text('UNLOCKED BADGES', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              SizedBox(height: 16.h),
              _buildBadgesGrid(theme, profile),
              SizedBox(height: 32.h),
              Text('XP PROGRESS', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              SizedBox(height: 16.h),
              _xpProgress(theme, profile),
            ],
          ),
    );
  }

  Widget _header(ThemeData theme, Profile profile) {
    return Column(
      children: [
        Icon(Icons.emoji_events_rounded, size: 80.r, color: Colors.amber),
        SizedBox(height: 16.h),
        Text('Level ${profile.socialLevel} Rider', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        Text('${profile.xpPoints} Vibe Points', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBadgesGrid(ThemeData theme, Profile profile) {
    final km = profile.totalDistanceKm;
    final rides = profile.totalRides;

    final badges = [
      _BadgeItem(
        icon: Icons.stars,
        label: 'First Ride',
        description: 'Complete your first trip.',
        unlocked: rides >= 1,
        color: Colors.amber,
      ),
      _BadgeItem(
        icon: Icons.speed,
        label: 'Centurion',
        description: 'Ride for 100 KM.',
        unlocked: km >= 100,
        color: Colors.blue,
      ),
      _BadgeItem(
        icon: Icons.landscape,
        label: 'Vagabond',
        description: 'Ride for 1,000 KM.',
        unlocked: km >= 1000,
        color: Colors.purple,
      ),
      _BadgeItem(
        icon: Icons.verified_user,
        label: 'Veteran',
        description: '5+ years of experience.',
        unlocked: profile.experienceYears >= 5,
        color: Colors.green,
      ),
      _BadgeItem(
        icon: Icons.groups_rounded,
        label: 'Pack Member',
        description: 'Join a riding club.',
        unlocked: true,
        color: Colors.orange,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: badges.length,
      itemBuilder: (ctx, i) => _badgeCard(theme, badges[i]),
    );
  }

  Widget _badgeCard(ThemeData theme, _BadgeItem item) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: item.unlocked ? item.color.withValues(alpha: 0.5) : theme.dividerColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, size: 40.r, color: item.unlocked ? item.color : Colors.white10),
          SizedBox(height: 12.h),
          Text(item.label, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, color: item.unlocked ? Colors.white : Colors.white24)),
          SizedBox(height: 4.h),
          Text(item.description, textAlign: TextAlign.center, style: TextStyle(fontSize: 10.sp, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _xpProgress(ThemeData theme, Profile profile) {
    final progress = (profile.xpPoints % 1000) / 1000;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Level ${profile.socialLevel}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Level ${profile.socialLevel + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white38)),
            ],
          ),
          SizedBox(height: 12.h),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            color: theme.colorScheme.primary,
            minHeight: 8.h,
            borderRadius: BorderRadius.circular(10),
          ),
          SizedBox(height: 8.h),
          Text('${(progress * 100).toInt()}% to next level', style: TextStyle(fontSize: 11.sp, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _BadgeItem {
  final IconData icon;
  final String label;
  final String description;
  final bool unlocked;
  final Color color;
  _BadgeItem({required this.icon, required this.label, required this.description, required this.unlocked, required this.color});
}
