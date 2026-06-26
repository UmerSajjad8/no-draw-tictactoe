// App-wide themes: Light (default) and Dark.
// One BoardTheme drives colors for EVERY screen (home, board, dialogs).
import 'package:flutter/material.dart';

enum BoardThemeId { light, dark }

class BoardTheme {
  final BoardThemeId id;
  final String name;
  final Brightness brightness;
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
    required this.brightness,
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

  static const light = BoardTheme(
    id: BoardThemeId.light,
    name: 'Light',
    brightness: Brightness.light,
    bg: Color(0xFFF5F7FB),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEAEEF5),
    cell: Color(0xFFEAEEF5),
    xColor: Color(0xFF1E88E5),
    oColor: Color(0xFFE5397A),
    win: Color(0xFFF5A623),
    primary: Color(0xFF3D6CF0),
    text: Color(0xFF16202E),
    textDim: Color(0xFF6B7A8D),
  );

  static const dark = BoardTheme(
    id: BoardThemeId.dark,
    name: 'Dark',
    brightness: Brightness.dark,
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

  static const all = [light, dark];

  static BoardTheme byId(BoardThemeId id) =>
      all.firstWhere((t) => t.id == id, orElse: () => light);

  /// Builds a Material ThemeData from this palette so every widget
  /// (AppBar, buttons, dialogs, switches) follows the theme.
  ThemeData toThemeData() {
    final base = brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        surface: surface,
        brightness: brightness,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: text,
        displayColor: text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: text,
        elevation: 0,
      ),
      iconTheme: IconThemeData(color: text),
      dialogBackgroundColor: surface,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: textDim.withOpacity(0.4)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
