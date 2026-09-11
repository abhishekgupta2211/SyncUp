import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/utils/chat_time.dart';
import '../../../../core/widgets/app_avatar.dart';

class ProfileVisitorsPage extends StatelessWidget {
  const ProfileVisitorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Visitors'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: SupabaseService.client
            .from('profile_views')
            .select('*, viewer:profiles(display_name, username, avatar_url, is_vip, is_verified)')
            .eq('profile_id', SupabaseService.currentUserId!)
            .order('viewed_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final views = snapshot.data as List;
          
          if (views.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.visibility_off_outlined, size: 64.r, color: theme.hintColor),
                  SizedBox(height: 16.h),
                  const Text('No visitors yet. Share your profile! 🚀'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.r),
            itemCount: views.length,
            itemBuilder: (context, i) {
              final v = views[i];
              final viewer = v['viewer'];
              return ListTile(
                contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                leading: AppAvatar(
                  name: viewer['display_name'],
                  avatarUrl: viewer['avatar_url'],
                  radius: 24.r,
                  isVip: viewer['is_vip'] ?? false,
                ),
                title: Text(viewer['display_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('@${viewer['username']} · ${ChatTime.listLabel(DateTime.parse(v['viewed_at'].toString()))}'),
                trailing: const Icon(Icons.chevron_right, size: 16),
              );
            },
          );
        },
      ),
    );
  }
}
