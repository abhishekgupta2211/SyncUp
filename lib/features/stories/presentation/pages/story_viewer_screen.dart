import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/chat_time.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/models/story.dart';
import '../../data/providers/story_provider.dart';
import '../../data/repositories/story_repository.dart';

void openStoryViewer(BuildContext context, UserStories group,
    {required bool isMine}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => StoryViewerScreen(group: group, isMine: isMine),
    ),
  );
}

class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({super.key, required this.group, required this.isMine});

  final UserStories group;
  final bool isMine;

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  final _repo = StoryRepository();
  int _index = 0;
  int _likeCount = 0;
  bool _liked = false;

  // double-tap heart-burst
  Offset? _burstAt;
  int _burstSeq = 0;
  Offset _lastTapPos = Offset.zero;

  late final List<Story> _stories = List<Story>.from(widget.group.stories);

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) _next();
      });
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    _progress.forward(from: 0);
    final story = _stories[_index];
    if (!widget.isMine) {
      context.read<StoryProvider>().markViewed(story.id);
    }
    _loadLike(story.id);
  }

  void _next() {
    if (_index < _stories.length - 1) {
      setState(() => _index++);
      _start();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _prev() {
    if (_index > 0) {
      setState(() => _index--);
      _start();
    } else {
      _progress.forward(from: 0);
    }
  }

  Future<void> _loadLike(String storyId) async {
    try {
      final s = await _repo.fetchLikeState(storyId);
      if (mounted && _stories[_index].id == storyId) {
        setState(() {
          _likeCount = s.count;
          _liked = s.liked;
        });
      }
    } catch (_) {}
  }

  Future<void> _like(bool value) async {
    if (_liked == value) return;
    final story = _stories[_index];
    setState(() {
      _liked = value;
      _likeCount = (_likeCount + (value ? 1 : -1)).clamp(0, 1 << 30);
    });
    HapticFeedback.lightImpact();
    try {
      await _repo.setLike(story.id, value);
      final s = await _repo.fetchLikeState(story.id);
      if (mounted && _stories[_index].id == story.id) {
        setState(() {
          _likeCount = s.count;
          _liked = s.liked;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleLike() => _like(!_liked);

  /// Double-tap: like (if not already) and pop a heart-burst at [pos].
  void _likeWithBurst(Offset pos) {
    if (!_liked) {
      _like(true);
    } else {
      HapticFeedback.mediumImpact();
    }
    setState(() {
      _burstAt = pos;
      _burstSeq++;
    });
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = _stories[_index];
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) =>
            d.globalPosition.dx < width / 3 ? _prev() : _next(),
        onDoubleTapDown: (d) => _lastTapPos = d.localPosition,
        onDoubleTap: () => _likeWithBurst(_lastTapPos),
        onLongPressStart: (_) => _progress.stop(),
        onLongPressEnd: (_) => _progress.forward(),
        child: Stack(
          children: [
            Center(
              child: CachedNetworkImage(
                imageUrl: story.mediaUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                placeholder: (_, _) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Column(
                  children: [
                    SizedBox(height: 8.h),
                    _progressBars(),
                    SizedBox(height: 10.h),
                    _header(story),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(child: _bottomBar(story)),
            ),
            if (_burstAt != null)
              Positioned(
                left: _burstAt!.dx - 90,
                top: _burstAt!.dy - 90,
                child: IgnorePointer(
                  child: _HeartBurst(
                    key: ValueKey(_burstSeq),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _progressBars() {
    return Row(
      children: List.generate(_stories.length, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 3.h,
                child: i < _index
                    ? Container(color: Colors.white)
                    : i > _index
                        ? Container(color: Colors.white24)
                        : AnimatedBuilder(
                            animation: _progress,
                            builder: (_, _) => LinearProgressIndicator(
                              value: _progress.value,
                              backgroundColor: Colors.white24,
                              valueColor:
                                  const AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _header(Story story) {
    return Row(
      children: [
        AppAvatar(
            name: widget.group.name,
            avatarUrl: widget.group.avatarUrl,
            radius: 18.r),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.isMine ? 'Your story' : widget.group.name,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp)),
              Text(ChatTime.listLabel(story.createdAt),
                  style:
                      TextStyle(color: Colors.white70, fontSize: 11.sp)),
            ],
          ),
        ),
        if (widget.isMine)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () => _deleteStory(story),
          ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }

  Future<void> _deleteStory(Story story) async {
    _progress.stop();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete story?'),
        content: const Text('Remove this story for everyone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete',
                  style: TextStyle(color: Theme.of(context).colorScheme.error))),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<StoryProvider>().deleteStory(story.id);
      if (!mounted) return;
      _stories.removeWhere((s) => s.id == story.id);
      if (_stories.isEmpty) {
        Navigator.of(context).maybePop();
      } else {
        setState(() => _index = _index.clamp(0, _stories.length - 1));
        _start();
      }
    } else if (mounted) {
      _progress.forward();
    }
  }

  Widget _bottomBar(Story story) {
    if (widget.isMine) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
        child: GestureDetector(
          onTap: () => _showViewers(story),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.visibility_outlined, color: Colors.white, size: 20),
              SizedBox(width: 6.w),
              const Text('Seen by viewers',
                  style: TextStyle(color: Colors.white)),
              const Icon(Icons.keyboard_arrow_up, color: Colors.white),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 12.h),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showComments(story),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white54),
                  borderRadius: BorderRadius.circular(26.r),
                ),
                child: const Text('Reply / comment...',
                    style: TextStyle(color: Colors.white70)),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          GestureDetector(
            onTap: _toggleLike,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_liked ? Icons.favorite : Icons.favorite_border,
                        color: _liked
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white,
                        size: 30.r)
                    .animate(key: ValueKey(_liked))
                    .scale(
                      begin: const Offset(1.4, 1.4),
                      end: const Offset(1, 1),
                      curve: Curves.elasticOut,
                      duration: 500.ms,
                    ),
                if (_likeCount > 0)
                  Text('$_likeCount',
                      style: TextStyle(color: Colors.white, fontSize: 11.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showViewers(Story story) async {
    _progress.stop();
    final viewers = await _repo.fetchViewers(story.id);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(14.w),
              child: Text('Viewed by ${viewers.length}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            if (viewers.isEmpty)
              Padding(
                padding: EdgeInsets.all(20.w),
                child: const Text('No views yet'),
              ),
            ...viewers.map((v) => ListTile(
                  leading:
                      AppAvatar(name: v.name, avatarUrl: v.avatarUrl, radius: 20.r),
                  title: Text(v.name),
                  trailing: Text(ChatTime.time(v.viewedAt),
                      style: Theme.of(context).textTheme.labelSmall),
                )),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
    if (mounted) _progress.forward();
  }

  Future<void> _showComments(Story story) async {
    _progress.stop();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _CommentSheet(storyId: story.id, repo: _repo),
    );
    if (mounted) _progress.forward();
  }
}

class _CommentSheet extends StatefulWidget {
  const _CommentSheet({required this.storyId, required this.repo});
  final String storyId;
  final StoryRepository repo;

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final _controller = TextEditingController();
  List<StoryComment> _comments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _comments = await widget.repo.fetchComments(widget.storyId);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    try {
      await widget.repo.addComment(widget.storyId, text);
      await _load();
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: 0.6.sh,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(14.w),
              child: Text('Comments',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty
                      ? const Center(child: Text('No comments yet'))
                      : ListView(
                          children: _comments
                              .map((c) => ListTile(
                                    leading: AppAvatar(
                                        name: c.name,
                                        avatarUrl: c.avatarUrl,
                                        radius: 18.r),
                                    title: Text(c.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    subtitle: Text(c.text),
                                  ))
                              .toList(),
                        ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 10.h),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: theme.colorScheme.primary),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A one-shot heart-burst played on double-tap-to-like a story.
class _HeartBurst extends StatefulWidget {
  const _HeartBurst({super.key, required this.color});

  final Color color;

  @override
  State<_HeartBurst> createState() => _HeartBurstState();
}

class _HeartBurstState extends State<_HeartBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const count = 8;
    return SizedBox(
      width: 180,
      height: 180,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeOut.transform(_c.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - t).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.6 + t,
                  child: Icon(Icons.favorite, color: widget.color, size: 62),
                ),
              ),
              for (int i = 0; i < count; i++) _particle(i, count, t),
            ],
          );
        },
      ),
    );
  }

  Widget _particle(int i, int count, double t) {
    final angle = (i / count) * 2 * math.pi;
    final dist = 72.0 * t;
    return Transform.translate(
      offset: Offset(dist * math.cos(angle), dist * math.sin(angle)),
      child: Opacity(
        opacity: (1 - t).clamp(0.0, 1.0),
        child: Transform.scale(
          scale: (0.3 + 0.7 * (1 - t)).clamp(0.0, 1.0),
          child: Icon(Icons.favorite, color: widget.color, size: 20),
        ),
      ),
    );
  }
}
