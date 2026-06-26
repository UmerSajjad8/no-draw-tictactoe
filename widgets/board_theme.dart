// Selectable board themes (Classic, Dark, Neon).
import 'package:flutter/material.dart';

enum BoardThemeId { classic, dark, neon }

class BoardTheme {
  final BoardThemeId id;
  final String name;
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color cell;
  final Color xColor;
  final Color oColor;
  final Color win;
  final Color primary;
  final Color text;
  final Color textDim;

  const BoardTheme({
    required this.id,
    required this.name,
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.cell,
    required this.xColor,
    required this.oColor,
    required this.win,
    required this.primary,
    required this.text,
    required this.textDim,
  });

  static const classic = BoardTheme(
    id: BoardThemeId.classic,
    name: 'Classic',
    bg: Color(0xFFF4F1EA),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEDE8DD),
    cell: Color(0xFFEDE8DD),
    xColor: Color(0xFF2D6CDF),
    oColor: Color(0xFFE5484D),
    win: Color(0xFFF5A623),
    primary: Color(0xFF2D6CDF),
    text: Color(0xFF1B1B1B),
    textDim: Color(0xFF6B6B6B),
  );

  static const dark = BoardTheme(
    id: BoardThemeId.dark,
    name: 'Dark',
    bg: Color(0xFF0E1116),
    surface: Color(0xFF181D26),
    surfaceAlt: Color(0xFF222936),
    cell: Color(0xFF222936),
    xColor: Color(0xFF4FD1C5),
    oColor: Color(0xFFFF7AB6),
    win: Color(0xFFFFD166),
    primary: Color(0xFF5B8CFF),
    text: Color(0xFFEAF0FA),
    textDim: Color(0xFF93A1B5),
  );

  static const neon = BoardTheme(
    id: BoardThemeId.neon,
    name: 'Neon',
    bg: Color(0xFF06010F),
    surface: Color(0xFF140A24),
    surfaceAlt: Color(0xFF1F0F3A),
    cell: Color(0xFF1A0E30),
    xColor: Color(0xFF00F5D4),
    oColor: Color(0xFFFF2E97),
    win: Color(0xFFFFE600),
    primary: Color(0xFFB14EFF),
    text: Color(0xFFF2E9FF),
    textDim: Color(0xFF9A7FC2),
  );

  static const all = [classic, dark, neon];

  static BoardTheme byId(BoardThemeId id) =>
      all.firstWhere((t) => t.id == id, orElse: () => dark);
}
