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
  final int socialLevel;
  final int xpPoints;
  final String? themeSongName;
  final String? themeSongArtist;
  final String? themeSongUrl;
  final String? themeSongCover;
  
  // Rider specific extensions
  final String? ridingStyle;
  final int experienceYears;
  final double totalDistanceKm;
  final int totalRides;
  
  final String? bloodGroup;
  final String? allergies;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  
  final DateTime? lastSeen;
  final bool isOnline;

  const Profile({
    required this.id,
    required this.username,
    required this.displayName,
    this.phone,
    this.email,
    this.avatarUrl,
    this.statusLine = 'Ready to ride! 🏍️',
    this.bio,
    this.interests = const [],
    this.isVerified = false,
    this.isVip = false,
    this.moodEmoji,
    this.moodText,
    this.socialLevel = 1,
    this.xpPoints = 0,
    this.themeSongName,
    this.themeSongArtist,
    this.themeSongUrl,
    this.themeSongCover,
    this.ridingStyle,
    this.experienceYears = 0,
    this.totalDistanceKm = 0.0,
    this.totalRides = 0,
    this.bloodGroup,
    this.allergies,
    this.emergencyContactName,
    this.emergencyContactPhone,
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
      statusLine: (map['status_line'] ?? 'Ready to ride! 🏍️') as String,
      bio: map['bio'] as String?,
      interests: List<String>.from(map['interests'] ?? []),
      isVerified: (map['is_verified'] ?? false) as bool,
      isVip: (map['is_vip'] ?? false) as bool,
      moodEmoji: map['mood_emoji'] as String?,
      moodText: map['mood_text'] as String?,
      socialLevel: (map['social_level'] as num?)?.toInt() ?? 1,
      xpPoints: (map['xp_points'] as num?)?.toInt() ?? 0,
      themeSongName: map['theme_song_name'] as String?,
      themeSongArtist: map['theme_song_artist'] as String?,
      themeSongUrl: map['theme_song_url'] as String?,
      themeSongCover: map['theme_song_cover'] as String?,
      ridingStyle: map['riding_style'] as String?,
      experienceYears: (map['experience_years'] as num?)?.toInt() ?? 0,
      totalDistanceKm: (map['total_distance_km'] as num?)?.toDouble() ?? 0.0,
      totalRides: (map['total_rides'] as num?)?.toInt() ?? 0,
      bloodGroup: map['blood_group'] as String?,
      allergies: map['allergies'] as String?,
      emergencyContactName: map['emergency_contact_name'] as String?,
      emergencyContactPhone: map['emergency_contact_phone'] as String?,
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
        'social_level': socialLevel,
        'xp_points': xpPoints,
        'theme_song_name': themeSongName,
        'theme_song_artist': themeSongArtist,
        'theme_song_url': themeSongUrl,
        'theme_song_cover': themeSongCover,
        'riding_style': ridingStyle,
        'experience_years': experienceYears,
        'total_distance_km': totalDistanceKm,
        'total_rides': totalRides,
        'blood_group': bloodGroup,
        'allergies': allergies,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
      };

  bool get isPlaceholder =>
      id.length >= 8 && username == 'user_${id.substring(0, 8)}';

  String get atUsername => '@$username';

  int get nextLevelXP => (socialLevel + 1) * 1000;
  double get levelProgress => (xpPoints % 1000) / 1000;

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
    int? socialLevel,
    int? xpPoints,
    String? themeSongName,
    String? themeSongArtist,
    String? themeSongUrl,
    String? themeSongCover,
    String? ridingStyle,
    int? experienceYears,
    double? totalDistanceKm,
    int? totalRides,
    String? bloodGroup,
    String? allergies,
    String? emergencyContactName,
    String? emergencyContactPhone,
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
      socialLevel: socialLevel ?? this.socialLevel,
      xpPoints: xpPoints ?? this.xpPoints,
      themeSongName: themeSongName ?? this.themeSongName,
      themeSongArtist: themeSongArtist ?? this.themeSongArtist,
      themeSongUrl: themeSongUrl ?? this.themeSongUrl,
      themeSongCover: themeSongCover ?? this.themeSongCover,
      ridingStyle: ridingStyle ?? this.ridingStyle,
      experienceYears: experienceYears ?? this.experienceYears,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      totalRides: totalRides ?? this.totalRides,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
