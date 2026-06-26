import '../models/game_models.dart';
import 'board.dart';

class MoveOutcome {
  final bool placed;
  final bool expanded;
  final WinResult win;
  const MoveOutcome({
    required this.placed,
    required this.expanded,
    required this.win,
  });
}

class GameController {
  Board board;
  Player current;
  WinResult lastWin = WinResult.none;
  bool gameOver = false;

  int scoreX = 0;
  int scoreO = 0;
  int expansionCount = 0;

  final List<List<int>> _history = [];

  GameController({int startSize = 3})
      : board = Board(startSize),
        current = Player.x;

  MoveOutcome play(int r, int c) {
    if (gameOver || !board.isEmpty(r, c)) {
      return const MoveOutcome(
          placed: false, expanded: false, win: WinResult.none);
    }

    board.place(r, c, current);
    _history.add([r, c, current.index]);
    final win = board.checkWinner();

    if (win.hasWinner) {
      gameOver = true;
      lastWin = win;
      if (win.winner == Player.x) {
        scoreX++;
      } else {
        scoreO++;
      }
      return MoveOutcome(placed: true, expanded: false, win: win);
    }

    var expanded = false;
    // No-draw rule: full board with no winner -> grow by 2 rows + 2 columns.
    if (board.isFull) {
      board.expand(amount: 2);
      expansionCount++;
      expanded = true;
    }

    current = current.opponent;
    return MoveOutcome(placed: true, expanded: expanded, win: WinResult.none);
  }

  /// Returns the player who made the most recent move, or Player.none.
  Player lastMoveOwner() {
    if (_history.isEmpty) return Player.none;
    return Player.values[_history.last[2]];
  }

  List<int>? undoLast() {
    if (gameOver || _history.isEmpty) return null;
    final last = _history.removeLast();
    final r = last[0], c = last[1];
    final owner = Player.values[last[2]];
    board.clearCell(r, c);
    current = owner;
    return [r, c];
  }

  void resetRound({int startSize = 3}) {
    board = Board(startSize);
    current = Player.x;
    lastWin = WinResult.none;
    gameOver = false;
    expansionCount = 0;
    _history.clear();
  }

  void resetScores() {
    scoreX = 0;
    scoreO = 0;
  }
}
