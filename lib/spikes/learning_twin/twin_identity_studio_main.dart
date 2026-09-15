import 'package:flutter/material.dart';

import 'twin_identity_studio_screen.dart';

void main() {
  runApp(const TwinIdentityStudioApp());
}

class TwinIdentityStudioApp extends StatefulWidget {
  const TwinIdentityStudioApp({super.key});

  @override
  State<TwinIdentityStudioApp> createState() => _TwinIdentityStudioAppState();
}

class _TwinIdentityStudioAppState extends State<TwinIdentityStudioApp> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CSP11 Phase M1 Twin Identity Studio',
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
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
      home: TwinIdentityStudioScreen(
        isDarkMode: _isDarkMode,
        onDarkModeChanged: (value) => setState(() => _isDarkMode = value),
      ),
    );
  }
}
