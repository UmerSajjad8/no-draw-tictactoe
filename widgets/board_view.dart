import 'package:flutter/material.dart';
import '../logic/board.dart';
import '../models/game_models.dart';
import 'board_theme.dart';

class BoardView extends StatefulWidget {
  final Board board;
  final WinResult win;
  final bool interactionEnabled;
  final void Function(int row, int col) onTap;
  final int expansionTick;
  final List<int>? hintCell;
  final BoardTheme theme;

  const BoardView({
    super.key,
    required this.board,
    required this.win,
    required this.interactionEnabled,
    required this.onTap,
    required this.expansionTick,
    required this.theme,
    this.hintCell,
  });

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void didUpdateWidget(covariant BoardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expansionTick != oldWidget.expansionTick) {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  bool _isWinningCell(int r, int c) {
    for (final cell in widget.win.line) {
      if (cell[0] == r && cell[1] == c) return true;
    }
    return false;
  }

  bool _isHintCell(int r, int c) {
    final h = widget.hintCell;
    return h != null && h[0] == r && h[1] == c;
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.board.size;
    final t = widget.theme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.biggest.shortestSide.isFinite
            ? constraints.biggest.shortestSide
            : constraints.maxWidth;
        final dim = available;
        final cellGap = size <= 3 ? 6.0 : (size <= 5 ? 4.0 : 3.0);

        return AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final pt = Curves.easeOut.transform(_pulse.value);
            final scale = 1.0 + 0.05 * (1 - (2 * pt - 1).abs());
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            width: dim,
            height: dim,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: t.surfaceAlt, width: 2),
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: size * size,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: size,
                mainAxisSpacing: cellGap,
                crossAxisSpacing: cellGap,
              ),
              itemBuilder: (context, index) {
                final r = index ~/ size;
                final c = index % size;
                final player = widget.board.at(r, c);
                final winning = _isWinningCell(r, c);
                final hint = _isHintCell(r, c);
                return _Cell(
                  player: player,
                  winning: winning,
                  hint: hint,
                  boardSize: size,
                  theme: t,
                  enabled: widget.interactionEnabled &&
                      player == Player.none &&
                      !widget.win.hasWinner,
                  onTap: () => widget.onTap(r, c),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _Cell extends StatefulWidget {
  final Player player;
  final bool winning;
  final bool hint;
  final bool enabled;
  final int boardSize;
  final BoardTheme theme;
  final VoidCallback onTap;

  const _Cell({
    required this.player,
    required this.winning,
    required this.hint,
    required this.enabled,
    required this.boardSize,
    required this.theme,
    required this.onTap,
  });

  @override
  State<_Cell> createState() => _CellState();
}

class _CellState extends State<_Cell> with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.hint) _glow.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _Cell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hint && !_glow.isAnimating) {
      _glow.repeat(reverse: true);
    } else if (!widget.hint && _glow.isAnimating) {
      _glow.stop();
      _glow.value = 0;
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final markColor = widget.player == Player.x ? t.xColor : t.oColor;
    final radius =
        widget.boardSize <= 3 ? 12.0 : (widget.boardSize <= 5 ? 9.0 : 6.0);

    return GestureDetector(
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _glow,
        builder: (context, child) {
          final glowT = widget.hint ? _glow.value : 0.0;
          return Container(
            decoration: BoxDecoration(
              color: widget.winning
                  ? t.win.withOpacity(0.22)
                  : widget.hint
                      ? t.primary.withOpacity(0.15 + 0.25 * glowT)
                      : t.cell,
              borderRadius: BorderRadius.circular(radius),
              border: widget.winning
                  ? Border.all(color: t.win, width: 2.5)
                  : widget.hint
                      ? Border.all(
                          color: t.primary.withOpacity(0.6 + 0.4 * glowT),
                          width: 2.5,
                        )
                      : null,
              boxShadow: widget.hint
                  ? [
                      BoxShadow(
                        color: t.primary.withOpacity(0.3 * glowT),
                        blurRadius: 16 * glowT,
                      )
                    ]
                  : null,
            ),
            child: child,
          );
        },
        child: Center(
          child: AnimatedScale(
            scale: widget.player == Player.none ? 0 : 1,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  widget.player.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 40,
                    color: widget.winning ? t.win : markColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
