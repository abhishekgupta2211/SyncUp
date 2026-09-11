import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';
import 'plan_ride_page.dart';
import 'live_ride_page.dart';
import '../../../settings/presentation/pages/safety_center_page.dart';

class RideManagementPage extends StatelessWidget {
  const RideManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RIDE CENTER'),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(20.r),
        children: [
          _buildHeroCard(context, theme),
          SizedBox(height: 24.h),
          _buildActionGrid(context, theme),
          SizedBox(height: 32.h),
          Text(
            'MY RIDE HISTORY',
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.2),
          ),
          SizedBox(height: 16.h),
          _buildHistoryList(context, theme),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, ThemeData theme) {
    return Container(
      height: 180.h,
      decoration: BoxDecoration(
        color: AppColors.asphalt,
        borderRadius: BorderRadius.circular(28.r),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1558981403-c5f91cbba527?q=80&w=1000&auto=format&fit=crop'),
          fit: BoxFit.cover,
          opacity: 0.4,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              'PUSH YOUR LIMITS',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 1),
            ),
            Text(
              'Every kilometer tells a story. Keep riding.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context, ThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16.r,
      crossAxisSpacing: 16.r,
      childAspectRatio: 1.1,
      children: [
        _ActionCard(
          title: 'START\nSOLO RIDE',
          icon: Icons.play_arrow_rounded,
          color: Colors.green,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LiveRidePage(rideData: const {'title': 'Solo Ride'}))),
        ),
        _ActionCard(
          title: 'PLAN\nGROUP RIDE',
          icon: Icons.add_location_alt_rounded,
          color: theme.colorScheme.primary,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlanRidePage())),
        ),
        _ActionCard(
          title: 'EXPLORE\nROUTES',
          icon: Icons.map_rounded,
          color: AppColors.asphalt,
          onTap: () {
            // This is a bit tricky from a stateless sub-page, but usually we can 
            // use a notification or a provider. For now, let's just show a snackbar
            // or navigate to a specialized routes list.
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use the "Explore" tab to discover real routes! 🧭')));
          },
        ),
        _ActionCard(
          title: 'SOS\nCENTER',
          icon: Icons.emergency_share_rounded,
          color: AppColors.danger,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SafetyCenterPage())),
        ),
      ],
    );
  }

  Widget _buildHistoryList(BuildContext context, ThemeData theme) {
    return FutureBuilder(
      future: SupabaseService.client
          .from('rides')
          .select()
          .eq('organizer_id', SupabaseService.currentUserId!)
          .order('start_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final history = snapshot.data as List;
        
        if (history.isEmpty) {
          return const Center(child: Text('No rides recorded yet.', style: TextStyle(color: Colors.white38)));
        }

        return Column(
          children: history.map((ride) => Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Icon(Icons.history_rounded, color: theme.colorScheme.primary),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ride['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(ride['start_at'].toString().split('T')[0], style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
                Text('COMPLETED', style: TextStyle(color: Colors.green, fontSize: 10.sp, fontWeight: FontWeight.bold)),
              ],
            ),
          )).toList(),
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.title, required this.icon, required this.color, required this.onTap});
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 32.r),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 13.sp, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
