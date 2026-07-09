import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/chat_time.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/models/story.dart';
import '../../data/providers/story_provider.dart';
import 'story_viewer_screen.dart';

class StoriesPage extends StatelessWidget {
  const StoriesPage({super.key});

  Future<void> _showAddSheet(BuildContext context) async {
    final provider = context.read<StoryProvider>();
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery (one or many)'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      if (source == ImageSource.camera) {
        final file =
            await picker.pickImage(source: ImageSource.camera, imageQuality: 90);
        if (file != null) await provider.postStories([file]);
      } else {
        final files = await picker.pickMultiImage(imageQuality: 90);
        if (files.isNotEmpty) await provider.postStories(files);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pick failed: $e')),
        );
      }
      return;
    }
    if (context.mounted && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Story failed: ${provider.error}'),
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<StoryProvider>();
    final mine = provider.myStories;
    final friends = provider.friendStories;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 4.h),
            child: Row(
              children: [
                Text('Stories',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const Spacer(),
                if (provider.posting)
                  SizedBox(
                    width: 18.r,
                    height: 18.r,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          // My story
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
            leading: _Ring(
              active: mine != null,
              child: mine != null
                  ? AppAvatar(name: mine.name, avatarUrl: mine.avatarUrl, radius: 26.r)
                  : Stack(
                      children: [
                        Container(
                          width: 52.r,
                          height: 52.r,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person,
                              size: 28.r,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5)),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: EdgeInsets.all(2.r),
                            decoration: BoxDecoration(
                              gradient: AppColors.gradientFrom(
                                  Theme.of(context).colorScheme.primary),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: theme.scaffoldBackgroundColor, width: 2),
                            ),
                            child: Icon(Icons.add, size: 14.r, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
            ),
            title: const Text('Your story',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(mine != null
                ? '${mine.stories.length} update${mine.stories.length > 1 ? 's' : ''} · tap to view'
                : 'Tap to add to your story'),
            trailing: IconButton(
              icon: Icon(Icons.add_a_photo_outlined,
                  color: theme.colorScheme.primary),
              onPressed: () => _showAddSheet(context),
            ),
            onTap: () => mine != null
                ? openStoryViewer(context, mine, isMine: true)
                : _showAddSheet(context),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 4.h),
            child: Text('Recent updates',
                style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w700)),
          ),
          Expanded(child: _buildFriends(context, provider, friends)),
        ],
      ),
    );
  }

  Widget _buildFriends(
      BuildContext context, StoryProvider provider, List<UserStories> friends) {
    final theme = Theme.of(context);
    if (provider.loading) {
      return Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary));
    }
    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  color: theme.colorScheme.error, size: 40.r),
              SizedBox(height: 12.h),
              Text('Couldn\'t load stories',
                  style: theme.textTheme.titleMedium),
              SizedBox(height: 6.h),
              Text(provider.error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6))),
              SizedBox(height: 16.h),
              FilledButton.tonal(
                onPressed: provider.load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (friends.isEmpty) {
      return const EmptyState(
        icon: Icons.auto_awesome_outlined,
        title: 'No recent updates',
        subtitle: 'When your chats post a story, it shows up here.',
      );
    }
    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView.builder(
        itemCount: friends.length,
        itemBuilder: (context, i) {
          final g = friends[i];
          final unseen = provider.hasUnseen(g);
          return ListTile(
            contentPadding:
                EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
            leading: _Ring(
              active: unseen,
              child: AppAvatar(name: g.name, avatarUrl: g.avatarUrl, radius: 26.r),
            ),
            title:
                Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(ChatTime.listLabel(g.latestAt)),
            onTap: () => openStoryViewer(context, g, isMine: false),
          );
        },
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.child, required this.active});
  final Widget child;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(2.5.r),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active
            ? AppColors.gradientFrom(Theme.of(context).colorScheme.primary)
            : null,
        color: active ? null : theme.colorScheme.outline,
      ),
      child: Container(
        padding: EdgeInsets.all(2.r),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.scaffoldBackgroundColor,
        ),
        child: child,
      ),
    );
  }
}
