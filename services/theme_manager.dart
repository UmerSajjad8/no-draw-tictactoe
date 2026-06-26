import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/board_theme.dart';

class ThemeManager extends ChangeNotifier {
  ThemeManager._();
  static final ThemeManager instance = ThemeManager._();

  static const _kTheme = 'board_theme';
  static const _kSound = 'sound_enabled';

  BoardTheme theme = BoardTheme.dark;
  bool soundEnabled = true;
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_kTheme);
    if (idx != null && idx >= 0 && idx < BoardThemeId.values.length) {
      theme = BoardTheme.byId(BoardThemeId.values[idx]);
    }
    soundEnabled = prefs.getBool(_kSound) ?? true;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setTheme(BoardTheme t) async {
    theme = t;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTheme, t.id.index);
    notifyListeners();
  }

  Future<void> setSound(bool on) async {
    soundEnabled = on;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSound, on);
    notifyListeners();
  }
}
