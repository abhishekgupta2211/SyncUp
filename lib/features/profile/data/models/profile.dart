/// Maps to the `public.profiles` table.
class Profile {
  final String id;
  final String username;
  final String displayName;
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final String statusLine;
  final String? bio;
  final List<String> interests;
  final bool isVerified;
  final bool isVip;
  final String? moodEmoji;
  final String? moodText;
  final int social_level;
  final int xp_points;
  final String? theme_song_name;
  final String? theme_song_artist;
  final String? theme_song_url;
  final String? theme_song_cover;
  final DateTime? lastSeen;
  final bool isOnline;

  const Profile({
    required this.id,
    required this.username,
    required this.displayName,
    this.phone,
    this.email,
    this.avatarUrl,
    this.statusLine = 'Hey there! I am using LoveChat 💗',
    this.bio,
    this.interests = const [],
    this.isVerified = false,
    this.isVip = false,
    this.moodEmoji,
    this.moodText,
    this.social_level = 1,
    this.xp_points = 0,
    this.theme_song_name,
    this.theme_song_artist,
    this.theme_song_url,
    this.theme_song_cover,
    this.lastSeen,
    this.isOnline = false,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      username: (map['username'] ?? '') as String,
      displayName: (map['display_name'] ?? '') as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      statusLine: (map['status_line'] ?? 'Hey there! I am using LoveChat 💗')
          as String,
      bio: map['bio'] as String?,
      interests: List<String>.from(map['interests'] ?? []),
      isVerified: (map['is_verified'] ?? false) as bool,
      isVip: (map['is_vip'] ?? false) as bool,
      moodEmoji: map['mood_emoji'] as String?,
      moodText: map['mood_text'] as String?,
      social_level: (map['social_level'] as num?)?.toInt() ?? 1,
      xp_points: (map['xp_points'] as num?)?.toInt() ?? 0,
      theme_song_name: map['theme_song_name'] as String?,
      theme_song_artist: map['theme_song_artist'] as String?,
      theme_song_url: map['theme_song_url'] as String?,
      theme_song_cover: map['theme_song_cover'] as String?,
      lastSeen: map['last_seen'] == null
          ? null
          : DateTime.tryParse(map['last_seen'].toString()),
      isOnline: (map['is_online'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        'phone': phone,
        'email': email,
        'avatar_url': avatarUrl,
        'status_line': statusLine,
        'bio': bio,
        'interests': interests,
        'is_verified': isVerified,
        'is_vip': isVip,
        'mood_emoji': moodEmoji,
        'mood_text': moodText,
        'social_level': social_level,
        'xp_points': xp_points,
        'theme_song_name': theme_song_name,
        'theme_song_artist': theme_song_artist,
        'theme_song_url': theme_song_url,
        'theme_song_cover': theme_song_cover,
      };

  bool get isPlaceholder =>
      id.length >= 8 && username == 'user_${id.substring(0, 8)}';

  String get atUsername => '@$username';

  Profile copyWith({
    String? username,
    String? displayName,
    String? phone,
    String? avatarUrl,
    String? statusLine,
    String? bio,
    List<String>? interests,
    bool? isVerified,
    bool? isVip,
    String? moodEmoji,
    String? moodText,
    int? social_level,
    int? xp_points,
    String? theme_song_name,
    String? theme_song_artist,
    String? theme_song_url,
    String? theme_song_cover,
    DateTime? lastSeen,
    bool? isOnline,
  }) {
    return Profile(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      email: email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      statusLine: statusLine ?? this.statusLine,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      isVerified: isVerified ?? this.isVerified,
      isVip: isVip ?? this.isVip,
      moodEmoji: moodEmoji ?? this.moodEmoji,
      moodText: moodText ?? this.moodText,
      social_level: social_level ?? this.social_level,
      xp_points: xp_points ?? this.xp_points,
      theme_song_name: theme_song_name ?? this.theme_song_name,
      theme_song_artist: theme_song_artist ?? this.theme_song_artist,
      theme_song_url: theme_song_url ?? this.theme_song_url,
      theme_song_cover: theme_song_cover ?? this.theme_song_cover,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
