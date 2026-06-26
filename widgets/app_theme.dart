// lib/widgets/app_theme.dart
//
// Centralized design tokens for a clean, modern look.

import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0E1116);
  static const surface = Color(0xFF181D26);
  static const surfaceAlt = Color(0xFF222936);
  static const primary = Color(0xFF5B8CFF);
  static const xColor = Color(0xFF4FD1C5); // teal
  static const oColor = Color(0xFFFF7AB6); // pink
  static const win = Color(0xFFFFD166);
  static const text = Color(0xFFEAF0FA);
  static const textDim = Color(0xFF93A1B5);
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.primary,
      surface: AppColors.surface,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
