import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../contacts/data/repositories/contacts_repository.dart';
import '../../../profile/data/models/profile.dart';
import '../../data/models/game_enums.dart';
import '../../data/models/game_match.dart';
import '../../data/providers/games_lobby_provider.dart';
import '../../data/repositories/game_repository.dart';
import 'game_match_page.dart';

/// The Games hub — pick a game to challenge a friend, and resume your matches.
class GamesHubPage extends StatefulWidget {
  const GamesHubPage({super.key});

  @override
  State<GamesHubPage> createState() => _GamesHubPageState();
}

class _GamesHubPageState extends State<GamesHubPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GamesLobbyProvider>().clearBadge();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lobby = context.watch<GamesLobbyProvider>();
    final me = SupabaseService.currentUserId ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Games')),
      body: RefreshIndicator(
        onRefresh: lobby.load,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 28.h),
          children: [
            _sectionTitle(theme, 'Start a game'),
            SizedBox(height: 10.h),
            for (final g in GameType.values) ...[
              _GameCard(game: g, onTap: () => startGame(context, g)),
              SizedBox(height: 10.h),
            ],
            SizedBox(height: 14.h),
            _sectionTitle(theme, 'Your games'),
            SizedBox(height: 6.h),
            if (lobby.loading && lobby.matches.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 40.h),
                child: Center(
                  child: CircularProgressIndicator(
                      color: theme.colorScheme.primary),
                ),
              )
            else if (lobby.matches.isEmpty)
              Padding(
                padding: EdgeInsets.only(top: 24.h),
                child: const EmptyState(
                  icon: Icons.sports_esports_outlined,
                  title: 'No games yet',
                  subtitle: 'Challenge a friend to a match above 🎮',
                ),
              )
            else ...[
              for (final m in lobby.active)
                _MatchTile(match: m, me: me, onTap: () => openGame(context, m)),
              if (lobby.finished.isNotEmpty) ...[
                SizedBox(height: 10.h),
                _sectionTitle(theme, 'Recent results', small: true),
                for (final m in lobby.finished)
                  _MatchTile(
                    match: m,
                    me: me,
                    onTap: () => openGame(context, m),
                    onDelete: () => lobby.deleteMatch(m.id),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String text, {bool small = false}) {
    return Text(
      text,
      style: (small ? theme.textTheme.titleSmall : theme.textTheme.titleMedium)
          ?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

/// Opens a match board.
void openGame(BuildContext context, GameMatch m) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => GameMatchPage(initial: m)),
  );
}

/// Pick a friend, create a match and open it.
Future<void> startGame(BuildContext context, GameType game) async {
  final friend = await showModalBottomSheet<Profile>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FriendPickerSheet(game: game),
  );
  if (friend == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final lobby = context.read<GamesLobbyProvider>();
  final id = await lobby.createMatch(game, friend.id);
  if (id == null) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not start the game. Try again.')),
    );
    return;
  }
  GameMatch fresh;
  try {
    fresh = await GameRepository(SupabaseService.client).fetchMatch(id);
  } catch (_) {
    return;
  }
  if (context.mounted) openGame(context, fresh);
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game, required this.onTap});

  final GameType game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 52.r,
                height: 52.r,
                decoration: BoxDecoration(
                  gradient:
                      AppColors.gradientFrom(theme.colorScheme.primary),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(game.icon, color: Colors.white, size: 28.r),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.label,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      game.tagline,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    required this.match,
    required this.me,
    required this.onTap,
    this.onDelete,
  });

  final GameMatch match;
  final String me;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = _status(theme);
    final tile = ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      leading: AppAvatar(
        name: match.opponentName(me) ?? 'Player',
        avatarUrl: match.opponentAvatar(me),
        radius: 22.r,
      ),
      title: Text(
        match.opponentName(me) ?? 'Player',
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(match.game.label),
      trailing: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
    if (onDelete == null) return tile;
    return Dismissible(
      key: ValueKey(match.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete!(),
      background: Container(
        color: theme.colorScheme.error.withValues(alpha: 0.85),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24.w),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: tile,
    );
  }

  (String, Color) _status(ThemeData theme) {
    if (match.status == GameStatus.active) {
      return match.isMyTurn(me)
          ? ('Your turn', theme.colorScheme.primary)
          : (match.game == GameType.rps ? 'Playing' : 'Their turn',
              theme.colorScheme.onSurface.withValues(alpha: 0.55));
    }
    if (match.status == GameStatus.abandoned) {
      return match.iWon(me)
          ? ('Won', AppColors.online)
          : ('Forfeited', theme.colorScheme.onSurface.withValues(alpha: 0.55));
    }
    if (match.winner == null) return ('Draw', theme.colorScheme.primary);
    return match.iWon(me)
        ? ('Won', AppColors.online)
        : ('Lost', theme.colorScheme.onSurface.withValues(alpha: 0.55));
  }
}

/// Bottom sheet listing accepted friends to challenge.
class _FriendPickerSheet extends StatefulWidget {
  const _FriendPickerSheet({required this.game});

  final GameType game;

  @override
  State<_FriendPickerSheet> createState() => _FriendPickerSheetState();
}

class _FriendPickerSheetState extends State<_FriendPickerSheet> {
  late Future<List<Profile>> _future;

  @override
  void initState() {
    super.initState();
    _future = ContactsRepository(SupabaseService.client).friends();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
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
                padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 6.h),
                child: Row(
                  children: [
                    Icon(widget.game.icon, color: theme.colorScheme.primary),
                    SizedBox(width: 10.w),
                    Text(
                      'Challenge a friend',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Profile>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                            color: theme.colorScheme.primary),
                      );
                    }
                    final friends = snap.data ?? const <Profile>[];
                    if (friends.isEmpty) {
                      return const EmptyState(
                        icon: Icons.group_outlined,
                        title: 'No friends yet',
                        subtitle: 'Add a friend first, then challenge them.',
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: friends.length,
                      itemBuilder: (context, i) {
                        final f = friends[i];
                        return ListTile(
                          onTap: () => Navigator.pop(context, f),
                          leading: AppAvatar(
                            name: f.displayName,
                            avatarUrl: f.avatarUrl,
                            radius: 22.r,
                          ),
                          title: Text(
                            f.displayName,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(f.atUsername),
                          trailing: const Icon(Icons.play_circle_outline),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
