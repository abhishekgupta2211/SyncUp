import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/supabase/supabase_service.dart';

class RideRepository {
  final SupabaseClient _client;
  RideRepository(this._client);

  Future<List<Map<String, dynamic>>> fetchUpcomingRides() async {
    final res = await _client
        .from('rides')
        .select('*, profiles:organizer_id(display_name, avatar_url)')
        .eq('status', 'upcoming')
        .order('start_at', ascending: true);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> joinRide(String rideId) async {
    final userId = SupabaseService.currentUserId;
    await _client.from('ride_participants').upsert({
      'ride_id': rideId,
      'user_id': userId,
      'status': 'joined',
    });
  }

  Future<List<Map<String, dynamic>>> fetchParticipants(String rideId) async {
    final res = await _client
        .from('ride_participants')
        .select('*, profiles:user_id(display_name, avatar_url)')
        .eq('ride_id', rideId);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> updateRideStatus(String rideId, String status) async {
    await _client.from('rides').update({'status': status}).eq('id', rideId);
  }
}
