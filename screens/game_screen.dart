import 'dart:async';

import 'package:flutter/material.dart';

import '../bot/bot_player.dart';
import '../logic/game_controller.dart';
import '../models/game_models.dart';
import '../services/ads_service.dart';
import '../services/profile_manager.dart';
import '../services/sfx.dart';
import '../services/theme_manager.dart';
import '../logic/achievement_engine.dart';
import '../models/achievement.dart';
import '../widgets/board_theme.dart';
import '../widgets/app_theme.dart';
import '../widgets/board_view.dart';
import '../widgets/scoreboard.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  final BotDifficulty difficulty;

  /// For PvP: the two player names. For bot: nameX is the human, nameO unused.
  final String nameX;
  final String nameO;

  /// Profile ids to record results against (null = don't record).
  final String? profileIdX;
  final String? profileIdO;

  const GameScreen({
    super.key,
    required this.mode,
    required this.difficulty,
    this.nameX = 'Player X',
    this.nameO = 'Player O',
    this.profileIdX,
    this.profileIdO,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GameController _game = GameController(startSize: 3);
  late BotPlayer _bot;

  int _expansionTick = 0;
  bool _botThinking = false;
  String? _banner;
  Timer? _bannerTimer;
  List<int>? _hintCell;
  int _winStreak = 0;
  bool _usedHint = false;
  bool _usedUndo = false;
  int _userMoves = 0;

  bool get _isBotGame => widget.mode == GameMode.pvb;

  @override
  void initState() {
    super.initState();
    _winStreak = _startStreak();
    _bot = BotPlayer(
      difficulty: widget.difficulty,
      me: Player.o,
      winStreak: _winStreak,
    );
  }

  int _startStreak() {
    if (!_isBotGame || widget.profileIdX == null) return 0;
    final p = ProfileManager.instance.current;
    return p?.botCurrentStreak ?? 0;
  }

  void _flash(String msg) {
    _bannerTimer?.cancel();
    setState(() => _banner = msg);
    _bannerTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _banner = null);
    });
  }

  Future<void> _handleTap(int r, int c) async {
    if (_botThinking) return;
    setState(() => _hintCell = null); // clear hint on any move
    final before = _game.board.size;
    final outcome = _game.play(r, c);
    if (!outcome.placed) return;
    _userMoves++;
    Sfx.instance.tap();

    if (_game.board.size != before) {
      _expansionTick++;
      Sfx.instance.expand();
      _flash('No winner — grid expanded to '
          '${_game.board.size}×${_game.board.size}!');
    }

    setState(() {});

    if (outcome.win.hasWinner) {
      _onWin(outcome.win.winner);
      return;
    }

    if (_isBotGame && _game.current == _bot.me && !_game.gameOver) {
      await _runBotTurn();
    }
  }

  Future<void> _runBotTurn() async {
    setState(() => _botThinking = true);
    await Future.delayed(const Duration(milliseconds: 300));

    while (_isBotGame && _game.current == _bot.me && !_game.gameOver) {
      final move = _bot.chooseMove(_game.board);
      final before = _game.board.size;
      final outcome = _game.play(move[0], move[1]);
      Sfx.instance.tap();

      if (_game.board.size != before) {
        _expansionTick++;
        Sfx.instance.expand();
        _flash('No winner — grid expanded to '
            '${_game.board.size}×${_game.board.size}!');
      }

      if (mounted) setState(() {});

      if (outcome.win.hasWinner) {
        if (mounted) {
          setState(() => _botThinking = false);
          _onWin(outcome.win.winner);
        }
        return;
      }
      if (_game.current != _bot.me) break;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (mounted) setState(() => _botThinking = false);
  }

  Future<void> _onWin(Player winner) async {
    final mgr = ProfileManager.instance;
    final unlocked = <AchievementDef>[];
    final size = _game.board.size;

    if (_isBotGame) {
      final humanWon = winner == Player.x;
      _winStreak = humanWon ? _winStreak + 1 : 0;
      _bot = BotPlayer(
        difficulty: widget.difficulty,
        me: Player.o,
        winStreak: _winStreak,
      );
      if (widget.profileIdX != null) {
        final p = mgr.current;
        if (p != null && p.id == widget.profileIdX) {
          p.recordBotResult(won: humanWon);
          unlocked.addAll(AchievementEngine.apply(
            p,
            GameResult(
              isBotGame: true,
              difficulty: widget.difficulty,
              userWon: humanWon,
              finalBoardSize: size,
              userMoves: _userMoves,
              usedHint: _usedHint,
              usedUndo: _usedUndo,
            ),
          ));
          await mgr.save();
        }
      }
    } else {
      // PvP: record + evaluate achievements for each participating profile.
      for (final p in mgr.profiles) {
        final isX = p.id == widget.profileIdX;
        final isO = p.id == widget.profileIdO;
        if (!isX && !isO) continue;
        final won = (isX && winner == Player.x) || (isO && winner == Player.o);
        p.recordPvpResult(won: won);
        // Moves count only meaningful for whoever we tracked as X; for O we
        // pass a large number so the "win under 10 moves" only credits X.
        final moves = isX ? _userMoves : 9999;
        unlocked.addAll(AchievementEngine.apply(
          p,
          GameResult(
            isBotGame: false,
            difficulty: null,
            userWon: won,
            finalBoardSize: size,
            userMoves: moves,
            usedHint: _usedHint,
            usedUndo: _usedUndo,
          ),
        ));
      }
      if (widget.profileIdX != null || widget.profileIdO != null) {
        await mgr.save();
      }
    }

    Sfx.instance.win();
    // Let the winning move + winning-line highlight render before the dialog,
    // so the bot's last move is clearly visible when you lose.
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) _showGameOver(winner, unlocked);
  }

  void _newRound() {
    setState(() {
      _game.resetRound(startSize: 3);
      _expansionTick = 0;
      _botThinking = false;
      _hintCell = null;
      _usedHint = false;
      _usedUndo = false;
      _userMoves = 0;
    });
  }

  // ---- Undo: removes the player's last move; bot's move auto-removed too. ----
  void _requestUndo() {
    if (_game.gameOver || _botThinking) return;
    AdsService.instance.showRewarded(onReward: () {
      if (_isBotGame) {
        // On the human's turn, the most recent move is the bot's (O) and the
        // one before is the human's (X). Remove both so X plays again.
        var removed = false;
        if (_game.lastMoveOwner() == Player.o) {
          _game.undoLast(); // bot's move
          removed = true;
        }
        if (_game.lastMoveOwner() == Player.x) {
          _game.undoLast(); // human's move
          removed = true;
        }
        if (removed) _usedUndo = true;
        setState(() => _hintCell = null);
        _flash(removed ? 'Move undone' : 'Nothing to undo');
      } else {
        final undone = _game.undoLast();
        if (undone != null) _usedUndo = true;
        setState(() => _hintCell = null);
        _flash(undone == null ? 'Nothing to undo' : 'Move undone');
      }
    });
  }

  // ---- Hint: highlight the actual best move on the board. ----
  void _requestHint() {
    if (_game.gameOver || _botThinking) return;
    AdsService.instance.showRewarded(onReward: () {
      final helper =
          BotPlayer(difficulty: BotDifficulty.hard, me: _game.current);
      final move = helper.chooseMove(_game.board);
      _usedHint = true;
      setState(() => _hintCell = move);
      _flash('Hint: highlighted square is a strong move');
    });
  }

  void _showGameOver(Player winner, List<AchievementDef> unlocked) {
    final winnerName = winner == Player.x ? widget.nameX : widget.nameO;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GameOverDialog(
        winnerName: _isBotGame && winner == Player.o ? 'Bot' : winnerName,
        winner: winner,
        streak: _isBotGame ? _winStreak : 0,
        unlocked: unlocked,
        onPlayAgain: () {
          Navigator.of(context).pop();
          _newRound();
        },
        onHome: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final interaction = !_botThinking &&
        !_game.gameOver &&
        !(_isBotGame && _game.current == _bot.me);

    final labelO = _isBotGame ? 'Bot (O)' : widget.nameO;
    final labelX = widget.nameX;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          _isBotGame
              ? 'vs Bot · ${widget.difficulty.name[0].toUpperCase()}'
                  '${widget.difficulty.name.substring(1)}'
              : 'Local Multiplayer',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Scoreboard(
                scoreX: _game.scoreX,
                scoreO: _game.scoreO,
                current: _game.current,
                labelX: labelX,
                labelO: labelO,
              ),
              const SizedBox(height: 12),
              _StatusBar(
                text: _banner ??
                    (_botThinking
                        ? 'Bot is thinking…'
                        : '${_game.current == Player.x ? labelX : labelO} '
                            'to move · ${_game.board.size}×${_game.board.size}'),
                highlight: _banner != null,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: BoardView(
                    board: _game.board,
                    win: _game.lastWin,
                    interactionEnabled: interaction,
                    expansionTick: _expansionTick,
                    hintCell: _hintCell,
                    theme: ThemeManager.instance.theme,
                    onTap: _handleTap,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.lightbulb_outline_rounded),
                      label: const Text('Hint'),
                      onPressed: _requestHint,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.undo_rounded),
                      label: const Text('Undo'),
                      onPressed: _requestUndo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Restart'),
                      onPressed: _newRound,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final String text;
  final bool highlight;
  const _StatusBar({required this.text, required this.highlight});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withOpacity(0.18)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight ? AppColors.primary : Colors.transparent,
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: highlight ? AppColors.text : AppColors.textDim,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GameOverDialog extends StatefulWidget {
  final String winnerName;
  final Player winner;
  final int streak;
  final List<AchievementDef> unlocked;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;

  const _GameOverDialog({
    required this.winnerName,
    required this.winner,
    required this.streak,
    required this.unlocked,
    required this.onPlayAgain,
    required this.onHome,
  });

  @override
  State<_GameOverDialog> createState() => _GameOverDialogState();
}

class _GameOverDialogState extends State<_GameOverDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    if (widget.unlocked.isNotEmpty) {
      // Celebratory sound for unlocks.
      Sfx.instance.win();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.winner == Player.x ? AppColors.xColor : AppColors.oColor;
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_rounded, size: 64, color: AppColors.win),
            const SizedBox(height: 16),
            Text(
              '${widget.winnerName} Wins!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.streak >= 2
                  ? 'Win streak: ${widget.streak} 🔥 The bot is getting tougher!'
                  : 'A winner emerged — exactly as intended.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textDim),
            ),
            if (widget.unlocked.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'ACHIEVEMENT UNLOCKED',
                style: TextStyle(
                  color: AppColors.win,
                  letterSpacing: 1.5,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              ...widget.unlocked.asMap().entries.map((e) {
                final i = e.key;
                final def = e.value;
                final anim = CurvedAnimation(
                  parent: _ctrl,
                  curve: Interval(
                    (i / (widget.unlocked.length + 1)).clamp(0.0, 1.0),
                    1.0,
                    curve: Curves.elasticOut,
                  ),
                );
                return ScaleTransition(
                  scale: anim,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.win.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.win.withOpacity(0.5), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(def.icon, color: AppColors.win, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(def.title,
                                  style: const TextStyle(
                                      color: AppColors.text,
                                      fontWeight: FontWeight.bold)),
                              Text(def.description,
                                  style: const TextStyle(
                                      color: AppColors.textDim, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onPlayAgain,
                child: const Text('Play Again'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: widget.onHome,
                child: const Text('Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
