import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';

class LoungeListPage extends StatelessWidget {
  const LoungeListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riding Clubs'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: SupabaseService.client.from('lounges').select(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final lounges = snapshot.data as List;
          return ListView.builder(
            padding: EdgeInsets.all(16.r),
            itemCount: lounges.length,
            itemBuilder: (context, i) {
              final l = lounges[i];
              return Container(
                margin: EdgeInsets.only(bottom: 16.h, left: 16.w, right: 16.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16.r),
                  leading: Container(
                    width: 56.r,
                    height: 56.r,
                    decoration: BoxDecoration(
                      color: AppColors.asphalt,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    alignment: Alignment.center,
                    child: Text(l['icon'] ?? '🏍️', style: TextStyle(fontSize: 28.sp)),
                  ),
                  title: Text(
                    l['name'],
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    l['description'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: const Text(
                      'JOIN',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10),
                    ),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Welcome to ${l['name']} Club! 🏁'))
                    );
                  },
                ),
              ).animate().fadeIn(delay: (i * 100).ms).slideY(begin: 0.1, end: 0);
            },
          );
        },
      ),
    );
  }
}
