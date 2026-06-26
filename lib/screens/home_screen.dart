import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/game_models.dart';
import '../models/user_profile.dart';
import '../services/ads_service.dart';
import '../services/profile_manager.dart';
import '../services/theme_manager.dart';
import '../services/sfx.dart';
import '../widgets/board_theme.dart';
import '../widgets/app_theme.dart';
import 'game_screen.dart';
import 'stats_screen.dart';
import 'achievements_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BannerAd? _banner;
  bool _bannerReady = false;
  BotDifficulty _difficulty = BotDifficulty.medium;
  final ProfileManager _pm = ProfileManager.instance;
  final ThemeManager _tm = ThemeManager.instance;

  @override
  void initState() {
    super.initState();
    _pm.addListener(_onProfiles);
    _tm.addListener(_onProfiles);
    _pm.ensureLoaded();
    _tm.ensureLoaded();
    if (!kIsWeb) _loadBanner();
  }

  void _onProfiles() {
    if (mounted) setState(() {});
  }

  void _loadBanner() {
    final banner = BannerAd(
      adUnitId: AdsService.instance.bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _bannerReady = true);
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    );
    banner.load();
    _banner = banner;
  }

  @override
  void dispose() {
    _pm.removeListener(_onProfiles);
    _tm.removeListener(_onProfiles);
    _banner?.dispose();
    super.dispose();
  }

  Future<void> _addUserDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('New player'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Enter name'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      await _pm.addProfile(name.trim());
    }
  }

  Future<void> _confirmDelete(UserProfile p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete ${p.name}?'),
        content: const Text('This removes the player and all their stats.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await _pm.deleteProfile(p.id);
  }

  void _startBot() {
    final cur = _pm.current;
    if (cur == null) {
      _needPlayerSnack();
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GameScreen(
        mode: GameMode.pvb,
        difficulty: _difficulty,
        nameX: cur.name,
        profileIdX: cur.id,
      ),
    ));
  }

  Future<void> _startPvp() async {
    if (_pm.profiles.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Add at least 2 players for local multiplayer.'),
      ));
      return;
    }
    // Pick two players.
    final picked = await showDialog<List<UserProfile>>(
      context: context,
      builder: (_) => _PvpPickerDialog(profiles: _pm.profiles),
    );
    if (picked == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GameScreen(
        mode: GameMode.pvp,
        difficulty: _difficulty,
        nameX: picked[0].name,
        nameO: picked[1].name,
        profileIdX: picked[0].id,
        profileIdO: picked[1].id,
      ),
    ));
  }

  void _needPlayerSnack() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Add a player first.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final profiles = _pm.profiles;
    final current = _pm.current;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    const _Logo(),
                    const SizedBox(height: 8),
                    Text(
                      'No draws. Ever.\nThe grid grows until someone wins.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textDim),
                    ),
                    const SizedBox(height: 24),

                    // ---- Players section ----
                    _PlayersCard(
                      profiles: profiles,
                      currentId: current?.id,
                      onSelect: (id) => _pm.selectProfile(id),
                      onAdd: _addUserDialog,
                      onDelete: _confirmDelete,
                      onStats: (p) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => StatsScreen(profileId: p.id),
                        ));
                      },
                      onAchievements: (p) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              AchievementsScreen(profileId: p.id),
                        ));
                      },
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.smart_toy_rounded),
                        label: Text(current == null
                            ? 'Player vs Bot'
                            : 'Play as ${current.name} vs Bot'),
                        onPressed: _startBot,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceAlt,
                        ),
                        icon: const Icon(Icons.people_alt_rounded),
                        label: const Text('Player vs Player'),
                        onPressed: _startPvp,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'BOT DIFFICULTY',
                      style: TextStyle(
                        color: AppColors.textDim,
                        letterSpacing: 1.5,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DifficultyPicker(
                      value: _difficulty,
                      onChanged: (d) => setState(() => _difficulty = d),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'APP THEME',
                      style: TextStyle(
                        color: AppColors.textDim,
                        letterSpacing: 1.5,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ThemePicker(
                      current: _tm.theme,
                      onPick: (t) => _tm.setTheme(t),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Sound & vibration',
                          style: TextStyle(color: AppColors.text)),
                      value: _tm.soundEnabled,
                      activeColor: AppColors.primary,
                      onChanged: (v) {
                        _tm.setSound(v);
                        Sfx.instance.enabled = v;
                        if (v) Sfx.instance.tap();
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (_bannerReady && _banner != null)
              SizedBox(
                height: _banner!.size.height.toDouble(),
                width: _banner!.size.width.toDouble(),
                child: AdWidget(ad: _banner!),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayersCard extends StatelessWidget {
  final List<UserProfile> profiles;
  final String? currentId;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<UserProfile> onDelete;
  final ValueChanged<UserProfile> onStats;
  final ValueChanged<UserProfile> onAchievements;

  const _PlayersCard({
    required this.profiles,
    required this.currentId,
    required this.onSelect,
    required this.onAdd,
    required this.onDelete,
    required this.onStats,
    required this.onAchievements,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PLAYERS',
                  style: TextStyle(
                    color: AppColors.textDim,
                    letterSpacing: 1.5,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  )),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          if (profiles.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No players yet. Tap "Add" to create one.',
                  style: TextStyle(color: AppColors.textDim)),
            )
          else
            ...profiles.map((p) {
              final selected = p.id == currentId;
              return Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ListTile(
                  onTap: () => onSelect(p.id),
                  leading: CircleAvatar(
                    backgroundColor:
                        selected ? AppColors.primary : AppColors.surface,
                    child: Text(
                      p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(p.name,
                      style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    'Bot: ${p.botWins}W-${p.botLosses}L · '
                    'Best streak ${p.botBestStreak}',
                    style: TextStyle(
                        color: AppColors.textDim, fontSize: 12),
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded,
                        color: AppColors.textDim),
                    color: AppColors.surfaceAlt,
                    onSelected: (v) {
                      if (v == 'ach') onAchievements(p);
                      if (v == 'stats') onStats(p);
                      if (v == 'delete') onDelete(p);
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'ach',
                        child: Row(children: [
                          Icon(Icons.emoji_events_outlined,
                              color: AppColors.win, size: 20),
                          SizedBox(width: 10),
                          Text('Achievements',
                              style: TextStyle(color: AppColors.text)),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'stats',
                        child: Row(children: [
                          Icon(Icons.bar_chart_rounded,
                              color: AppColors.primary, size: 20),
                          SizedBox(width: 10),
                          Text('Stats',
                              style: TextStyle(color: AppColors.text)),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline_rounded,
                              color: Colors.redAccent, size: 20),
                          SizedBox(width: 10),
                          Text('Delete',
                              style: TextStyle(color: AppColors.text)),
                        ]),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _PvpPickerDialog extends StatefulWidget {
  final List<UserProfile> profiles;
  const _PvpPickerDialog({required this.profiles});

  @override
  State<_PvpPickerDialog> createState() => _PvpPickerDialogState();
}

class _PvpPickerDialogState extends State<_PvpPickerDialog> {
  UserProfile? x;
  UserProfile? o;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Choose two players'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<UserProfile>(
            value: x,
            dropdownColor: AppColors.surfaceAlt,
            decoration: const InputDecoration(labelText: 'Player X'),
            items: widget.profiles
                .map((p) =>
                    DropdownMenuItem(value: p, child: Text(p.name)))
                .toList(),
            onChanged: (v) => setState(() => x = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<UserProfile>(
            value: o,
            dropdownColor: AppColors.surfaceAlt,
            decoration: const InputDecoration(labelText: 'Player O'),
            items: widget.profiles
                .map((p) =>
                    DropdownMenuItem(value: p, child: Text(p.name)))
                .toList(),
            onChanged: (v) => setState(() => o = v),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: (x != null && o != null && x != o)
              ? () => Navigator.pop(context, [x!, o!])
              : null,
          child: const Text('Start'),
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Icon(Icons.grid_3x3_rounded,
              size: 56, color: AppColors.primary),
        ),
        const SizedBox(height: 18),
        Text(
          'NO DRAW',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: AppColors.text,
          ),
        ),
        Text(
          'TIC TAC TOE',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 6,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _DifficultyPicker extends StatelessWidget {
  final BotDifficulty value;
  final ValueChanged<BotDifficulty> onChanged;

  const _DifficultyPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<BotDifficulty>(
      style: SegmentedButton.styleFrom(
        backgroundColor: AppColors.surface,
        selectedBackgroundColor: AppColors.primary,
        selectedForegroundColor: Colors.white,
        foregroundColor: AppColors.textDim,
      ),
      segments: const [
        ButtonSegment(
            value: BotDifficulty.beginner, label: Text('Beginner')),
        ButtonSegment(value: BotDifficulty.medium, label: Text('Medium')),
        ButtonSegment(value: BotDifficulty.hard, label: Text('Hard')),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _ThemePicker extends StatelessWidget {
  final BoardTheme current;
  final ValueChanged<BoardTheme> onPick;
  const _ThemePicker({required this.current, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: BoardTheme.all.map((t) {
        final selected = t.id == current.id;
        return Expanded(
          child: GestureDetector(
            onTap: () => onPick(t),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? t.primary : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _swatch(t.xColor),
                      _swatch(t.oColor),
                      _swatch(t.primary),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.name,
                    style: TextStyle(
                      color: t.text,
                      fontSize: 12,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _swatch(Color c) => Container(
        width: 14,
        height: 14,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
        ),
      );
}
