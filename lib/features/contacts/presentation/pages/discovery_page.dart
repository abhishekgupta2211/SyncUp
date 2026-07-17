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
  List<Profile>? _allUsers; // Cache all users
  bool _loading = true;
  int _currentIndex = 0;
  String? _selectedInterest;

  final List<String> _interestOptions = ['All', 'Travel', 'Music', 'Coding', 'Fitness', 'Art', 'Movies'];

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
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _filter(String interest) {
    setState(() {
      _selectedInterest = interest == 'All' ? null : interest;
      if (_selectedInterest == null) {
        _users = _allUsers;
      } else {
        _users = _allUsers?.where((p) => p.interests.contains(_selectedInterest)).toList();
      }
      _currentIndex = 0;
    });
  }

  void _next() {
    if (_users == null) return;
    setState(() {
      if (_currentIndex < _users!.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0; // Loop back or refresh
      }
    });
  }

  void _shakeToVibe() {
    if (_users == null || _users!.isEmpty) return;
    final randomIdx = DateTime.now().millisecond % _users!.length;
    setState(() => _currentIndex = randomIdx);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✨ Phone Shaked! Found a random vibe match for you!'), duration: Duration(seconds: 2)),
    );
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
        title: const Text('Vibe Match'),
        actions: [
          IconButton(onPressed: _shakeToVibe, icon: const Icon(Icons.auto_fix_normal), tooltip: 'Shake to Vibe'),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildInterestBar(theme),
                Expanded(
                  child: _users == null || _users!.isEmpty || _currentIndex >= _users!.length
                      ? _buildEmptyState(theme)
                      : Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.r),
                            child: Stack(
                              children: [
                                _buildCard(_users![_currentIndex], theme),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildInterestBar(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: _interestOptions.map((interest) {
          final isSelected = (_selectedInterest ?? 'All') == interest;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: FilterChip(
              label: Text(interest),
              selected: isSelected,
              onSelected: (_) => _filter(interest),
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              checkmarkColor: theme.colorScheme.primary,
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
          Icon(Icons.people_outline, size: 80.r, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          SizedBox(height: 20.h),
          const Text('No more vibes to match right now!', style: TextStyle(fontWeight: FontWeight.bold)),
          TextButton(onPressed: _load, child: const Text('Refresh Discovery')),
        ],
      ),
    );
  }

  Widget _buildCard(Profile p, ThemeData theme) {
    return Dismissible(
      key: Key(p.id),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          // Ignored
          _next();
        } else {
          // Matched/Liked
          _open(p);
        }
      },
      background: _swipeBackground(Alignment.centerLeft, Colors.green, Icons.favorite),
      secondaryBackground: _swipeBackground(Alignment.centerRight, Colors.red, Icons.close),
      child: Container(
        width: double.infinity,
        height: 500.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.r),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.colorScheme.surface, theme.colorScheme.surfaceContainerHighest],
          ),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
                child: AppAvatar(name: p.displayName, avatarUrl: p.avatarUrl, radius: 100.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(p.displayName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      if (p.isVerified) Icon(Icons.verified, color: Colors.blue, size: 20.r),
                      const Spacer(),
                      Icon(Icons.music_note, color: theme.colorScheme.primary, size: 20.r),
                    ],
                  ),
                  Text(p.atUsername, style: TextStyle(color: theme.colorScheme.primary)),
                  SizedBox(height: 10.h),
                  _buildVibeScore(p, theme),
                  SizedBox(height: 10.h),
                  _buildAIInsightButton(p, theme),
                  SizedBox(height: 10.h),
                  Text(p.statusLine, maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (p.bio != null) ...[
                    SizedBox(height: 10.h),
                    Text(p.bio!, style: theme.textTheme.bodySmall, maxLines: 3),
                  ],
                ],
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildVibeScore(Profile p, ThemeData theme) {
    // Advanced Mock Logic: Calculate score based on interests length and a random factor
    final score = 70 + (p.interests.length * 5) % 30;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.pinkAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, size: 14.r, color: Colors.pinkAccent),
          SizedBox(width: 4.w),
          Text('$score% Vibe Match', style: TextStyle(fontSize: 12.sp, color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAIInsightButton(Profile p, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
            title: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber),
                SizedBox(width: 10.w),
                const Text('AI Match Insight'),
              ],
            ),
            content: Text("AI says: You both love '${p.interests.isNotEmpty ? p.interests.first : 'connecting'}'! Plus, your moods are perfectly in sync today. Go ahead, say hi! ✨❤️"),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Nice!'))],
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.psychology_outlined, color: Colors.white, size: 16),
            SizedBox(width: 6.w),
            const Text('Why we match?', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _swipeBackground(Alignment align, Color color, IconData icon) {
    return Container(
      alignment: align,
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(30.r)),
      child: Icon(icon, color: Colors.white, size: 50.r),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _circleButton(Icons.close, Colors.red, _next),
          _circleButton(Icons.favorite, Colors.green, () => _open(_users![_currentIndex])),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(15.r),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, color: color, size: 30.r),
      ),
    );
  }
}
