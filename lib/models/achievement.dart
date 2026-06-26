// Achievement definitions + per-user progress.
//
// Each achievement has a target count; progress accumulates and unlocks at
// target. We surface only a few "active" (not-yet-unlocked) ones at a time so
// the player isn't overwhelmed, while still tracking all in the background.

import 'package:flutter/material.dart';

enum AchId {
  beatBeginner5,
  beatMedium3,
  beatHard1,
  beatStreak3,
  win5x5,
  win7x7,
  winNoExpand,
  winUnder10Moves,
  winNoHint,
  beatHardNoUndo,
  play10Games,
  win50Games,
  dailyStreak3,
}

class AchievementDef {
  final AchId id;
  final String title;
  final String description;
  final IconData icon;
  final int target;

  /// Display order / unlock order. Lower = surfaced earlier.
  final int order;

  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.target,
    required this.order,
  });
}

class Achievements {
  static const List<AchievementDef> all = [
    // --- Beat the bot (easiest first) ---
    AchievementDef(
      id: AchId.beatBeginner5,
      title: 'Rookie Slayer',
      description: 'Beat the Beginner bot 5 times',
      icon: Icons.sports_esports_rounded,
      target: 5,
      order: 1,
    ),
    AchievementDef(
      id: AchId.beatMedium3,
      title: 'Rising Star',
      description: 'Beat the Medium bot 3 times',
      icon: Icons.trending_up_rounded,
      target: 3,
      order: 2,
    ),
    AchievementDef(
      id: AchId.beatHard1,
      title: 'Giant Killer',
      description: 'Beat the Hard bot once',
      icon: Icons.local_fire_department_rounded,
      target: 1,
      order: 3,
    ),
    AchievementDef(
      id: AchId.beatStreak3,
      title: 'On Fire',
      description: 'Beat the bot 3 times in a row',
      icon: Icons.whatshot_rounded,
      target: 3,
      order: 4,
    ),
    // --- Expanding board (the unique twist) ---
    AchievementDef(
      id: AchId.win5x5,
      title: 'Grid Bender',
      description: 'Win on a 5×5 board',
      icon: Icons.grid_4x4_rounded,
      target: 1,
      order: 5,
    ),
    AchievementDef(
      id: AchId.win7x7,
      title: 'Marathon Master',
      description: 'Win on a 7×7 board',
      icon: Icons.grid_on_rounded,
      target: 1,
      order: 6,
    ),
    AchievementDef(
      id: AchId.winNoExpand,
      title: 'Quick Finisher',
      description: 'Win on the 3×3 board (no expansion)',
      icon: Icons.bolt_rounded,
      target: 1,
      order: 7,
    ),
    // --- Speed / skill ---
    AchievementDef(
      id: AchId.winUnder10Moves,
      title: 'Efficient',
      description: 'Win within 10 of your moves',
      icon: Icons.speed_rounded,
      target: 1,
      order: 8,
    ),
    AchievementDef(
      id: AchId.winNoHint,
      title: 'No Help Needed',
      description: 'Win a game without using Hint',
      icon: Icons.visibility_off_rounded,
      target: 1,
      order: 9,
    ),
    AchievementDef(
      id: AchId.beatHardNoUndo,
      title: 'Flawless',
      description: 'Beat the Hard bot without Undo',
      icon: Icons.workspace_premium_rounded,
      target: 1,
      order: 10,
    ),
    // --- Milestones ---
    AchievementDef(
      id: AchId.play10Games,
      title: 'Getting Started',
      description: 'Play 10 games total',
      icon: Icons.videogame_asset_rounded,
      target: 10,
      order: 11,
    ),
    AchievementDef(
      id: AchId.win50Games,
      title: 'Champion',
      description: 'Win 50 games total',
      icon: Icons.emoji_events_rounded,
      target: 50,
      order: 12,
    ),
    AchievementDef(
      id: AchId.dailyStreak3,
      title: 'Regular',
      description: 'Play on 3 different days in a row',
      icon: Icons.calendar_month_rounded,
      target: 3,
      order: 13,
    ),
  ];

  static AchievementDef byId(AchId id) =>
      all.firstWhere((a) => a.id == id);

  /// How many active (in-progress, not unlocked) achievements to show at once.
  static const int activeWindow = 4;
}
