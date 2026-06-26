import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'services/ads_service.dart';
import 'services/profile_manager.dart';
import 'services/theme_manager.dart';
import 'services/sfx.dart';
import 'widgets/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await ProfileManager.instance.ensureLoaded();
  await ThemeManager.instance.ensureLoaded();
  Sfx.instance.enabled = ThemeManager.instance.soundEnabled;
  unawaited(AdsService.instance.init());
  runApp(const NoDrawTttApp());
}

class NoDrawTttApp extends StatefulWidget {
  const NoDrawTttApp({super.key});

  @override
  State<NoDrawTttApp> createState() => _NoDrawTttAppState();
}

class _NoDrawTttAppState extends State<NoDrawTttApp> {
  @override
  void initState() {
    super.initState();
    ThemeManager.instance.addListener(_onChange);
  }

  void _onChange() => setState(() {});

  @override
  void dispose() {
    ThemeManager.instance.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'No Draw Tic Tac Toe',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomeScreen(),
    );
  }
}
