import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/providers/feed_provider.dart';
import '../../presentation/widgets/comments_sheet.dart';
import '../../presentation/widgets/post_card.dart';
import '../../../profile/presentation/pages/leaderboard_page.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<FeedProvider>();
    final allPosts = provider.posts;
    
    final posts = _query.isEmpty 
        ? allPosts 
        : allPosts.where((p) => 
            (p.text?.toLowerCase().contains(_query.toLowerCase()) ?? false) ||
            (p.authorName?.toLowerCase().contains(_query.toLowerCase()) ?? false)
          ).toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShoutoutBanner(theme),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 8.h),
            child: Row(
              children: [
                Text(
                  'Community',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.1),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.emoji_events_outlined, color: Colors.amber),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LeaderboardPage()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // Logic to show search bar could be here, 
                    // but for now we'll just show it always or toggle.
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search posts...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: EdgeInsets.symmetric(vertical: 8.h),
              ),
            ),
          ),
          Expanded(
            child: provider.loading && posts.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                        color: theme.colorScheme.primary),
                  )
                : posts.isEmpty
                    ? EmptyState(
                        icon: _query.isEmpty ? Icons.dynamic_feed_outlined : Icons.search_off,
                        title: _query.isEmpty ? 'No posts yet' : 'No matches',
                        subtitle: _query.isEmpty 
                            ? 'Share a photo, video or thought — your friends will see it here 💜'
                            : 'No posts match your search.',
                      )
                    : RefreshIndicator(
                        onRefresh: provider.load,
                        child: ListView.builder(
                          padding: EdgeInsets.only(top: 4.h, bottom: 96.h),
                          itemCount: posts.length,
                          itemBuilder: (_, i) {
                            final p = posts[i];
                            return PostCard(
                              post: p,
                              onOpenComments: () =>
                                  showCommentsSheet(context, p.id),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoutoutBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 36.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [theme.colorScheme.primary, Colors.purpleAccent]),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: const Icon(Icons.campaign, color: Colors.white, size: 18),
          ),
          Expanded(
            child: Text(
              "Global Shoutout: user_abhishek just joined the Top 10 Leaderboard! 🔥",
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds),
          ),
        ],
      ),
    );
  }
}
