import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/chat_time.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/models/post.dart';
import '../../data/providers/feed_provider.dart';

/// A single feed post rendered as a rounded card: author header, optional
/// text/image/video body and a like + comment action row.
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onOpenComments,
  });

  final Post post;
  final VoidCallback onOpenComments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final me = SupabaseService.currentUserId ?? '';
    final text = post.text;
    final mediaUrl = post.mediaUrl;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: GestureDetector(
        onDoubleTap: () => context.read<FeedProvider>().toggleLike(post),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Header ----
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 12.h, 4.w, 8.h),
              child: Row(
                children: [
                  AppAvatar(
                    name: post.authorName ?? 'User',
                    avatarUrl: post.authorAvatar,
                    radius: 20.r,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName ?? 'User',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '@${post.authorUsername ?? ''} · '
                          '${ChatTime.listLabel(post.createdAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                  if (post.isMine(me))
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: muted),
                      onSelected: (v) {
                        if (v == 'delete') _confirmDelete(context);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // ---- Body: text ----
            if (text != null && text.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 10.h),
                child: Text(text, style: theme.textTheme.bodyLarge),
              ),

            // ---- Body: image ----
            if (post.isImage && mediaUrl != null)
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 2.h, 12.w, 4.h),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14.r),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 420.h),
                    child: CachedNetworkImage(
                      imageUrl: mediaUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        height: 240.h,
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 240.h,
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        alignment: Alignment.center,
                        child: Icon(Icons.broken_image_outlined, color: muted),
                      ),
                    ),
                  ),
                ),
              ),

            // ---- Body: video ----
            if (post.isVideo && mediaUrl != null)
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 2.h, 12.w, 4.h),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14.r),
                  child: _PostVideo(url: mediaUrl),
                ),
              ),

            // ---- Actions ----
            Padding(
              padding: EdgeInsets.fromLTRB(6.w, 2.h, 6.w, 6.h),
              child: Row(
                children: [
                  _ActionButton(
                    key: ValueKey('like_${post.id}_${post.likedByMe}'),
                    icon: post.likedByMe
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: post.likedByMe ? AppColors.danger : muted,
                    label: '${post.likeCount}',
                    onTap: () => context.read<FeedProvider>().toggleLike(post),
                  ).animate(target: post.likedByMe ? 1 : 0).scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.2, 1.2),
                        duration: 150.ms,
                        curve: Curves.easeOut,
                      ).then().scale(
                        begin: const Offset(1.2, 1.2),
                        end: const Offset(1, 1),
                        duration: 150.ms,
                        curve: Curves.bounceOut,
                      ),
                  _ActionButton(
                    icon: Icons.mode_comment_outlined,
                    color: muted,
                    label: '${post.commentCount}',
                    onTap: onOpenComments,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      post.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: post.isBookmarked ? theme.colorScheme.primary : muted,
                      size: 20.r,
                    ),
                    onPressed: () => context.read<FeedProvider>().toggleBookmark(post),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final provider = context.read<FeedProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok == true) await provider.deletePost(post.id);
  }
}

/// A single icon + count action pill used in the card's bottom row.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20.r, color: color),
            SizedBox(width: 6.w),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline video player for a post: tap to play/pause, centred play overlay
/// while paused. Keeps a fixed aspect ratio from the decoded stream.
class _PostVideo extends StatefulWidget {
  const _PostVideo({required this.url});

  final String url;

  @override
  State<_PostVideo> createState() => _PostVideoState();
}

class _PostVideoState extends State<_PostVideo> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = c;
    try {
      await c.initialize();
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      // Leave the placeholder in place on failure.
    }
  }

  void _toggle() {
    final c = _controller;
    if (c == null || !_ready) return;
    setState(() {
      c.value.isPlaying ? c.pause() : c.play();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = _controller;
    if (c == null || !_ready) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.4),
          alignment: Alignment.center,
          child: SizedBox(
            width: 26.r,
            height: 26.r,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final ratio =
        c.value.aspectRatio > 0 ? c.value.aspectRatio : 16 / 9;
    return GestureDetector(
      onTap: _toggle,
      child: AspectRatio(
        aspectRatio: ratio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(c),
            if (!c.value.isPlaying)
              Container(
                width: 56.r,
                height: 56.r,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 34.r,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
