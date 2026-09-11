import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import 'add_bike_page.dart';

class GaragePage extends StatefulWidget {
  const GaragePage({super.key});

  @override
  State<GaragePage> createState() => _GaragePageState();
}

class _GaragePageState extends State<GaragePage> {
  final _client = SupabaseService.client;
  List<dynamic> _bikes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchBikes();
  }

  Future<void> _fetchBikes() async {
    try {
      final res = await _client.from('bikes').select().eq('owner_id', SupabaseService.currentUserId!);
      if (mounted) setState(() { _bikes = res; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addBike() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddBikePage()),
    );
    if (result == true) _fetchBikes();
  }

  void _editBike(Map<String, dynamic> bike) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddBikePage(bike: bike)),
    );
    if (result == true) _fetchBikes();
  }

  void _deleteBike(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Bike?'),
        content: const Text('This will permanently remove this bike from your garage.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('REMOVE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await _client.from('bikes').delete().eq('id', id);
      _fetchBikes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Garage'),
        actions: [
          IconButton(onPressed: _addBike, icon: const Icon(Icons.add_circle_outline_rounded)),
        ],
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : _bikes.isEmpty 
          ? const EmptyState(
              icon: Icons.motorcycle_rounded, 
              title: 'Garage is Empty', 
              subtitle: 'Add your motorcycles to showcase them and track maintenance.',
            )
          : ListView.builder(
              padding: EdgeInsets.all(20.r),
              itemCount: _bikes.length,
              itemBuilder: (ctx, i) {
                final b = _bikes[i];
                return _BikeCard(
                  bike: b,
                  onEdit: () => _editBike(b),
                  onDelete: () => _deleteBike(b['id']),
                );
              },
            ),
    );
  }
}

class _BikeCard extends StatelessWidget {
  const _BikeCard({required this.bike, required this.onEdit, required this.onDelete});
  final dynamic bike;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: AppColors.asphalt,
        borderRadius: BorderRadius.circular(24.r),
        image: bike['image_url'] != null ? DecorationImage(
          image: NetworkImage(bike['image_url']),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.4), BlendMode.darken),
        ) : null,
      ),
      height: 200.h,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        bike['year'].toString(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const Spacer(),
                Text(
                  bike['nickname'] ?? '${bike['brand']} ${bike['model']}',
                  style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                ),
                Text(
                  '${bike['engine_cc']}cc • ${bike['odometer']} KM',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8.r)),
                  child: const Text('READY TO RIDE', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Positioned(
            top: 10.r,
            right: 10.r,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white70),
              onSelected: (val) {
                if (val == 'edit') onEdit();
                if (val == 'delete') onDelete();
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Bike')),
                const PopupMenuItem(value: 'delete', child: Text('Remove Bike', style: TextStyle(color: Colors.red))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
