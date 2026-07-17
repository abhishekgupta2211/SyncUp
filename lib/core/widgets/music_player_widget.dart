import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';

class MusicPlayerWidget extends StatefulWidget {
  const MusicPlayerWidget({
    super.key,
    required this.songName,
    required this.artist,
    required this.url,
    required this.coverUrl,
  });

  final String songName;
  final String artist;
  final String url;
  final String coverUrl;

  @override
  State<MusicPlayerWidget> createState() => _MusicPlayerWidgetState();
}

class _MusicPlayerWidgetState extends State<MusicPlayerWidget> {
  final _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _player.setUrl(widget.url);
    } catch (_) {}
  }

  void _toggle() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
    if (mounted) setState(() => _isPlaying = _player.playing);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Image.network(widget.coverUrl, width: 44.r, height: 44.r, fit: BoxFit.cover),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.songName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(widget.artist, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          IconButton(
            onPressed: _toggle,
            icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, 
                       color: theme.colorScheme.primary, size: 32.r),
          ),
        ],
      ),
    );
  }
}
