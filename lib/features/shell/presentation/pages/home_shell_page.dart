import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../chat/presentation/pages/chats_page.dart';
import '../../../feed/presentation/pages/feed_page.dart';
import '../../../feed/presentation/pages/post_composer_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../stories/presentation/pages/stories_page.dart';

/// Root scaffold: an [IndexedStack] of the four tabs with a notched bottom bar
/// and an elevated center FAB that composes a new Feed post —
/// Chats · Story · (+) · Feed · Profile.
class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _index = 0;
  late final PageController _pageController = PageController(initialPage: _index);

  static const _pages = [
    ChatsPage(), // 0
    StoriesPage(), // 1
    FeedPage(), // 2
    ProfilePage(), // 3
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _newPost() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PostComposerPage()),
    );
  }

  void _onSelect(int i) {
    setState(() => _index = i);
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _index = i),
        physics: const NeverScrollableScrollPhysics(), // Only tap to change
        children: _pages,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _PostFab(onTap: _newPost),
      bottomNavigationBar: _NotchedBar(
        index: _index,
        onSelect: _onSelect,
      ),
    );
  }
}

class _NotchedBar extends StatelessWidget {
  const _NotchedBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 12,
      color: theme.colorScheme.surface,
      padding: EdgeInsets.zero,
      height: 62.h,
      child: Row(
        children: [
          _NavItem(
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble,
            label: 'Chats',
            selected: index == 0,
            onTap: () => onSelect(0),
          ),
          _NavItem(
            icon: Icons.amp_stories_outlined,
            activeIcon: Icons.amp_stories,
            label: 'Story',
            selected: index == 1,
            onTap: () => onSelect(1),
          ),
          SizedBox(width: 64.w), // gap for the center FAB notch
          _NavItem(
            icon: Icons.dynamic_feed_outlined,
            activeIcon: Icons.dynamic_feed,
            label: 'Feed',
            selected: index == 2,
            onTap: () => onSelect(2),
          ),
          _NavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
            selected: index == 3,
            onTap: () => onSelect(3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.55);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.14 : 1.0,
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              child: Icon(selected ? activeIcon : icon, color: color, size: 22.r),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostFab extends StatelessWidget {
  const _PostFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60.r,
        height: 60.r,
        decoration: BoxDecoration(
          gradient: AppColors.gradientFrom(primary),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(Icons.add_rounded, color: Colors.white, size: 32.r),
      ),
    );
  }
}
