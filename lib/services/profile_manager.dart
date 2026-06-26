// In-memory manager for user profiles, backed by ProfileStore.
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import 'profile_store.dart';

class ProfileManager extends ChangeNotifier {
  ProfileManager._();
  static final ProfileManager instance = ProfileManager._();

  final ProfileStore _store = ProfileStore();
  List<UserProfile> profiles = [];
  String? currentId;

  bool _loaded = false;

  UserProfile? get current {
    for (final p in profiles) {
      if (p.id == currentId) return p;
    }
    return null;
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    profiles = await _store.loadProfiles();
    currentId = await _store.loadCurrentId();
    if (current == null && profiles.isNotEmpty) {
      currentId = profiles.first.id;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<UserProfile> addProfile(String name) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final p = UserProfile(id: id, name: name.trim());
    profiles.add(p);
    currentId ??= p.id;
    await _persist();
    notifyListeners();
    return p;
  }

  Future<void> deleteProfile(String id) async {
    profiles.removeWhere((p) => p.id == id);
    if (currentId == id) {
      currentId = profiles.isNotEmpty ? profiles.first.id : null;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> selectProfile(String id) async {
    currentId = id;
    await _store.saveCurrentId(id);
    notifyListeners();
  }

  Future<void> save() async {
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await _store.saveProfiles(profiles);
    await _store.saveCurrentId(currentId);
  }
}
