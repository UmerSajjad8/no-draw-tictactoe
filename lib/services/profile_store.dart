// Persists the list of user profiles + the currently-selected user id.
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class ProfileStore {
  static const _kProfiles = 'profiles_v1';
  static const _kCurrent = 'current_profile_id';

  Future<List<UserProfile>> loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kProfiles);
    if (raw == null || raw.isEmpty) return [];
    try {
      return UserProfile.decodeList(raw);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveProfiles(List<UserProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfiles, UserProfile.encodeList(profiles));
  }

  Future<String?> loadCurrentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kCurrent);
  }

  Future<void> saveCurrentId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_kCurrent);
    } else {
      await prefs.setString(_kCurrent, id);
    }
  }
}
