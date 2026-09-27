import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/navigation_motion.dart';
import 'app/theme.dart';
import 'firebase_options.dart';
import 'services/local_question_repository.dart';
import 'services/settings/navigation_motion_service.dart';
import 'services/settings/theme_mode_service.dart';
import 'services/supabase/supabase_bootstrap_service.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/startup/csp11_startup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SupabaseBootstrapService.initializeIfConfigured();

  await LocalQuestionRepository.instance.initialize();
  await ThemeModeService.initialize();
  await NavigationMotionService.initialize();

  runApp(const ExamPlatformApp());
}

class ExamPlatformApp extends StatelessWidget {
  const ExamPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeModeService.isDarkMode,
      builder: (context, isDarkMode, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: NavigationMotionService.isEnabled,
          builder: (context, navigationMotionEnabled, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'CSP11 Learning Platform',
              theme: AppNavigationMotion.apply(
                AppTheme.studentGlassLightTheme,
                enabled: navigationMotionEnabled,
              ),
              darkTheme: AppNavigationMotion.apply(
                AppTheme.studentGlassDarkTheme,
                enabled: navigationMotionEnabled,
              ),
              themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
              home: const Csp11StartupScreen(child: AuthGate()),
            );
          },
        );
      },
    );
  }
}
