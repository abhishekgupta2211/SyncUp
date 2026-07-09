import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/supabase/supabase_service.dart';

class LoungeListPage extends StatelessWidget {
  const LoungeListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Public Lounges'),
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
              return Card(
                margin: EdgeInsets.only(bottom: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                child: ListTile(
                  contentPadding: EdgeInsets.all(12.r),
                  leading: Text(l['icon'] ?? '💬', style: TextStyle(fontSize: 32.sp)),
                  title: Text(l['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(l['description'] ?? ''),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Logic to open Lounge Chat Room
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Entering ${l['name']}...'))
                    );
                  },
                ),
              ).animate().fadeIn(delay: (i * 100).ms).slideX(begin: 0.1, end: 0);
            },
          );
        },
      ),
    );
  }
}
