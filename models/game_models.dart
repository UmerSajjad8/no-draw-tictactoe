// lib/models/game_models.dart
//
// Core data types shared across the game.

/// A single cell's occupant.
enum Player { none, x, o }

extension PlayerLabel on Player {
  String get label {
    switch (this) {
      case Player.x:
        return 'X';
      case Player.o:
        return 'O';
      case Player.none:
        return '';
    }
  }

  Player get opponent {
    switch (this) {
      case Player.x:
        return Player.o;
      case Player.o:
        return Player.x;
      case Player.none:
        return Player.none;
    }
  }
}

/// Who controls the O seat (X is always the human in bot mode).
enum GameMode { pvp, pvb }

enum BotDifficulty { beginner, medium, hard }

/// Result of a win scan.
class WinResult {
  final Player winner;

  /// The list of (row, col) cells forming the winning line. Empty if no winner.
  final List<List<int>> line;

  const WinResult(this.winner, this.line);

  bool get hasWinner => winner != Player.none;

  static const WinResult none = WinResult(Player.none, []);
}
