import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/theme.dart';
import 'firebase_options.dart';
import 'services/local_question_repository.dart';
import 'services/settings/theme_mode_service.dart';
import 'screens/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await LocalQuestionRepository.instance.initialize();
  await ThemeModeService.initialize();

  runApp(const ExamPlatformApp());
}

class ExamPlatformApp extends StatelessWidget {
  const ExamPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeModeService.isDarkMode,
      builder: (context, isDarkMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'CSP11 Learning Platform',
          theme: AppTheme.studentGlassLightTheme,
          darkTheme: AppTheme.studentGlassDarkTheme,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const AuthGate(),
        );
      },
    );
  }
}
