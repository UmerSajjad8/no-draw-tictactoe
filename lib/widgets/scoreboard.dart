// lib/widgets/scoreboard.dart

import 'package:flutter/material.dart';
import '../models/game_models.dart';
import 'app_theme.dart';

class Scoreboard extends StatelessWidget {
  final int scoreX;
  final int scoreO;
  final Player current;
  final String labelX;
  final String labelO;

  const Scoreboard({
    super.key,
    required this.scoreX,
    required this.scoreO,
    required this.current,
    this.labelX = 'Player X',
    this.labelO = 'Player O',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ScoreCard(
            label: labelX,
            score: scoreX,
            color: AppColors.xColor,
            active: current == Player.x,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ScoreCard(
            label: labelO,
            score: scoreO,
            color: AppColors.oColor,
            active: current == Player.o,
          ),
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  final bool active;

  const _ScoreCard({
    required this.label,
    required this.score,
    required this.color,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active ? color : Colors.transparent,
          width: 2,
        ),
        boxShadow: active
            ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 16)]
            : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
