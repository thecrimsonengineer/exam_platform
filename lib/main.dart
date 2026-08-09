import 'package:flutter/material.dart';

import 'app/theme.dart';
import 'screens/courses/csp/content_test_screen.dart';

void main() {
  runApp(const ExamPlatformApp());
}

class ExamPlatformApp extends StatelessWidget {
  const ExamPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Exam Platform',
      theme: AppTheme.lightTheme,
      home: const ContentTestScreen(),
    );
  }
}