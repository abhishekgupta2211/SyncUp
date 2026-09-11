import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../chat/presentation/pages/chats_page.dart';
import '../../../chat/presentation/pages/ride_management_page.dart';
import '../../../feed/presentation/pages/feed_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../stories/presentation/pages/stories_page.dart';

/// Root scaffold for the SyncUp Rider platform.
/// HOME | EXPLORE | RIDE | COMMUNITY | PROFILE
class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _index = 0;
  late final PageController _pageController = PageController(initialPage: _index);

  static const _pages = [
    ChatsPage(),          // 0: Home (Dashboard)
    StoriesPage(),        // 1: Explore (Maps)
    RideManagementPage(), // 2: Ride Center
    FeedPage(),           // 3: Community (Social)
    ProfilePage(),        // 4: Profile (Garage)
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSelect(int i) {
    setState(() => _index = i);
    _pageController.jumpToPage(i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _index = i),
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: _RiderBottomBar(
        index: _index,
        onSelect: _onSelect,
      ),
    );
  }
}

class _RiderBottomBar extends StatelessWidget {
  const _RiderBottomBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
            selected: index == 0,
            onTap: () => onSelect(0),
          ),
          _NavItem(
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore,
            label: 'Explore',
            selected: index == 1,
            onTap: () => onSelect(1),
          ),
          _RideActionButton(
            selected: index == 2,
            onTap: () => onSelect(2),
          ),
          _NavItem(
            icon: Icons.groups_outlined,
            activeIcon: Icons.groups_rounded,
            label: 'Social',
            selected: index == 3,
            onTap: () => onSelect(3),
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
            selected: index == 4,
            onTap: () => onSelect(4),
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
        : theme.colorScheme.onSurface.withValues(alpha: 0.5);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? activeIcon : icon, color: color, size: 24.r),
          SizedBox(height: 4.h),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _RideActionButton extends StatelessWidget {
  const _RideActionButton({required this.selected, required this.onTap});
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56.r,
        height: 56.r,
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : AppColors.asphalt,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (selected ? theme.colorScheme.primary : Colors.black).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.navigation_rounded,
          color: Colors.white,
          size: 28.r,
        ),
      ),
    );
  }
}
