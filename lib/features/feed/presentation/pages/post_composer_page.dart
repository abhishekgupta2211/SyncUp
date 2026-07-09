import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/gradient_button.dart';
import '../../data/models/post.dart';
import '../../data/providers/feed_provider.dart';

/// Full-page composer to create a new feed post (text, photo or video).
class PostComposerPage extends StatefulWidget {
  const PostComposerPage({super.key});

  @override
  State<PostComposerPage> createState() => _PostComposerPageState();
}

class _PostComposerPageState extends State<PostComposerPage> {
  final TextEditingController _controller = TextEditingController();

  String? _mediaKind; // 'image' | 'video'
  Uint8List? _bytes;
  String? _ext;
  String? _contentType;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  bool get _canPost =>
      !_posting && (_controller.text.trim().isNotEmpty || _bytes != null);

  Future<void> _pickPhoto() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final x = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 82);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (!mounted) return;
      final parts = x.name.split('.');
      setState(() {
        _bytes = bytes;
        _ext = parts.length > 1 ? parts.last : 'jpg';
        _contentType = 'image/jpeg';
        _mediaKind = 'image';
      });
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open the picker')),
      );
    }
  }

  Future<void> _pickVideo() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final x = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _ext = 'mp4';
        _contentType = 'video/mp4';
        _mediaKind = 'video';
      });
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open the picker')),
      );
    }
  }

  void _clearMedia() {
    setState(() {
      _bytes = null;
      _ext = null;
      _contentType = null;
      _mediaKind = null;
    });
  }

  Future<void> _onPost() async {
    if (!_canPost) return;
    setState(() => _posting = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final feed = context.read<FeedProvider>();
    final text = _controller.text.trim();

    Post? post;
    if (_mediaKind != null && _bytes != null) {
      post = await feed.createMediaPost(
        kind: _mediaKind!,
        bytes: _bytes!,
        ext: _ext ?? 'jpg',
        contentType: _contentType ?? 'application/octet-stream',
        text: text.isEmpty ? null : text,
      );
    } else {
      post = await feed.createTextPost(text);
    }

    if (!mounted) return;
    if (post == null) {
      setState(() => _posting = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not post. Try again.')),
      );
      return;
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('New post')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
          children: [
            TextField(
              controller: _controller,
              minLines: 4,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              enabled: !_posting,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
                border: InputBorder.none,
              ),
              style: theme.textTheme.bodyLarge,
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _MediaChip(
                    icon: Icons.image,
                    label: 'Photo',
                    selected: _mediaKind == 'image',
                    onTap: _posting ? null : _pickPhoto,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _MediaChip(
                    icon: Icons.videocam,
                    label: 'Video',
                    selected: _mediaKind == 'video',
                    onTap: _posting ? null : _pickVideo,
                  ),
                ),
              ],
            ),
            if (_bytes != null) ...[
              SizedBox(height: 18.h),
              _preview(theme),
            ],
            SizedBox(height: 28.h),
            GradientButton(
              label: 'Post',
              icon: Icons.send_rounded,
              loading: _posting,
              onPressed: _canPost ? _onPost : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview(ThemeData theme) {
    final isVideo = _mediaKind == 'video';
    final media = isVideo
        ? Container(
            height: 220.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18.r),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.play_circle_fill,
                  size: 52.r,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Video selected',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(18.r),
            child: Image.memory(
              _bytes!,
              height: 220.h,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          );

    return Stack(
      children: [
        media,
        Positioned(
          top: 8.h,
          right: 8.w,
          child: Material(
            color: Colors.black.withValues(alpha: 0.45),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _posting ? null : _clearMedia,
              child: Padding(
                padding: EdgeInsets.all(4.r),
                child: Icon(Icons.close, size: 20.r, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A choice-style button for picking a media type.
class _MediaChip extends StatelessWidget {
  const _MediaChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final border = selected
        ? accent
        : theme.colorScheme.onSurface.withValues(alpha: 0.14);
    return Material(
      color: selected
          ? accent.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: border, width: 1.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20.r,
                color: selected
                    ? accent
                    : theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
              SizedBox(width: 8.w),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected
                      ? accent
                      : theme.colorScheme.onSurface.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
