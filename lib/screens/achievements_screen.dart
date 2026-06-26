import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../logic/achievement_engine.dart';
import '../services/profile_manager.dart';
import '../widgets/app_theme.dart';

class AchievementsScreen extends StatelessWidget {
  final String profileId;
  const AchievementsScreen({super.key, required this.profileId});

  @override
  Widget build(BuildContext context) {
    final matches =
        ProfileManager.instance.profiles.where((e) => e.id == profileId);
    final p = matches.isEmpty ? null : matches.first;
    if (p == null) {
      return const Scaffold(body: Center(child: Text('Player not found')));
    }

    final unlocked =
        Achievements.all.where((a) => p.isUnlocked(a.id)).toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    final active = AchievementEngine.activeFor(p);
    final activeIds = active.map((a) => a.id).toSet();
    final locked = Achievements.all
        .where((a) =>
            !p.isUnlocked(a.id) && !activeIds.contains(a.id))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('${p.name} · Achievements'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _summary(unlocked.length, Achievements.all.length, p.dayStreak),
            const SizedBox(height: 20),
            if (active.isNotEmpty) ...[
              _section('IN PROGRESS'),
              ...active.map((a) => _tile(a, p.progressOf(a.id), false)),
              const SizedBox(height: 20),
            ],
            if (unlocked.isNotEmpty) ...[
              _section('UNLOCKED'),
              ...unlocked.map((a) => _tile(a, a.target, true)),
              const SizedBox(height: 20),
            ],
            if (locked.isNotEmpty) ...[
              _section('LOCKED'),
              ...locked.map((a) => _tile(a, 0, false, dim: true)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summary(int done, int total, int dayStreak) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat('$done/$total', 'Unlocked', AppColors.win),
            _stat('$dayStreak', 'Day streak', AppColors.primary),
          ],
        ),
      );

  Widget _stat(String value, String label, Color color) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 24, fontWeight: FontWeight.w900)),
          Text(label,
              style: TextStyle(color: AppColors.textDim, fontSize: 12)),
        ],
      );

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(t,
            style: TextStyle(
              color: AppColors.textDim,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            )),
      );

  Widget _tile(AchievementDef a, int progress, bool unlocked,
      {bool dim = false}) {
    final ratio =
        a.target == 0 ? 0.0 : (progress / a.target).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: unlocked
            ? Border.all(color: AppColors.win.withOpacity(0.6), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: unlocked
                  ? AppColors.win.withOpacity(0.15)
                  : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              unlocked ? a.icon : (dim ? Icons.lock_outline_rounded : a.icon),
              color: unlocked
                  ? AppColors.win
                  : (dim ? AppColors.textDim : AppColors.primary),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title,
                    style: TextStyle(
                      color: dim ? AppColors.textDim : AppColors.text,
                      fontWeight: FontWeight.bold,
                    )),
                Text(a.description,
                    style: TextStyle(
                        color: AppColors.textDim, fontSize: 12)),
                if (!unlocked && !dim && a.target > 1) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceAlt,
                      valueColor: AlwaysStoppedAnimation(
                          AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$progress / ${a.target}',
                      style: TextStyle(
                          color: AppColors.textDim, fontSize: 11)),
                ],
              ],
            ),
          ),
          if (unlocked)
            Icon(Icons.check_circle_rounded, color: AppColors.win),
        ],
      ),
    );
  }
}
