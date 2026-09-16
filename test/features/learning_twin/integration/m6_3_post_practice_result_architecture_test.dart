import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('M6.3 result Twin layer contains no protected question payload', () async {
    const paths = <String>[
      'lib/features/learning_twin/coaching/learning_twin_practice_result_context.dart',
      'lib/features/learning_twin/coaching/learning_twin_practice_result_message_bridge.dart',
      'lib/features/learning_twin/integration/learning_twin_post_practice_guidance.dart',
    ];

    for (final path in paths) {
      final source = await File(path).readAsString();

      // Guard concrete code-level payload types, imports, and sensitive fields.
      // Do not ban ordinary English words such as "question", "explanation",
      // or "reference" because result-coaching copy may legitimately use them.
      for (final forbidden in <String>[
        'models/question.dart',
        'List<Question>',
        'Question?',
        'Question>',
        'Question(',
        'incorrectQuestions',
        'correctAnswer',
        'correctOption',
        'answerOptions',
        'questionText',
        'questionStem',
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
          reason: '$forbidden must not enter the sanitized M6.3 Twin layer.',
        );
      }
    }
  });

  test(
    'M6.3 uses practiceCompleted through frozen M3 decision service',
    () async {
      final source = await File(
        'lib/features/learning_twin/integration/'
        'learning_twin_post_practice_guidance.dart',
      ).readAsString();

      expect(source, contains('LearningTwinTrigger.practiceCompleted'));
      expect(source, contains('DeterministicLearningTwinDecisionService'));
      expect(source, contains('LearningTwinSessionState.empty()'));
      expect(source, contains('isTimedExamActive: widget.isTimedExamActive'));
      expect(source, contains('onDismiss: _dismiss'));
      expect(source, isNot(contains('showDialog(')));
      expect(source, isNot(contains('showModalBottomSheet(')));
    },
  );

  test(
    'QuizScreen forwards only sanitized practice context to ResultScreen',
    () async {
      final source = await File(
        'lib/screens/courses/csp/quiz/quiz_screen.dart',
      ).readAsString();

      expect(
        source,
        contains('LearningTwinPracticeContext? learningTwinPracticeContext'),
      );
      expect(
        source,
        contains(
          'learningTwinPracticeContext: widget.learningTwinPracticeContext',
        ),
      );
      expect(source, contains('final resultRouteTheme = Theme.of(context);'));
      expect(source, contains('data: resultRouteTheme'));
    },
  );

  test(
    'ResultScreen builds aggregate result context without passing misses',
    () async {
      final source = await File(
        'lib/screens/courses/csp/quiz/result/result_screen.dart',
      ).readAsString();

      expect(source, contains('LearningTwinPracticeResultContext('));
      expect(source, contains('score: score'));
      expect(source, contains('totalQuestions: totalQuestions'));
      expect(source, contains('LearningTwinPostPracticeGuidance('));

      final guidanceStart = source.indexOf('LearningTwinPostPracticeGuidance(');
      final guidanceEnd = source.indexOf('),', guidanceStart);

      expect(guidanceStart, greaterThanOrEqualTo(0));
      expect(guidanceEnd, greaterThan(guidanceStart));

      final guidanceCall = source.substring(guidanceStart, guidanceEnd);
      expect(guidanceCall, isNot(contains('incorrectQuestions')));
    },
  );

  test(
    'direct and custom practice sessions forward sanitized context to quiz',
    () async {
      final quick = await File(
        'lib/screens/practice/practice_quick_launch_screen.dart',
      ).readAsString();
      final custom = await File(
        'lib/widgets/csp/student_quiz_builder.dart',
      ).readAsString();

      expect(
        quick,
        contains('learningTwinPracticeContext: learningTwinPracticeContext'),
      );
      expect(
        custom,
        contains('learningTwinPracticeContext: learningTwinPracticeContext'),
      );
    },
  );

  test(
    'retry retains result-coach context while incorrect review does not',
    () async {
      final source = await File(
        'lib/screens/courses/csp/quiz/result/result_screen.dart',
      ).readAsString();

      expect(
        source,
        contains('learningTwinPracticeContext: learningTwinPracticeContext'),
      );
      expect(source, contains("customQuestions: incorrectQuestions"));

      final reviewStart = source.indexOf('customQuestions: incorrectQuestions');
      final reviewTail = source.substring(
        reviewStart,
        (reviewStart + 220).clamp(0, source.length),
      );

      expect(
        reviewTail,
        isNot(contains('learningTwinPracticeContext:')),
        reason: 'Review Incorrect Answers must remain a review flow.',
      );
    },
  );
}
