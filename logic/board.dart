import '../models/game_models.dart';

class Board {
  int size;
  List<List<Player>> cells;

  Board(this.size)
      : cells = List.generate(
          size,
          (_) => List<Player>.filled(size, Player.none),
        );

  Board.from(Board other)
      : size = other.size,
        cells = other.cells.map((row) => List<Player>.from(row)).toList();

  int get winLength => size <= 3 ? 3 : 4;

  Player at(int r, int c) => cells[r][c];

  bool isEmpty(int r, int c) => cells[r][c] == Player.none;

  void place(int r, int c, Player p) => cells[r][c] = p;

  void clearCell(int r, int c) => cells[r][c] = Player.none;

  List<List<int>> emptyCells() {
    final out = <List<int>>[];
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (cells[r][c] == Player.none) out.add([r, c]);
      }
    }
    return out;
  }

  bool get isFull => emptyCells().isEmpty;

  WinResult checkWinner() {
    final n = winLength;
    const dirs = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];

    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final start = cells[r][c];
        if (start == Player.none) continue;
        for (final d in dirs) {
          final line = <List<int>>[[r, c]];
          var rr = r, cc = c;
          var ok = true;
          for (var k = 1; k < n; k++) {
            rr += d[0];
            cc += d[1];
            if (rr < 0 || rr >= size || cc < 0 || cc >= size) {
              ok = false;
              break;
            }
            if (cells[rr][cc] != start) {
              ok = false;
              break;
            }
            line.add([rr, cc]);
          }
          if (ok) return WinResult(start, line);
        }
      }
    }
    return WinResult.none;
  }

  /// Expands the board by [amount] rows and [amount] columns,
  /// preserving existing marks. Draw rule uses amount = 2 (3x3 -> 5x5 -> 7x7).
  void expand({int amount = 2}) {
    final newSize = size + amount;
    final newCells = List.generate(
      newSize,
      (r) => List<Player>.generate(
        newSize,
        (c) => (r < size && c < size) ? cells[r][c] : Player.none,
      ),
    );
    size = newSize;
    cells = newCells;
  }
}
