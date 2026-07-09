/// One row of call history (derived for the current viewer).
class CallLog {
  final String id;
  final String peerId;
  final String peerName;
  final String? peerAvatarUrl;
  final String type; // 'voice' | 'video'
  final bool outgoing; // caller == me
  final bool missed;
  final DateTime startedAt;

  const CallLog({
    required this.id,
    required this.peerId,
    required this.peerName,
    this.peerAvatarUrl,
    required this.type,
    required this.outgoing,
    required this.missed,
    required this.startedAt,
  });

  bool get isVideo => type == 'video';
}
