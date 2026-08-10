import 'package:flutter/material.dart';

import 'app/theme.dart';
import 'screens/admin/admin_home_screen.dart';

void main() {
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