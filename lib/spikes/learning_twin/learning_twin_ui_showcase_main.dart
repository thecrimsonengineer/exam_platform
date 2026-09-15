import 'package:flutter/material.dart';

import 'learning_twin_ui_showcase_screen.dart';

void main() {
  runApp(const LearningTwinUiShowcaseApp());
}

class LearningTwinUiShowcaseApp extends StatefulWidget {
  const LearningTwinUiShowcaseApp({super.key});

  @override
  State<LearningTwinUiShowcaseApp> createState() =>
      _LearningTwinUiShowcaseAppState();
}

class _LearningTwinUiShowcaseAppState extends State<LearningTwinUiShowcaseApp> {
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CSP11 Phase M2 Twin UI Showcase',
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF174A8B)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6EA8FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: LearningTwinUiShowcaseScreen(
        isDarkMode: _darkMode,
        onDarkModeChanged: (value) => setState(() => _darkMode = value),
      ),
    );
  }
}
