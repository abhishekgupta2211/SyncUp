import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/models/game_enums.dart';
import '../../data/models/game_match.dart';
import '../../data/providers/game_match_provider.dart';
import '../../data/providers/games_lobby_provider.dart';
import '../../data/repositories/game_repository.dart';
import '../widgets/connect4_board.dart';
import '../widgets/dotsboxes_board.dart';
import '../widgets/game_result_overlay.dart';
import '../widgets/gomoku_board.dart';
import '../widgets/reversi_board.dart';
import '../widgets/rps_board.dart';
import '../widgets/tictactoe_board.dart';

/// Hosts one live match: the shared chrome (header, forfeit, result overlay) plus
/// the per-game board. Boards read [GameMatchProvider] from this scope.
class GameMatchPage extends StatelessWidget {
  const GameMatchPage({super.key, required this.initial});

  final GameMatch initial;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameMatchProvider(initial),
      child: const _GameMatchView(),
    );
  }
}

class _GameMatchView extends StatefulWidget {
  const _GameMatchView();

  @override
  State<_GameMatchView> createState() => _GameMatchViewState();
}

class _GameMatchViewState extends State<_GameMatchView> {
  bool _playingAgain = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GameMatchProvider>();
    final m = p.match;
    final me = p.me;
    final theme = Theme.of(context);

    // Surface RPC errors as a transient snackbar.
    final err = p.error;
    if (err != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        p.clearError();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), duration: const Duration(seconds: 2)),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            AppAvatar(
              name: m.opponentName(me) ?? 'Player',
              avatarUrl: m.opponentAvatar(me),
              radius: 16.r,
            ),
            SizedBox(width: 10.w),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.opponentName(me) ?? 'Player',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  m.game.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (m.status == GameStatus.active)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'forfeit') _confirmForfeit(context, p);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'forfeit', child: Text('Forfeit')),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: switch (m.game) {
                GameType.tictactoe => const TicTacToeBoard(),
                GameType.connect4 => const ConnectFourBoard(),
                GameType.gomoku => const GomokuBoard(),
                GameType.reversi => const ReversiBoard(),
                GameType.dotsboxes => const DotsBoxesBoard(),
                GameType.rps => const RpsBoard(),
              },
            ),
            if (m.status.isOver) _buildOverlay(context, p, m, me),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay(
    BuildContext context,
    GameMatchProvider p,
    GameMatch m,
    String me,
  ) {
    final outcome = m.winner == null
        ? GameOutcome.draw
        : (m.iWon(me) ? GameOutcome.won : GameOutcome.lost);
    final headline = switch (outcome) {
      GameOutcome.won => 'You won! 🎉',
      GameOutcome.lost => 'You lost',
      GameOutcome.draw => "It's a draw",
    };
    final String subtitle;
    if (m.status == GameStatus.abandoned) {
      subtitle = m.iWon(me)
          ? '${m.opponentName(me) ?? 'Your opponent'} forfeited.'
          : 'You forfeited the match.';
    } else {
      subtitle = switch (outcome) {
        GameOutcome.won =>
          'Nice moves against ${m.opponentName(me) ?? 'your friend'}.',
        GameOutcome.lost => 'Better luck next time!',
        GameOutcome.draw => 'Evenly matched — go again?',
      };
    }
    return GameResultOverlay(
      headline: headline,
      subtitle: subtitle,
      outcome: outcome,
      busy: _playingAgain,
      onPlayAgain: () => _playAgain(context, m, me),
      onClose: () => Navigator.of(context).maybePop(),
    );
  }

  Future<void> _playAgain(BuildContext context, GameMatch m, String me) async {
    setState(() => _playingAgain = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final lobby = context.read<GamesLobbyProvider>();
    final id = await lobby.createMatch(m.game, m.opponentId(me));
    if (id == null) {
      if (mounted) {
        setState(() => _playingAgain = false);
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not start a rematch.')),
        );
      }
      return;
    }
    GameMatch fresh;
    try {
      fresh = await GameRepository(SupabaseService.client).fetchMatch(id);
    } catch (_) {
      if (mounted) setState(() => _playingAgain = false);
      return;
    }
    if (!mounted) return;
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => GameMatchPage(initial: fresh)),
    );
  }

  Future<void> _confirmForfeit(
    BuildContext context,
    GameMatchProvider p,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forfeit match?'),
        content: const Text('Your opponent will win this match.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Forfeit',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (ok == true) await p.abandon();
  }
}
