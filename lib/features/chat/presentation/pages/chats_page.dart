import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../../notifications/presentation/widgets/notifications_bell.dart';
import 'live_ride_page.dart';
import 'plan_ride_page.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  List<dynamic> _upcomingRides = [];
  List<dynamic> _allRides = [];
  bool _loadingRides = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRealRides();
  }

  Future<void> _fetchRealRides() async {
    try {
      final res = await SupabaseService.client
          .from('rides')
          .select('*, profiles:organizer_id(display_name, avatar_url)')
          .eq('status', 'upcoming')
          .order('start_at', ascending: true);
      if (mounted) {
        setState(() { 
          _allRides = res;
          _upcomingRides = res.take(5).toList(); 
          _loadingRides = false; 
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingRides = false);
    }
  }

  void _onSearch(String q) {
    setState(() {
      if (q.isEmpty) {
        _upcomingRides = _allRides.take(5).toList();
      } else {
        _upcomingRides = _allRides.where((r) => 
          r['title'].toString().toLowerCase().contains(q.toLowerCase())
        ).toList();
      }
    });
  }

  void _startRide(Map<String, dynamic> ride) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('SAFETY CHECK 🛡️'),
        content: const Text('Are you wearing your helmet and protective gear? Safety is our priority.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('WAIT')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('READY TO RIDE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LiveRidePage(rideData: ride)),
    ).then((_) => _fetchRealRides());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = context.watch<AuthProvider>().profile;
    final name = profile?.displayName ?? 'Rider';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchRealRides,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 12.h, 12.w, 8.h),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ready to Roll,', style: theme.textTheme.labelLarge?.copyWith(color: Colors.white60)),
                          Text(name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
                        ],
                      ),
                      const Spacer(),
                      const NotificationsBell(),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  child: Row(
                    children: [
                      _QuickAction(
                        label: 'PLAN RIDE',
                        icon: Icons.add_location_alt_rounded,
                        color: theme.colorScheme.primary,
                        onTap: () async {
                          final newRide = await Navigator.of(context).push<Map<String, dynamic>>(
                            MaterialPageRoute(builder: (_) => const PlanRidePage()),
                          );
                          if (newRide != null) {
                            _fetchRealRides();
                            _startRide(newRide);
                          }
                        },
                      ),
                      SizedBox(width: 12.w),
                      _QuickAction(
                        label: 'START LATEST',
                        icon: Icons.play_arrow_rounded,
                        color: Colors.green,
                        onTap: () {
                          if (_upcomingRides.isNotEmpty) {
                            _startRide(_upcomingRides.first);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No upcoming rides found. Plan one first!')));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearch,
                    decoration: InputDecoration(
                      hintText: 'Search rides...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r)),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)]),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wb_cloudy_rounded, color: Colors.white, size: 40),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('WEATHER AT YOUR LOCATION', style: TextStyle(color: Colors.white70, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                              const Text('Cloudy • 22°C', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                              Text('Perfect for a long cruise! 🏍️', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Icon(Icons.water_drop, color: Colors.white70, size: 14),
                            Text('12%', style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 20.h)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatusCard(
                          title: 'TOTAL KM',
                          value: profile?.totalDistanceKm.toStringAsFixed(1) ?? '0.0',
                          icon: Icons.route_rounded,
                          color: Colors.blueAccent,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _StatusCard(
                          title: 'RIDES',
                          value: '${profile?.totalRides ?? 0}',
                          icon: Icons.motorcycle_rounded,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 12.h),
                  child: Text('MY UPCOMING RIDES', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ),
              ),

              if (_loadingRides)
                const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
              else if (_upcomingRides.isEmpty)
                const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No rides planned yet.', style: TextStyle(color: Colors.white38)))))
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final ride = _upcomingRides[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 12.h),
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: theme.dividerColor)),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 20, color: Colors.white24),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ride['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('To: ${ride['destination']?['name'] ?? 'Dest'}', style: theme.textTheme.labelSmall),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _startRide(ride),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, visualDensity: VisualDensity.compact),
                                child: const Text('START', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: _upcomingRides.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.label, required this.icon, required this.color, required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16.r)),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 28.r),
              SizedBox(height: 8.h),
              Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11.sp)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.title, required this.value, required this.icon, required this.color});
  final String title, value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: theme.dividerColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20.r),
          SizedBox(height: 12.h),
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
          Text(title, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
