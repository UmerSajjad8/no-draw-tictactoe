// lib/services/score_store.dart
//
// Persists cumulative scores across app launches with SharedPreferences.

import 'package:shared_preferences/shared_preferences.dart';

class ScoreStore {
  static const _kX = 'score_x';
  static const _kO = 'score_o';

  Future<(int, int)> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_kX) ?? 0, prefs.getInt(_kO) ?? 0);
  }

  Future<void> save(int x, int o) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kX, x);
    await prefs.setInt(_kO, o);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kX);
    await prefs.remove(_kO);
  }
}
