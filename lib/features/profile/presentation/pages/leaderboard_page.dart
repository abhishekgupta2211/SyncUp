import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/widgets/app_avatar.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Vibes 🏆'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: SupabaseService.client.from('profiles').select().order('vibe_points', ascending: false).limit(20),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final topUsers = snapshot.data as List;
          return ListView.builder(
            padding: EdgeInsets.all(16.r),
            itemCount: topUsers.length,
            itemBuilder: (context, i) {
              final user = topUsers[i];
              final rank = i + 1;
              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: rank <= 3 ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20.r),
                  border: rank <= 3 ? Border.all(color: Colors.amber, width: 2) : null,
                ),
                child: Row(
                  children: [
                    Text('#$rank', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: rank <= 3 ? Colors.amber : null)),
                    SizedBox(width: 15.w),
                    AppAvatar(name: user['display_name'], avatarUrl: user['avatar_url'], radius: 24.r, isVip: user['is_vip'] ?? false),
                    SizedBox(width: 15.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['display_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('@${user['username']}', style: theme.textTheme.labelSmall),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        const Icon(Icons.bolt, color: Colors.pinkAccent, size: 16),
                        Text('${user['vibe_points']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
                      ],
                    ),
                  ],
                ),
              ).animate().slideY(begin: 0.2, end: 0, delay: (i * 50).ms).fadeIn();
            },
          );
        },
      ),
    );
  }
}
