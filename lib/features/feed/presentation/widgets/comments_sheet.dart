import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/utils/chat_time.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/models/post_comment.dart';
import '../../data/providers/feed_provider.dart';
import '../../data/repositories/feed_repository.dart';

/// Opens the comments modal for [postId]. Padded above the keyboard.
Future<void> showCommentsSheet(BuildContext context, String postId) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: CommentsSheet(postId: postId),
      ),
    );

/// A draggable bottom sheet listing a post's comments with threaded replies
/// and an input to add a comment or reply.
class CommentsSheet extends StatefulWidget {
  const CommentsSheet({super.key, required this.postId});

  final String postId;

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _repo = FeedRepository(SupabaseService.client);
  final _controller = TextEditingController();

  List<PostComment> _all = [];
  bool _loading = true;
  String? _replyingToId;
  String? _replyingToName;
  bool _sending = false;

  final String _me = SupabaseService.currentUserId ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rows = await _repo.fetchComments(widget.postId);
      if (!mounted) return;
      setState(() {
        _all = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _startReply(PostComment c) {
    setState(() {
      _replyingToId = c.id;
      _replyingToName = c.authorName ?? 'User';
    });
  }

  void _clearReply() {
    setState(() {
      _replyingToId = null;
      _replyingToName = null;
    });
  }

  Future<void> _deleteComment(PostComment c) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.deleteComment(c.id);
      if (!mounted) return;
      context.read<FeedProvider>().bumpCommentCount(widget.postId, -1);
      await _load();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not delete comment')),
      );
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _repo.addComment(widget.postId, text, parentId: _replyingToId);
      if (!mounted) return;
      context.read<FeedProvider>().bumpCommentCount(widget.postId, 1);
      _controller.clear();
      _replyingToId = null;
      _replyingToName = null;
      await _load();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
          ),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 10.h),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Comments',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Divider(height: 1, color: theme.colorScheme.outline),
              Expanded(child: _buildList(theme, scrollController)),
              _buildInput(theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(ThemeData theme, ScrollController scrollController) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final topLevel = _all.where((c) => c.parentId == null).toList();
    if (topLevel.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Text(
            'No comments yet — be the first!',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
      itemCount: topLevel.length,
      itemBuilder: (_, i) {
        final parent = topLevel[i];
        final replies =
            _all.where((c) => c.parentId == parent.id).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CommentTile(
              comment: parent,
              isMine: parent.userId == _me,
              onReply: () => _startReply(parent),
              onDelete: () => _deleteComment(parent),
            ),
            for (final reply in replies)
              Padding(
                padding: EdgeInsets.only(left: 40.w),
                child: _CommentTile(
                  comment: reply,
                  isMine: reply.userId == _me,
                  onReply: () => _startReply(parent),
                  onDelete: () => _deleteComment(reply),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInput(ThemeData theme) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outline, width: 1),
          ),
        ),
        padding: EdgeInsets.fromLTRB(12.w, 8.h, 8.w, 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyingToId != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.fromLTRB(12.w, 6.h, 6.w, 6.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Replying to ${_replyingToName ?? 'User'}',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _clearReply,
                        child: Padding(
                          padding: EdgeInsets.only(left: 4.w),
                          child: Icon(
                            Icons.close,
                            size: 16.r,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Add a comment…',
                      isDense: true,
                      filled: true,
                      fillColor:
                          theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                IconButton(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.send_rounded,
                          color: theme.colorScheme.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.isMine,
    required this.onReply,
    required this.onDelete,
  });

  final PostComment comment;
  final bool isMine;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onLongPress: isMine ? onDelete : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppAvatar(
              name: comment.authorName ?? 'User',
              avatarUrl: comment.authorAvatar,
              radius: 16.r,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          comment.authorName ?? 'User',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        ChatTime.listLabel(comment.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11.sp,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    comment.text,
                    style: theme.textTheme.bodyMedium,
                  ),
                  SizedBox(height: 2.h),
                  SizedBox(
                    height: 28.h,
                    child: TextButton(
                      onPressed: onReply,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size(0, 28.h),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      child: Text(
                        'Reply',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
