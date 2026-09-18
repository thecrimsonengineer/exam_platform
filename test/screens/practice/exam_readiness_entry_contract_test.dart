import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Exam Readiness universal learner entry contract', () {
    late String practiceHub;
    late String bottomNavigation;

    setUpAll(() {
      practiceHub = File(
        'lib/screens/practice/practice_hub_screen.dart',
      ).readAsStringSync();
      bottomNavigation = File(
        'lib/screens/navigation/bottom_navigation.dart',
      ).readAsStringSync();
    });

    test('Practice hub contains an unconditional Exam Readiness entry', () {
      expect(practiceHub, contains('practice-hub-exam-readiness'));
      expect(practiceHub, contains("title: 'Exam Readiness'"));
      expect(practiceHub, contains('ExamReadinessPlanScreen'));
    });

    test('Practice hub does not gate Exam Readiness on learner identity', () {
      expect(practiceHub, isNot(contains('LearnerLocalIdentity')));
      expect(practiceHub, isNot(contains('FirebaseAuth')));
    });

    test(
      'Practice hub does not gate Exam Readiness on saved plan existence',
      () {
        expect(practiceHub, isNot(contains('ExamStudyPlanRepository')));
        expect(practiceHub, isNot(contains('loadActivePlan')));
      },
    );

    test('Practice hub does not gate Exam Readiness on progress history', () {
      expect(practiceHub, isNot(contains('StudentLearningProgress')));
      expect(practiceHub, isNot(contains('StudentQuestionProgress')));
      expect(practiceHub, isNot(contains('StudentLearningPosition')));
    });

    test('shared Practice hub is used for light learner navigation', () {
      expect(bottomNavigation, contains('return const PracticeHubScreen();'));
    });

    test('shared Practice hub is used for dark learner navigation', () {
      final occurrences = 'return const PracticeHubScreen();'.allMatches(
        bottomNavigation,
      );
      expect(occurrences.length, greaterThanOrEqualTo(2));
    });

    test(
      'Practice remains a permanent learner bottom-navigation destination',
      () {
        expect(bottomNavigation, contains("label: 'Practice'"));
      },
    );

    test('universal entry does not depend on admin role checks', () {
      expect(practiceHub, isNot(contains('isAdmin')));
      expect(practiceHub, isNot(contains('AdminGate')));
    });
  });
}
