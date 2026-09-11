import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../chat/presentation/pages/plan_ride_page.dart';

class RouteDetailsPage extends StatelessWidget {
  final Map<String, dynamic> route;
  const RouteDetailsPage({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = route['start_point'] as Map;
    final end = route['end_point'] as Map;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.h,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(start['lat'], start['lng']),
                  zoom: 10,
                ),
                liteModeEnabled: true,
                zoomControlsEnabled: false,
                markers: {
                  Marker(markerId: const MarkerId('start'), position: LatLng(start['lat'], start['lng']), infoWindow: InfoWindow(title: start['name'])),
                  Marker(markerId: const MarkerId('end'), position: LatLng(end['lat'], end['lng']), infoWindow: InfoWindow(title: end['name'])),
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _badge(route['category'] ?? 'Touring', theme.colorScheme.primary),
                      SizedBox(width: 8.w),
                      _badge(route['difficulty'].toString().toUpperCase(), Colors.orange),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    route['title'],
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    route['description'] ?? 'No description available for this route.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  SizedBox(height: 24.h),
                  _infoRow(Icons.route_rounded, 'Distance', '${route['distance_km']} KM'),
                  _infoRow(Icons.timer_rounded, 'Duration', '${route['duration_mins']} Mins'),
                  _infoRow(Icons.location_on_rounded, 'Start', start['name']),
                  _infoRow(Icons.flag_rounded, 'End', end['name']),
                  
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
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlanRidePage(initialRoute: route)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                child: const Text('PLAN RIDE WITH THIS ROUTE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.w900)),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          Icon(icon, size: 20.r, color: Colors.white38),
          SizedBox(width: 12.w),
          Text('$label: ', style: const TextStyle(color: Colors.white38)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
