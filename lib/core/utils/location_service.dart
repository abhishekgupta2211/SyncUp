import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  static Stream<Position> getLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  static LatLng posToLatLng(Position pos) => LatLng(pos.latitude, pos.longitude);

  static Future<void> sendEmergencyAlert(Position pos, String contactPhone) async {
    // This is a placeholder for the real SMS/Alert logic
    // In production, use 'url_launcher' or 'flutter_sms' to send the location link
    final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${pos.latitude},${pos.longitude}';
    debugPrint('EMERGENCY ALERT to $contactPhone: Rider in trouble at $googleMapsUrl');
  }
}
