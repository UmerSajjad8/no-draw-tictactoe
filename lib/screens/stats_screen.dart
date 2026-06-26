import 'package:flutter/material.dart';
import '../services/profile_manager.dart';
import '../widgets/app_theme.dart';

class StatsScreen extends StatelessWidget {
  final String profileId;
  const StatsScreen({super.key, required this.profileId});

  @override
  Widget build(BuildContext context) {
    final matches =
        ProfileManager.instance.profiles.where((e) => e.id == profileId);
    final p = matches.isEmpty ? null : matches.first;

    if (p == null) {
      return const Scaffold(body: Center(child: Text('Player not found')));
    }

    final botWinRate =
        p.botGames == 0 ? 0 : ((p.botWins / p.botGames) * 100).round();
    final pvpWinRate =
        p.pvpGames == 0 ? 0 : ((p.pvpWins / p.pvpGames) * 100).round();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('${p.name} · Stats'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _section('VS BOT'),
            _statRow('Wins', '${p.botWins}', AppColors.xColor),
            _statRow('Losses', '${p.botLosses}', AppColors.oColor),
            _statRow('Games', '${p.botGames}', AppColors.text),
            _statRow('Win rate', '$botWinRate%', AppColors.primary),
            _statRow('Current streak', '${p.botCurrentStreak}', AppColors.win),
            _statRow('Best streak', '${p.botBestStreak}', AppColors.win),
            const SizedBox(height: 24),
            _section('VS PLAYER (LOCAL)'),
            _statRow('Wins', '${p.pvpWins}', AppColors.xColor),
            _statRow('Losses', '${p.pvpLosses}', AppColors.oColor),
            _statRow('Games', '${p.pvpGames}', AppColors.text),
            _statRow('Win rate', '$pvpWinRate%', AppColors.primary),
            const SizedBox(height: 24),
            _section('OVERALL'),
            _statRow('Total wins', '${p.totalWins}', AppColors.xColor),
            _statRow('Total games', '${p.totalGames}', AppColors.text),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(title,
            style: TextStyle(
              color: AppColors.textDim,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            )),
      );

  Widget _statRow(String label, String value, Color color) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: AppColors.textDim)),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ],
        ),
      );
}
