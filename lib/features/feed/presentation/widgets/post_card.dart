import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/chat_time.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/models/post.dart';
import '../../data/providers/feed_provider.dart';

/// A rugged card for the Rider Community.
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
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.5);
    final me = SupabaseService.currentUserId ?? '';
    final text = post.text;
    final mediaUrl = post.mediaUrl;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Header ----
          Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              children: [
                AppAvatar(
                  name: post.authorName ?? 'Rider',
                  avatarUrl: post.authorAvatar,
                  radius: 20.r,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName ?? 'Rider',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '@${post.authorUsername ?? ''} • ${ChatTime.listLabel(post.createdAt)}',
                        style: theme.textTheme.labelSmall?.copyWith(color: muted, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (post.isMine(me))
                  IconButton(
                    icon: Icon(Icons.more_horiz_rounded, color: muted),
                    onPressed: () => _confirmDelete(context),
                  ),
              ],
            ),
          ),

          // ---- Body: media ----
          if (mediaUrl != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: post.isVideo 
                  ? _PostVideo(url: mediaUrl)
                  : CachedNetworkImage(
                      imageUrl: mediaUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(height: 240.h, color: AppColors.asphalt),
                    ),
              ),
            ),

          // ---- Body: text ----
          if (text != null && text.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
              child: _buildRichText(context, text, theme),
            ),

          // ---- Actions ----
          Padding(
            padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 8.h),
            child: Row(
              children: [
                _ActionButton(
                  icon: post.likedByMe ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                  color: post.likedByMe ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  label: post.likeCount.toString(),
                  onTap: () => context.read<FeedProvider>().toggleLike(post),
                ),
                _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  color: theme.colorScheme.onSurface,
                  label: post.commentCount.toString(),
                  onTap: onOpenComments,
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    post.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                    color: post.isBookmarked ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  ),
                  onPressed: () => context.read<FeedProvider>().toggleBookmark(post),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final provider = context.read<FeedProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This post will be removed from the community feed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) await provider.deletePost(post.id);
  }

  Widget _buildRichText(BuildContext context, String text, ThemeData theme) {
    final words = text.split(' ');
    return Text.rich(
      TextSpan(
        children: words.map((word) {
          if (word.startsWith('#')) {
            return TextSpan(
              text: '$word ',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            );
          }
          return TextSpan(text: '$word ', style: theme.textTheme.bodyMedium);
        }).toList(),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.color, required this.label, required this.onTap});
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        child: Row(
          children: [
            Icon(icon, size: 22.r, color: color),
            SizedBox(width: 8.w),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13.sp)),
          ],
        ),
      ),
    );
  }
}

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
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await _controller!.initialize();
      if (mounted) setState(() => _ready = true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_ready) return Container(height: 240.h, color: AppColors.asphalt, child: const Center(child: CircularProgressIndicator()));
    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller!),
          IconButton(
            onPressed: () => setState(() => _controller!.value.isPlaying ? _controller!.pause() : _controller!.play()),
            icon: Icon(_controller!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 50.r, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
