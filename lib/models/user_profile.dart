import 'dart:convert';
import 'achievement.dart';

class UserProfile {
  final String id;
  String name;

  int botWins;
  int botLosses;
  int botBestStreak;
  int botCurrentStreak;

  int pvpWins;
  int pvpLosses;

  // Achievement progress: AchId.name -> current count.
  final Map<String, int> achProgress;
  // Unlocked achievements: set of AchId.name.
  final Set<String> achUnlocked;

  // Daily-streak tracking.
  String? lastPlayedDay; // 'yyyy-mm-dd'
  int dayStreak;

  UserProfile({
    required this.id,
    required this.name,
    this.botWins = 0,
    this.botLosses = 0,
    this.botBestStreak = 0,
    this.botCurrentStreak = 0,
    this.pvpWins = 0,
    this.pvpLosses = 0,
    Map<String, int>? achProgress,
    Set<String>? achUnlocked,
    this.lastPlayedDay,
    this.dayStreak = 0,
  })  : achProgress = achProgress ?? {},
        achUnlocked = achUnlocked ?? {};

  int get botGames => botWins + botLosses;
  int get pvpGames => pvpWins + pvpLosses;
  int get totalWins => botWins + pvpWins;
  int get totalGames => botGames + pvpGames;

  int progressOf(AchId id) => achProgress[id.name] ?? 0;
  bool isUnlocked(AchId id) => achUnlocked.contains(id.name);

  void recordBotResult({required bool won}) {
    if (won) {
      botWins++;
      botCurrentStreak++;
      if (botCurrentStreak > botBestStreak) botBestStreak = botCurrentStreak;
    } else {
      botLosses++;
      botCurrentStreak = 0;
    }
  }

  void recordPvpResult({required bool won}) {
    if (won) {
      pvpWins++;
    } else {
      pvpLosses++;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'botWins': botWins,
        'botLosses': botLosses,
        'botBestStreak': botBestStreak,
        'botCurrentStreak': botCurrentStreak,
        'pvpWins': pvpWins,
        'pvpLosses': pvpLosses,
        'achProgress': achProgress,
        'achUnlocked': achUnlocked.toList(),
        'lastPlayedDay': lastPlayedDay,
        'dayStreak': dayStreak,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id: j['id'] as String,
        name: j['name'] as String,
        botWins: (j['botWins'] ?? 0) as int,
        botLosses: (j['botLosses'] ?? 0) as int,
        botBestStreak: (j['botBestStreak'] ?? 0) as int,
        botCurrentStreak: (j['botCurrentStreak'] ?? 0) as int,
        pvpWins: (j['pvpWins'] ?? 0) as int,
        pvpLosses: (j['pvpLosses'] ?? 0) as int,
        achProgress: (j['achProgress'] as Map?)
                ?.map((k, v) => MapEntry(k as String, (v as num).toInt())) ??
            {},
        achUnlocked: ((j['achUnlocked'] as List?) ?? [])
            .map((e) => e as String)
            .toSet(),
        lastPlayedDay: j['lastPlayedDay'] as String?,
        dayStreak: (j['dayStreak'] ?? 0) as int,
      );

  static String encodeList(List<UserProfile> list) =>
      jsonEncode(list.map((p) => p.toJson()).toList());

  static List<UserProfile> decodeList(String raw) {
    final data = jsonDecode(raw) as List<dynamic>;
    return data
        .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
