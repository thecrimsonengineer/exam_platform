import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('M6.2 Twin practice layer receives no protected question payload', () async {
    const paths = <String>[
      'lib/features/learning_twin/coaching/learning_twin_practice_context.dart',
      'lib/features/learning_twin/coaching/learning_twin_practice_message_bridge.dart',
      'lib/features/learning_twin/integration/learning_twin_pre_practice_guidance.dart',
    ];

    for (final path in paths) {
      final source = await File(path).readAsString();

      for (final forbidden in <String>[
        "models/question.dart",
        "import '../../../models/question",
        'List<Question>',
        'correctAnswer',
        'correctOption',
        'answerOptions',
        'cloud_firestore',
        'firebase_',
        'SharedPreferences',
        'Navigator.',
        'Random(',
        'DateTime.now',
      ]) {
        expect(
          source,
          isNot(contains(forbidden)),
          reason: '$forbidden must not enter the sanitized M6.2 Twin layer.',
        );
      }
    }
  });

  test(
    'pre-practice coach remains governed by the frozen M3 decision service',
    () async {
      final source = await File(
        'lib/features/learning_twin/integration/'
        'learning_twin_pre_practice_guidance.dart',
      ).readAsString();

      expect(source, contains('DeterministicLearningTwinDecisionService'));
      expect(source, contains('LearningTwinSessionState.empty()'));
      expect(source, contains('isTimedExamActive: widget.isTimedExamActive'));
      expect(source, contains('onDismiss: _dismiss'));
      expect(source, isNot(contains('showDialog(')));
      expect(source, isNot(contains('showModalBottomSheet(')));
    },
  );

  test(
    'direct modes create sanitized context before entering Twin host',
    () async {
      final source = await File(
        'lib/screens/practice/practice_quick_launch_screen.dart',
      ).readAsString();

      expect(source, contains('LearningTwinPracticeSessionHost('));
      expect(source, contains('LearningTwinPracticeContext('));
      expect(source, contains('plan.questionCount'));
      expect(source, contains('plan.usedFallback'));
      expect(source, contains('customQuestions: plan.questions'));
    },
  );

  test(
    'Custom Quiz receives the same sanitized pre-practice boundary',
    () async {
      final source = await File(
        'lib/widgets/csp/student_quiz_builder.dart',
      ).readAsString();

      expect(source, contains('LearningTwinPracticeMode.customQuiz'));
      expect(source, contains('LearningTwinPracticeSessionHost('));
      expect(source, contains('questionCount: questions.length'));
      expect(source, contains('final practiceRouteTheme = Theme.of(context);'));
      expect(source, contains('theme: practiceRouteTheme'));
      expect(source, contains('child: QuizScreen('));
    },
  );

  test(
    'PracticeModeService remains free of Learning Twin dependencies',
    () async {
      final source = await File(
        'lib/services/practice/practice_mode_service.dart',
      ).readAsString();

      expect(source, isNot(contains('learning_twin')));
      expect(source, isNot(contains('LearningTwin')));
    },
  );
}
