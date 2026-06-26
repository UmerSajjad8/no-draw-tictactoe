import 'dart:math';

import '../logic/board.dart';
import '../models/game_models.dart';

class BotPlayer {
  final BotDifficulty difficulty;
  final Player me;
  final Random _rng = Random();

  /// How many games the human has won in a row. Higher = bot plays sharper.
  int winStreak;

  // Hard mode time budget so the bot never hangs on big boards.
  final Stopwatch _clock = Stopwatch();
  static const int _timeBudgetMs = 700;

  BotPlayer({
    required this.difficulty,
    this.me = Player.o,
    this.winStreak = 0,
  });

  List<int> chooseMove(Board board) {
    switch (difficulty) {
      case BotDifficulty.beginner:
        return _beginner(board);
      case BotDifficulty.medium:
        return _medium(board);
      case BotDifficulty.hard:
        return _hard(board);
    }
  }

  // ---- Beginner ----
  List<int> _beginner(Board board) {
    final empties = board.emptyCells();
    final winMove = _findWinning(board, me);
    if (winMove != null) return winMove;

    final blockChance = (0.15 * winStreak).clamp(0.0, 0.7);
    if (_rng.nextDouble() < blockChance) {
      final block = _findWinning(board, me.opponent);
      if (block != null) return block;
    }

    if (_rng.nextDouble() < 0.25) {
      final mid = board.size ~/ 2;
      if (board.isEmpty(mid, mid)) return [mid, mid];
    }
    return empties[_rng.nextInt(empties.length)];
  }

  // ---- Medium ----
  List<int> _medium(Board board) {
    final winMove = _findWinning(board, me);
    if (winMove != null) return winMove;

    final blockMove = _findWinning(board, me.opponent);
    if (blockMove != null) return blockMove;

    final pool = (4 - winStreak).clamp(1, 4);
    return _randomTopHeuristic(board, pool);
  }

  // ---- Hard: tactics first, then time-boxed minimax. ----
  List<int> _hard(Board board) {
    final winMove = _findWinning(board, me);
    if (winMove != null) return winMove;
    final blockMove = _findWinning(board, me.opponent);
    if (blockMove != null) return blockMove;

    // On large boards full minimax is too slow; use a strong, fast heuristic.
    if (board.size > 5) {
      final pool = (3 - winStreak).clamp(1, 3);
      return _randomTopHeuristic(board, pool);
    }

    // Only search a limited set of promising candidate moves.
    final candidates = _orderedMoves(board, board.emptyCells());
    final limited = candidates.take(board.size <= 3 ? 9 : 10).toList();
    final depth = _depthForSize(board.size) + (winStreak >= 3 ? 1 : 0);

    _clock
      ..reset()
      ..start();

    var bestScore = -1 << 30;
    final bestMoves = <List<int>>[];

    for (final move in limited) {
      if (_clock.elapsedMilliseconds > _timeBudgetMs) break;
      final clone = Board.from(board);
      clone.place(move[0], move[1], me);
      final score = _minimax(clone, depth - 1, false, -(1 << 30), 1 << 30);
      if (score > bestScore) {
        bestScore = score;
        bestMoves
          ..clear()
          ..add(move);
      } else if (score == bestScore) {
        bestMoves.add(move);
      }
    }
    _clock.stop();

    if (bestMoves.isEmpty) {
      // Fell out of time before scoring anything: take a safe heuristic move.
      return _randomTopHeuristic(board, 1);
    }
    return bestMoves[_rng.nextInt(bestMoves.length)];
  }

  int _depthForSize(int size) {
    if (size <= 3) return 9; // perfect on 3x3
    if (size == 4) return 4;
    return 3; // 5x5
  }

  int _minimax(Board board, int depth, bool maximizing, int alpha, int beta) {
    final win = board.checkWinner();
    if (win.hasWinner) {
      return win.winner == me ? (1000 + depth) : -(1000 + depth);
    }
    if (depth == 0 || board.isFull ||
        _clock.elapsedMilliseconds > _timeBudgetMs) {
      return _evaluate(board);
    }

    // Limit branching on bigger boards.
    final all = _orderedMoves(board, board.emptyCells());
    final empties = board.size <= 3 ? all : all.take(8).toList();

    if (maximizing) {
      var value = -(1 << 30);
      for (final move in empties) {
        final clone = Board.from(board);
        clone.place(move[0], move[1], me);
        value = max(value, _minimax(clone, depth - 1, false, alpha, beta));
        alpha = max(alpha, value);
        if (alpha >= beta) break;
        if (_clock.elapsedMilliseconds > _timeBudgetMs) break;
      }
      return value;
    } else {
      var value = 1 << 30;
      for (final move in empties) {
        final clone = Board.from(board);
        clone.place(move[0], move[1], me.opponent);
        value = min(value, _minimax(clone, depth - 1, true, alpha, beta));
        beta = min(beta, value);
        if (alpha >= beta) break;
        if (_clock.elapsedMilliseconds > _timeBudgetMs) break;
      }
      return value;
    }
  }

  // ---- Helpers ----

  List<int>? _findWinning(Board board, Player p) {
    for (final move in board.emptyCells()) {
      final clone = Board.from(board);
      clone.place(move[0], move[1], p);
      if (clone.checkWinner().winner == p) return move;
    }
    return null;
  }

  List<int> _randomTopHeuristic(Board board, int pool) {
    final empties = board.emptyCells();
    final scored = empties.map((m) {
      final clone = Board.from(board);
      clone.place(m[0], m[1], me);
      return MapEntry(m, _evaluate(clone));
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final take = scored.take(pool.clamp(1, scored.length)).toList();
    return take[_rng.nextInt(take.length)].key;
  }

  List<List<int>> _orderedMoves(Board board, List<List<int>> empties) {
    final mid = (board.size - 1) / 2.0;
    final scored = empties.map((m) {
      final centerDist = (m[0] - mid).abs() + (m[1] - mid).abs();
      final neighborScore = _neighborWeight(board, m[0], m[1]);
      final rank = centerDist - neighborScore * 2;
      return MapEntry(m, rank);
    }).toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return scored.map((e) => e.key).toList();
  }

  int _neighborWeight(Board board, int r, int c) {
    var count = 0;
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final rr = r + dr, cc = c + dc;
        if (rr >= 0 &&
            rr < board.size &&
            cc >= 0 &&
            cc < board.size &&
            board.at(rr, cc) != Player.none) {
          count++;
        }
      }
    }
    return count;
  }

  int _evaluate(Board board) {
    return _lineScore(board, me) - _lineScore(board, me.opponent);
  }

  int _lineScore(Board board, Player p) {
    final n = board.winLength;
    const dirs = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];
    var score = 0;
    for (var r = 0; r < board.size; r++) {
      for (var c = 0; c < board.size; c++) {
        for (final d in dirs) {
          var mine = 0, blocked = false;
          for (var k = 0; k < n; k++) {
            final rr = r + d[0] * k, cc = c + d[1] * k;
            if (rr < 0 || rr >= board.size || cc < 0 || cc >= board.size) {
              blocked = true;
              break;
            }
            final v = board.at(rr, cc);
            if (v == p.opponent) {
              blocked = true;
              break;
            }
            if (v == p) mine++;
          }
          if (!blocked && mine > 0) {
            score += (1 << mine);
          }
        }
      }
    }
    return score;
  }
}
