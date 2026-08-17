import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/theme.dart';
import 'firebase_options.dart';
import 'services/local_question_repository.dart';
import 'tests/phase_d_test_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await LocalQuestionRepository.instance.initialize();

  runApp(const ExamPlatformApp());
}

class ExamPlatformApp extends StatelessWidget {
  const ExamPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CSP11 Learning Platform',
      theme: AppTheme.lightTheme,
      home: const PhaseDTestScreen(),
    );
  }
}
