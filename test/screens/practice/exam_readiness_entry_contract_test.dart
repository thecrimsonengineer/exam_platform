import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Exam Readiness learner entry contract', () {
    late String lightHome;
    late String darkHome;
    late String practiceHub;
    late String bottomNavigation;

    setUpAll(() {
      lightHome = File('lib/screens/home/home_screen.dart').readAsStringSync();
      darkHome = File(
        'lib/screens/home/home_screen_dark.dart',
      ).readAsStringSync();
      practiceHub = File(
        'lib/screens/practice/practice_hub_screen.dart',
      ).readAsStringSync();
      bottomNavigation = File(
        'lib/screens/navigation/bottom_navigation.dart',
      ).readAsStringSync();
    });

    test('light Home exposes Exam Readiness in learning footprint', () {
      expect(lightHome, contains("ValueKey('home-exam-readiness')"));
      expect(lightHome, contains("const _Eyebrow('PROGRESS INTELLIGENCE')"));
      expect(lightHome, contains("'Your learning footprint'"));
      expect(lightHome, contains('ExamReadinessPlanScreen'));
      expect(lightHome, contains('examReadinessRoute<void>'));
    });

    test('dark Home exposes the same Exam Readiness entry', () {
      expect(darkHome, contains("ValueKey('home-exam-readiness')"));
      expect(darkHome, contains("const _Eyebrow('PROGRESS INTELLIGENCE')"));
      expect(darkHome, contains("'Your learning footprint'"));
      expect(darkHome, contains('ExamReadinessPlanScreen'));
      expect(darkHome, contains('examReadinessRoute<void>'));
    });

    test('Home learning-footprint action no longer opens Progress', () {
      expect(lightHome, isNot(contains("ValueKey('home-progress')")));
      expect(darkHome, isNot(contains("ValueKey('home-progress')")));
      expect(lightHome, isNot(contains("'See domain and topic progress'")));
      expect(darkHome, isNot(contains("'See domain and topic progress'")));
    });

    test('Practice hub no longer contains the Exam Readiness planner', () {
      expect(
        practiceHub,
        isNot(contains("keyName: 'practice-hub-exam-readiness'")),
      );
      expect(practiceHub, isNot(contains('ExamReadinessPlanScreen')));
      expect(practiceHub, isNot(contains('_openExamReadiness')));
    });

    test('Ultra Hard DQG300 remains a Practice mode', () {
      expect(practiceHub, contains("keyName: 'practice-hub-ultra-hard'"));
      expect(practiceHub, contains("title: 'Ultra Hard • DQG300'"));
    });

    test('Practice remains a permanent bottom-navigation destination', () {
      expect(bottomNavigation, contains("label: 'Practice'"));
    });

    test('Progress remains a dedicated bottom-navigation destination', () {
      expect(bottomNavigation, contains("label: 'Progress'"));
    });
  });
}
