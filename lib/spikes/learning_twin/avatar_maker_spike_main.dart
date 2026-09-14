import 'package:avatar_maker/avatar_maker.dart';
import 'package:flutter/material.dart';

import 'avatar_maker_spike_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LearningTwinAvatarMakerSpikeApp());
}

class LearningTwinAvatarMakerSpikeApp extends StatefulWidget {
  const LearningTwinAvatarMakerSpikeApp({super.key});

  @override
  State<LearningTwinAvatarMakerSpikeApp> createState() =>
      _LearningTwinAvatarMakerSpikeAppState();
}

class _LearningTwinAvatarMakerSpikeAppState
    extends State<LearningTwinAvatarMakerSpikeApp> {
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CSP11 Phase M0 Avatar Spike',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF315DA8)),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7FB3FF),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      home: AvatarMakerSpikeScreen(
        isDarkMode: _darkMode,
        onDarkModeChanged: (enabled) {
          setState(() {
            _darkMode = enabled;
          });
        },
      ),
    );
  }
}
