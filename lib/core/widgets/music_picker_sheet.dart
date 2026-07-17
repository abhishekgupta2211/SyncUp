import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/music_service.dart';

class MusicPickerSheet extends StatefulWidget {
  const MusicPickerSheet({super.key});

  @override
  State<MusicPickerSheet> createState() => _MusicPickerSheetState();
}

class _MusicPickerSheetState extends State<MusicPickerSheet> {
  String _query = '';
  late List<Song> _songs;

  @override
  void initState() {
    super.initState();
    _songs = MusicService.getTrendingSongs();
  }

  void _onSearch(String q) {
    setState(() {
      _query = q;
      _songs = MusicService.searchSongs(q);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              SizedBox(height: 12.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.r),
                child: TextField(
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'Search music...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _songs.length,
                  itemBuilder: (context, i) {
                    final song = _songs[i];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Image.network(song.coverUrl, width: 48.r, height: 48.r, fit: BoxFit.cover),
                      ),
                      title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(song.artist),
                      trailing: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
                      onTap: () => Navigator.pop(context, song),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
