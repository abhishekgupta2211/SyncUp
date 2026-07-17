class Song {
  final String id;
  final String title;
  final String artist;
  final String url;
  final String coverUrl;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.url,
    required this.coverUrl,
  });
}

class MusicService {
  static List<Song> getTrendingSongs() {
    return [
      Song(
        id: '1',
        title: 'Heeriye',
        artist: 'Arijit Singh',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        coverUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=music1',
      ),
      Song(
        id: '2',
        title: 'Stay',
        artist: 'The Kid LAROI & Justin Bieber',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        coverUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=music2',
      ),
      Song(
        id: '3',
        title: 'Blinding Lights',
        artist: 'The Weeknd',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        coverUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=music3',
      ),
      Song(
        id: '4',
        title: 'Pasoori',
        artist: 'Ali Sethi',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
        coverUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=music4',
      ),
    ];
  }

  static List<Song> searchSongs(String query) {
    final all = getTrendingSongs();
    if (query.isEmpty) return all;
    return all.where((s) => 
      s.title.toLowerCase().contains(query.toLowerCase()) || 
      s.artist.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}
