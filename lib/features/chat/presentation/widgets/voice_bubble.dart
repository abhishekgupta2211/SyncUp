import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/theme/chat_theme.dart';
import '../../data/models/message.dart';

/// Voice-note player: play/pause, progress, duration.
class VoiceMessageContent extends StatefulWidget {
  const VoiceMessageContent({
    super.key,
    required this.message,
    required this.mine,
  });

  final Message message;
  final bool mine;

  @override
  State<VoiceMessageContent> createState() => _VoiceMessageContentState();
}

class _VoiceMessageContentState extends State<VoiceMessageContent> {
  final _player = AudioPlayer();
  bool _ready = false;
  bool _loading = false;
  double _speed = 1.0;
  double _pitch = 1.0; // NEW
  Duration _position = Duration.zero;
  late Duration _total;

  @override
  void initState() {
    super.initState();
    final ms = int.tryParse(widget.message.message) ?? 0;
    _total = Duration(milliseconds: ms);
    _player.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.playerStateStream.listen((s) {
      if (!mounted) return;
      if (s.processingState == ProcessingState.completed) {
        _player.pause();
        _player.seek(Duration.zero);
      }
      setState(() {});
    });
  }

  Future<void> _toggle() async {
    if (!_ready) {
      setState(() => _loading = true);
      var loaded = false;
      try {
        final local = widget.message.localPath;
        if (local != null && File(local).existsSync()) {
          await _player.setFilePath(local);
          loaded = true;
        } else if (widget.message.mediaUrl != null) {
          await _player.setUrl(widget.message.mediaUrl!);
          loaded = true;
        }
        if (loaded && _player.duration != null) _total = _player.duration!;
      } catch (_) {
        loaded = false;
      } finally {
        _ready = loaded;
        if (mounted) setState(() => _loading = false);
      }
    }
    if (!_ready) return; // never play without a loaded source
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  void _changeSpeed() {
    setState(() {
      if (_speed == 1.0) {
        _speed = 1.5;
      } else if (_speed == 1.5) {
        _speed = 2.0;
      } else {
        _speed = 1.0;
      }
    });
    _player.setSpeed(_speed);
  }

  void _changePitch() {
    setState(() {
      if (_pitch == 1.0) {
        _pitch = 1.4;
      } else if (_pitch == 1.4) {
        _pitch = 0.7;
      } else {
        _pitch = 1.0;
      }
    });
    _player.setPitch(_pitch);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chat = theme.extension<ChatTheme>()!;
    final tint = widget.mine ? chat.outgoingText : theme.colorScheme.primary;
    final progress = _total.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0);
    final remaining = _player.playing || _position > Duration.zero
        ? _position
        : _total;

    return SizedBox(
      width: 200.w,
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: _loading
                  ? Padding(
                      padding: EdgeInsets.all(10.r),
                      child: CircularProgressIndicator(strokeWidth: 2, color: tint),
                    )
                  : Icon(
                      _player.playing ? Icons.pause : Icons.play_arrow,
                      color: tint,
                      size: 22.r,
                    ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3.r),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4.h,
                    backgroundColor: tint.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(tint),
                  ),
                ),
                SizedBox(height: 5.h),
                Row(
                  children: [
                    Icon(Icons.mic, size: 12.r, color: tint.withValues(alpha: 0.8)),
                    SizedBox(width: 3.w),
                    Text(
                      _fmt(remaining),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: widget.mine
                            ? chat.outgoingText.withValues(alpha: 0.85)
                            : chat.timestamp,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _changePitch,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: tint.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(Icons.face_retouching_natural, size: 14.r, color: tint),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: _changeSpeed,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: tint.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '${_speed}x',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: tint,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
