import 'package:flutter/material.dart';

import 'app/theme.dart';
import 'screens/admin/study_content/study_content_studio_screen.dart';

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
      home: const StudyContentStudioScreen(),
    );
  }
}
