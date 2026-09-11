import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../chat/presentation/pages/chat_thread_screen.dart';
import '../../../profile/data/models/profile.dart';
import '../../data/repositories/contacts_repository.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  final _repo = ContactsRepository(SupabaseService.client);
  List<Profile>? _users;
  List<Profile>? _allUsers;
  bool _loading = true;
  int _currentIndex = 0;
  String? _selectedStyle;

  final List<String> _styleOptions = ['All', 'City Rider', 'Tourer', 'Adventure Rider', 'Sports Rider', 'Cruiser'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _repo.getSuggestedUsers();
      if (mounted) {
        setState(() { 
          _allUsers = res;
          _users = res; 
          _loading = false; 
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filter(String style) {
    setState(() {
      _selectedStyle = style == 'All' ? null : style;
      if (_selectedStyle == null) {
        _users = _allUsers;
      } else {
        _users = _allUsers?.where((p) => p.ridingStyle == _selectedStyle).toList();
      }
      _currentIndex = 0;
    });
  }

  void _next() {
    if (_users == null || _users!.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _users!.length;
    });
  }

  void _open(Profile p) async {
    try {
      final convId = await _repo.getOrCreateConversation(p.id);
      if (!mounted) return;
      openChat(
        context,
        conversationId: convId,
        peerId: p.id,
        peerName: p.displayName,
        peerUsername: p.username,
        peerAvatarUrl: p.avatarUrl,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('RIDER MATCH'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt, color: Colors.amber),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI Buddy Match: Saurabh and 4 others have bikes similar to yours! 🔥')),
              );
            },
            tooltip: 'Buddy Suggestions',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStyleBar(theme),
                Expanded(
                  child: _users == null || _users!.isEmpty || _currentIndex >= _users!.length
                      ? _buildEmptyState(theme)
                      : Padding(
                          padding: EdgeInsets.all(20.r),
                          child: _buildRiderCard(_users![_currentIndex], theme),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStyleBar(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: _styleOptions.map((style) {
          final isSelected = (_selectedStyle ?? 'All') == style;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: ChoiceChip(
              label: Text(style.toUpperCase(), style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold)),
              selected: isSelected,
              onSelected: (_) => _filter(style),
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.motorcycle_rounded, size: 80.r, color: theme.colorScheme.primary.withValues(alpha: 0.2)),
          SizedBox(height: 16.h),
          const Text('No riders found in this category.', style: TextStyle(fontWeight: FontWeight.bold)),
          TextButton(onPressed: _load, child: const Text('REFRESH LIST')),
        ],
      ),
    );
  }

  Widget _buildRiderCard(Profile p, ThemeData theme) {
    return Dismissible(
      key: Key(p.id),
      onDismissed: (direction) => direction == DismissDirection.endToStart ? _next() : _open(p),
      background: _swipeBg(Alignment.centerLeft, Colors.green, Icons.chat_rounded),
      secondaryBackground: _swipeBg(Alignment.centerRight, Colors.red, Icons.close_rounded),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(32.r),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
                child: Container(
                  width: double.infinity,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: AppAvatar(name: p.displayName, avatarUrl: p.avatarUrl, radius: 100.r),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(p.displayName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                      if (p.isVerified) ...[SizedBox(width: 6.w), const Icon(Icons.verified, color: Colors.blueAccent, size: 20)],
                    ],
                  ),
                  Text(p.atUsername, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      _tag(p.ridingStyle ?? 'Rider', theme.colorScheme.primary),
                      SizedBox(width: 8.w),
                      _tag('${p.experienceYears}Y EXP', Colors.orange),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Text(p.statusLine, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8.r), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.w900)),
    );
  }

  Widget _swipeBg(Alignment align, Color color, IconData icon) {
    return Container(
      alignment: align,
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(32.r)),
      child: Icon(icon, color: Colors.white, size: 48.r),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _circleBtn(Icons.close_rounded, Colors.red, _next),
          _circleBtn(Icons.chat_bubble_rounded, Colors.green, () => _open(_users![_currentIndex])),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.1), border: Border.all(color: color, width: 2)),
        child: Icon(icon, color: color, size: 28.r),
      ),
    );
  }
}
