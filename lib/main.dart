import 'package:flutter/material.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Platform')),
      body: const Center(
        child: Text(
          'Welcome to Exam Platform!',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
