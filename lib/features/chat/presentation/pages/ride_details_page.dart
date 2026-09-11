import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/repositories/ride_repository.dart';

class RideDetailsPage extends StatefulWidget {
  final Map<String, dynamic>? rideData;
  const RideDetailsPage({super.key, this.rideData});

  @override
  State<RideDetailsPage> createState() => _RideDetailsPageState();
}

class _RideDetailsPageState extends State<RideDetailsPage> {
  final _repo = RideRepository(SupabaseService.client);
  bool _joining = false;
  List<dynamic> _participants = [];

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    if (widget.rideData?['id'] == null) return;
    try {
      final res = await _repo.fetchParticipants(widget.rideData!['id']);
      if (mounted) setState(() => _participants = res);
    } catch (_) {}
  }

  Future<void> _join() async {
    if (widget.rideData?['id'] == null) return;
    setState(() => _joining = true);
    try {
      await _repo.joinRide(widget.rideData!['id']);
      await _loadParticipants();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joined successfully! Pack is ready. 🏁')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.rideData?['title'] ?? 'MOUNTAIN PASS RUN';
    final organizer = widget.rideData?['profiles']?['display_name'] ?? 'Revv Rider';
    final date = widget.rideData?['start_at']?.toString().split('T')[0] ?? '2024-10-12';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220.h,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.asphalt,
                child: Center(
                  child: Icon(Icons.map_rounded, size: 80.r, color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                ),
              ),
              title: Text(title.toUpperCase(), style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(context, 'ORGANIZER', organizer, Icons.person_pin_rounded),
                  SizedBox(height: 20.h),
                  _infoRow(context, 'START DATE', date, Icons.calendar_month_rounded),
                  SizedBox(height: 20.h),
                  _infoRow(context, 'RIDE TYPE', (widget.rideData?['ride_type'] ?? 'public').toString().toUpperCase(), Icons.visibility_rounded),
                  
                  SizedBox(height: 32.h),
                  Text('RIDE STATS', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary, letterSpacing: 1)),
                  SizedBox(height: 16.h),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statCard(theme, 'EST. DISTANCE', '124 KM'),
                      _statCard(theme, 'DIFFICULTY', (widget.rideData?['difficulty'] ?? 'MODERATE').toString().toUpperCase()),
                    ],
                  ),

                  SizedBox(height: 32.h),
                  Text('PARTICIPANTS (${_participants.length})', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
                  SizedBox(height: 12.h),
                  if (_participants.isEmpty)
                    const Text('No riders joined yet.', style: TextStyle(color: Colors.white38))
                  else
                    SizedBox(
                      height: 50.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _participants.length,
                        itemBuilder: (ctx, i) {
                          final p = _participants[i]['profiles'];
                          return Padding(
                            padding: EdgeInsets.only(right: 12.w),
                            child: AppAvatar(name: p['display_name'], avatarUrl: p['avatar_url'], radius: 20.r),
                          );
                        },
                      ),
                    ),

                  SizedBox(height: 32.h),
                  Text('RIDE RULES', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
                  SizedBox(height: 12.h),
                  const Text('1. Full gear is mandatory.\n2. No speeding beyond 80 km/h.\n3. Stay with the group at all times.', style: TextStyle(color: Colors.white60, height: 1.6)),
                  
                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 40.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56.h,
          child: ElevatedButton(
            onPressed: _joining ? null : _join,
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r))),
            child: _joining 
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('JOIN THIS RIDE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20.r),
        ),
        SizedBox(width: 16.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: Colors.white38, fontWeight: FontWeight.w800)),
            Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _statCard(ThemeData theme, String label, String value) {
    return Container(
      width: 150.w,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10.sp, color: Colors.white38, fontWeight: FontWeight.bold)),
          SizedBox(height: 4.h),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ],
      ),
    );
  }
}
