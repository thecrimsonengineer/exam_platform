import 'package:flutter/material.dart';

import 'app/theme.dart';
import 'screens/admin/admin_home_screen.dart';
import 'services/local_question_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalQuestionRepository.instance.initialize();
  runApp(const ExamPlatformApp());
}

class ExamPlatformApp extends StatelessWidget {
  const ExamPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CSP11 Admin Console',
      theme: AppTheme.lightTheme,
      home: AdminHomeScreen(),
    );
  }
}