// Evaluates a finished game against all achievements and updates a profile.
import '../models/achievement.dart';
import '../models/user_profile.dart';
import '../models/game_models.dart';

/// Facts about a completed game, gathered by the game screen.
class GameResult {
  final bool isBotGame;
  final BotDifficulty? difficulty; // null for PvP
  final bool userWon; // did THIS profile win?
  final int finalBoardSize; // 3, 5, 7, ...
  final int userMoves; // how many moves this user made
  final bool usedHint;
  final bool usedUndo;

  const GameResult({
    required this.isBotGame,
    required this.difficulty,
    required this.userWon,
    required this.finalBoardSize,
    required this.userMoves,
    required this.usedHint,
    required this.usedUndo,
  });
}

class AchievementEngine {
  /// Applies the result to [p], returns the list of newly-unlocked defs.
  static List<AchievementDef> apply(UserProfile p, GameResult r) {
    final newlyUnlocked = <AchievementDef>[];

    void bump(AchId id, int by) {
      if (by <= 0) return;
      if (p.isUnlocked(id)) return;
      final def = Achievements.byId(id);
      final cur = (p.achProgress[id.name] ?? 0) + by;
      p.achProgress[id.name] = cur;
      if (cur >= def.target) {
        p.achUnlocked.add(id.name);
        newlyUnlocked.add(def);
      }
    }

    void unlock(AchId id) {
      if (p.isUnlocked(id)) return;
      final def = Achievements.byId(id);
      p.achProgress[id.name] = def.target;
      p.achUnlocked.add(id.name);
      newlyUnlocked.add(def);
    }

    // --- Daily streak (counts on any game played) ---
    _updateDailyStreak(p);
    if (p.dayStreak >= 3) unlock(AchId.dailyStreak3);

    // --- Milestone: total games played (any game) ---
    bump(AchId.play10Games, 1);

    if (r.userWon) {
      // Milestone: total wins.
      bump(AchId.win50Games, 1);

      // Board-size achievements.
      if (r.finalBoardSize >= 7) {
        unlock(AchId.win7x7);
      }
      if (r.finalBoardSize >= 5) {
        unlock(AchId.win5x5);
      }
      if (r.finalBoardSize == 3) {
        unlock(AchId.winNoExpand);
      }

      // Speed / skill.
      if (r.userMoves > 0 && r.userMoves <= 10) {
        unlock(AchId.winUnder10Moves);
      }
      if (!r.usedHint) {
        unlock(AchId.winNoHint);
      }

      // Bot-specific wins.
      if (r.isBotGame) {
        switch (r.difficulty) {
          case BotDifficulty.beginner:
            bump(AchId.beatBeginner5, 1);
            break;
          case BotDifficulty.medium:
            bump(AchId.beatMedium3, 1);
            break;
          case BotDifficulty.hard:
            unlock(AchId.beatHard1);
            if (!r.usedUndo) unlock(AchId.beatHardNoUndo);
            break;
          case null:
            break;
        }
        // Streak achievement uses the profile's current bot streak.
        if (p.botCurrentStreak >= 3) {
          unlock(AchId.beatStreak3);
        }
      }
    }

    return newlyUnlocked;
  }

  static void _updateDailyStreak(UserProfile p) {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (p.lastPlayedDay == today) return; // already counted today

    if (p.lastPlayedDay != null) {
      final parts = p.lastPlayedDay!.split('-');
      final last = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final yesterday = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 1));
      if (last.year == yesterday.year &&
          last.month == yesterday.month &&
          last.day == yesterday.day) {
        p.dayStreak += 1;
      } else {
        p.dayStreak = 1; // streak broken, restart
      }
    } else {
      p.dayStreak = 1;
    }
    p.lastPlayedDay = today;
  }

  /// Returns the active (in-progress, not-unlocked) achievements to surface,
  /// limited to [Achievements.activeWindow], ordered by their `order`.
  static List<AchievementDef> activeFor(UserProfile p) {
    final inProgress = Achievements.all
        .where((a) => !p.isUnlocked(a.id))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return inProgress.take(Achievements.activeWindow).toList();
  }
}
