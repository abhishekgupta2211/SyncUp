import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TicTacToeGame extends StatefulWidget {
  const TicTacToeGame({super.key});

  @override
  State<TicTacToeGame> createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> {
  List<String> _board = List.filled(9, '');
  bool _xTurn = true;
  String _winner = '';

  void _handleTap(int index) {
    if (_board[index] != '' || _winner != '') return;
    setState(() {
      _board[index] = _xTurn ? 'X' : 'O';
      _xTurn = !_xTurn;
      _checkWinner();
    });
  }

  void _checkWinner() {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // cols
      [0, 4, 8], [2, 4, 6]             // diags
    ];
    for (var line in lines) {
      if (_board[line[0]] != '' &&
          _board[line[0]] == _board[line[1]] &&
          _board[line[0]] == _board[line[2]]) {
        setState(() => _winner = _board[line[0]]);
        return;
      }
    }
    if (!_board.contains('')) setState(() => _winner = 'Draw');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _winner == '' ? "Player ${_xTurn ? 'X' : 'O'}'s Turn" : (_winner == 'Draw' ? "It's a Draw!" : "Winner: $_winner! 🎉"),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
            ),
            itemCount: 9,
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => _handleTap(i),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  _board[i],
                  style: TextStyle(
                    fontSize: 24.sp, 
                    fontWeight: FontWeight.bold,
                    color: _board[i] == 'X' ? Colors.pinkAccent : Colors.blueAccent,
                  ),
                ),
              ),
            ),
          ),
          if (_winner != '')
            TextButton(
              onPressed: () => setState(() {
                _board = List.filled(9, '');
                _winner = '';
                _xTurn = true;
              }),
              child: const Text('Play Again'),
            ),
        ],
      ),
    );
  }
}
