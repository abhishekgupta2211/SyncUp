import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:geocoding/geocoding.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/location_service.dart';
import 'route_details_page.dart';

class StoriesPage extends StatefulWidget {
  const StoriesPage({super.key});

  @override
  State<StoriesPage> createState() => _StoriesPageState();
}

class _StoriesPageState extends State<StoriesPage> {
  // ignore: unused_field
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng? _myLocation;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    final pos = await LocationService.getCurrentLocation();
    if (pos != null) {
      _myLocation = LatLng(pos.latitude, pos.longitude);
    }
    
    await _fetchNearbyRiders();
    
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fetchNearbyRiders() async {
    try {
      final riders = await SupabaseService.client
          .from('profiles')
          .select('id, username, display_name, riding_style')
          .not('id', 'eq', SupabaseService.currentUserId);

      for (var r in riders) {
        if (_myLocation != null) {
          final lat = _myLocation!.latitude + (0.005 * (riders.indexOf(r) % 5));
          final lng = _myLocation!.longitude + (0.005 * (riders.indexOf(r) % 3));
          
          _markers.add(Marker(
            markerId: MarkerId(r['id']),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: r['display_name'], 
              snippet: r['riding_style'] ?? 'Rider',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          ));
        }
      }
    } catch (_) {}
  }

  final _searchController = TextEditingController();

  Future<void> _searchPlace(String query) async {
    if (query.isEmpty) return;
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty && mounted) {
        final loc = locations.first;
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(loc.latitude, loc.longitude), 14),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location not found.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNight = DateTime.now().hour > 18 || DateTime.now().hour < 6;

    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _myLocation ?? const LatLng(19.076, 72.877),
              zoom: 14,
            ),
            markers: _markers,
            myLocationEnabled: true,
            onMapCreated: (c) => _mapController = c,
            style: isNight ? _darkMapStyle : null,
          ),
          
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(30.r),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: _searchPlace,
                  decoration: const InputDecoration(
                    hintText: 'Search the map...',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
            ),
          ),

          _ExploreDiscoverySheet(),
        ],
      ),
    );
  }

  static const String _darkMapStyle = '[{"elementType":"geometry","stylers":[{"color":"#212121"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#303030"}]}]';
}

class _ExploreDiscoverySheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.15,
      maxChildSize: 0.8,
      builder: (ctx, scroll) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
        ),
        child: FutureBuilder(
          future: SupabaseService.client.from('discovery_routes').select(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final routes = snapshot.data as List;

            return ListView.builder(
              controller: scroll,
              padding: EdgeInsets.all(24.r),
              itemCount: routes.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)))),
                      SizedBox(height: 24.h),
                      Text('REAL DISCOVERED ROUTES', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                      SizedBox(height: 16.h),
                    ],
                  );
                }
                final r = routes[index - 1];
                return _RouteTile(route: r);
              },
            );
          },
        ),
      ),
    );
  }
}

class _RouteTile extends StatelessWidget {
  final dynamic route;
  const _RouteTile({required this.route});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RouteDetailsPage(route: route))),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColors.asphalt, 
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(route['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('${route['distance_km']} KM • ${route['difficulty'].toString().toUpperCase()}', 
                    style: TextStyle(color: theme.colorScheme.primary, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
