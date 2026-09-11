import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../data/providers/game_match_provider.dart';
import 'turn_banner.dart';

class TicTacToeBoard extends StatelessWidget {
  const TicTacToeBoard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GameMatchProvider>();
    final m = p.match;
    final me = p.me;
    final theme = Theme.of(context);

    final isMyTurn = m.isMyTurn(me);
    final label = isMyTurn ? "Your turn" : "${m.opponentName(me) ?? 'Opponent'}'s turn";

    // board is list of 9 marks from m.cells
    final cells = m.cells;

    return Column(
      children: [
        TurnBanner(isMyTurn: isMyTurn, label: label),
        SizedBox(height: 24.h),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 9,
              itemBuilder: (context, i) {
                final cell = i < cells.length ? cells[i] : '';
                return GestureDetector(
                  onTap: () {
                    if (cell.isEmpty && !p.sending && isMyTurn) {
                      p.placeCell(i);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cell,
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cell == 'X' ? theme.colorScheme.primary : theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
