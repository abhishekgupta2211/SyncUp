import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/location_service.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../auth/data/providers/auth_provider.dart';

class LiveRidePage extends StatefulWidget {
  const LiveRidePage({super.key, required this.rideData});
  final Map<String, dynamic> rideData;

  @override
  State<LiveRidePage> createState() => _LiveRidePageState();
}

class _LiveRidePageState extends State<LiveRidePage> {
  bool _isPaused = false;
  double _speed = 0.0;
  double _distance = 0.0;
  int _seconds = 0;
  Timer? _elapsedTimer;
  Position? _lastPos;
  StreamSubscription<Position>? _posSub;
  GoogleMapController? _mapController;
  final List<LatLng> _path = [];
  RealtimeChannel? _rideChannel;
  final Map<String, Marker> _riderMarkers = {};

  @override
  void initState() {
    super.initState();
    _startRealTracking();
    _initRideChannel();
    _startTimer();
  }

  void _startTimer() {
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && mounted) {
        setState(() => _seconds++);
      }
    });
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _initRideChannel() {
    final rideId = widget.rideData['id'];
    if (rideId == null) return;
    
    _rideChannel = SupabaseService.client.channel('ride:$rideId');
    _rideChannel!.onBroadcast(
      event: 'location_update',
      callback: (payload) {
        final uid = payload['user_id'] as String;
        if (uid == SupabaseService.currentUserId) return;
        
        final lat = payload['lat'] as double;
        final lng = payload['lng'] as double;
        
        setState(() {
          _riderMarkers[uid] = Marker(
            markerId: MarkerId(uid),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: const InfoWindow(title: 'Fellow Rider'),
          );
        });
      },
    );
    _rideChannel!.subscribe();
  }

  void _startRealTracking() {
    _posSub = LocationService.getLocationStream().listen((pos) {
      if (!_isPaused && mounted) {
        // Broadcast location to group
        _rideChannel?.sendBroadcastMessage(
          event: 'location_update',
          payload: {
            'user_id': SupabaseService.currentUserId,
            'lat': pos.latitude,
            'lng': pos.longitude,
            'speed': pos.speed * 3.6,
          },
        );

        setState(() {
          _speed = pos.speed * 3.6; // Real speed from GPS
          
          if (_lastPos != null) {
            final d = Geolocator.distanceBetween(
              _lastPos!.latitude, _lastPos!.longitude,
              pos.latitude, pos.longitude
            );
            if (d > 2.0) { // filter out GPS jitter
               _distance += d / 1000.0;
            }
          }
          _lastPos = pos;
          _path.add(LatLng(pos.latitude, pos.longitude));

          _mapController?.animateCamera(
            CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude))
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _elapsedTimer?.cancel();
    _rideChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.rideData['title'] ?? 'Riding...';
    final destination = widget.rideData['destination']?['name'] ?? 'Destination';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: LatLng(19.076, 72.877), zoom: 16),
            onMapCreated: (c) => _mapController = c,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _riderMarkers.values.toSet(),
            polylines: {
              Polyline(
                polylineId: const PolylineId('path'),
                points: _path,
                color: theme.colorScheme.primary,
                width: 5,
              ),
            },
            style: _darkMapStyle,
          ),

          Positioned(
            top: 50.h,
            left: 16.w,
            right: 16.w,
            child: Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.navigation_rounded, color: theme.colorScheme.primary, size: 28.r),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                        Text('Goal: $destination', style: TextStyle(color: Colors.white60, fontSize: 11.sp)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 40.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
                boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _stat('SPEED', _speed.toStringAsFixed(0), 'KM/H', theme),
                      _stat('DISTANCE', _distance.toStringAsFixed(2), 'KM', theme),
                      _stat('ELAPSED', _formatTime(_seconds), 'MIN', theme),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      Expanded(
                        child: _btn(
                          label: _isPaused ? 'RESUME' : 'PAUSE',
                          icon: _isPaused ? Icons.play_arrow : Icons.pause,
                          color: _isPaused ? Colors.green : Colors.orange,
                          onTap: () => setState(() => _isPaused = !_isPaused),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: _btn(
                          label: 'FINISH',
                          icon: Icons.stop_rounded,
                          color: AppColors.danger,
                          onTap: () => _finish(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String val, String unit, ThemeData theme) {
    final isSpeeding = label == 'SPEED' && double.parse(val) > 80.0;
    return Column(
      children: [
        Text(label, style: TextStyle(color: isSpeeding ? Colors.red : Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(val, style: TextStyle(color: isSpeeding ? Colors.red : Colors.white, fontSize: 24.sp, fontWeight: FontWeight.w900)),
            SizedBox(width: 2.w),
            Text(unit, style: TextStyle(color: isSpeeding ? Colors.red : Colors.white38, fontSize: 8.sp)),
          ],
        ),
      ],
    );
  }

  Widget _btn({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 18.r),
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }

  Future<void> _finish(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final auth = context.read<AuthProvider>();
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      await SupabaseService.client.rpc('increment_rider_stats', params: {'p_km': _distance});
      await auth.loadProfile();
      if (mounted) {
        nav.pop(); // close loader
        nav.pop(); // exit ride
        
        final share = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Share your Ride?'),
            content: Text('Awesome job! Would you like to share your ${(_distance).toStringAsFixed(1)} KM ride to the community?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('NOT NOW')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('SHARE')),
            ],
          ),
        );

        if (share == true && mounted) {
           // Logic to create a community post with ride stats
           await SupabaseService.client.from('posts').insert({
             'author_id': SupabaseService.currentUserId,
             'text': 'Just completed a ride! Covered ${_distance.toStringAsFixed(2)} KM in ${title}. 🏍️🔥 #RevvRide #BikerLife',
           });
           messenger.showSnackBar(const SnackBar(content: Text('Ride shared to community! 🚀')));
        } else {
           messenger.showSnackBar(SnackBar(content: Text('Ride Finished! Saved ${_distance.toStringAsFixed(2)} KM.')));
        }
      }
    } catch (_) {
      if (mounted) nav.pop();
    }
  }

  static const String _darkMapStyle = '[{"elementType":"geometry","stylers":[{"color":"#212121"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#303030"}]}]';
}
