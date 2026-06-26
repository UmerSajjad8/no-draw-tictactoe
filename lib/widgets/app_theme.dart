// AppColors is a live holder that mirrors the currently selected BoardTheme.
// Every screen reads AppColors.*, so switching theme recolors the whole app.
import 'package:flutter/material.dart';
import 'board_theme.dart';

class AppColors {
  static BoardTheme _t = BoardTheme.light;

  static void apply(BoardTheme theme) => _t = theme;

  static Color get bg => _t.bg;
  static Color get surface => _t.surface;
  static Color get surfaceAlt => _t.surfaceAlt;
  static Color get primary => _t.primary;
  static Color get xColor => _t.xColor;
  static Color get oColor => _t.oColor;
  static Color get win => _t.win;
  static Color get text => _t.text;
  static Color get textDim => _t.textDim;
}

ThemeData buildAppTheme() => BoardTheme.light.toThemeData();
