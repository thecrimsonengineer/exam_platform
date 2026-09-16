import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'M6.1 quick modes use one direct launcher and preserve Custom Quiz',
    () async {
      final hub = await File(
        'lib/screens/practice/practice_hub_screen.dart',
      ).readAsString();

      expect(hub, contains('PracticeMode.dailyChallenge'));
      expect(hub, contains('PracticeMode.randomQuiz'));
      expect(hub, contains('PracticeMode.weakAreas'));
      expect(hub, contains("title: 'Custom Quiz'"));
      expect(hub, contains('CspPracticeScreen('));
      expect(hub, contains('DarkCspPracticeScreen('));
    },
  );

  test(
    'Home quick-practice cards are direct in light and dark variants',
    () async {
      final light = await File(
        'lib/screens/home/home_screen.dart',
      ).readAsString();
      final dark = await File(
        'lib/screens/home/home_screen_dark.dart',
      ).readAsString();

      for (final source in [light, dark]) {
        expect(
          source,
          contains('_openQuickPractice(PracticeMode.dailyChallenge)'),
        );
        expect(source, contains('_openQuickPractice(PracticeMode.weakAreas)'));
        expect(source, contains('_openQuickPractice(PracticeMode.randomQuiz)'));
      }
    },
  );

  test(
    'Weak Areas is local-progress driven and fail-closed to mixed fallback',
    () async {
      final service = await File(
        'lib/services/practice/practice_mode_service.dart',
      ).readAsString();

      expect(service, contains('StudentQuestionProgress'));
      expect(service, contains('minWeakDomainEvidence = 5'));
      expect(service, contains('weakMasteryThreshold = 0.65'));
      expect(service, contains('usedFallback: true'));
      expect(service, isNot(contains('FirebaseFirestore')));
      expect(service, isNot(contains('LearningTwin')));
    },
  );

  test(
    'Quiz result retry preserves custom direct-mode question sets',
    () async {
      final quiz = await File(
        'lib/screens/courses/csp/quiz/quiz_screen.dart',
      ).readAsString();
      final result = await File(
        'lib/screens/courses/csp/quiz/result/result_screen.dart',
      ).readAsString();

      expect(quiz, contains('retryQuestions: widget.customQuestions'));
      expect(quiz, contains('sessionNotice'));
      expect(result, contains('final List<Question>? retryQuestions'));
      expect(result, contains('customQuestions: retryQuestions'));
    },
  );
}
