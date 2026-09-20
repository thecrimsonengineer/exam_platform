import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('Home uses a restrained staged entrance hierarchy in both themes', () {
    for (final path in <String>[
      'lib/screens/home/home_screen.dart',
      'lib/screens/home/home_screen_dark.dart',
    ]) {
      final source = read(path);
      expect(source, contains('Csp11StaggeredReveal('));
      expect(source, contains('Duration(milliseconds: 30)'));
      expect(source, contains('Duration(milliseconds: 60)'));
      expect(source, contains('Duration(milliseconds: 90)'));
      expect(source, contains('Duration(milliseconds: 120)'));
      expect(source, contains('Duration(milliseconds: 150)'));
      expect(source, contains("PageStorageKey<String>('csp11-home-scroll')"));
    }
  });

  test('Learn hierarchy uses central route transitions', () {
    final expected = <String, String>{
      'lib/screens/courses/csp/csp_study_hub_screen.dart':
          'Csp11Route.forward<void>(',
      'lib/screens/courses/csp/csp_study_hub_screen_dark.dart':
          'Csp11Route.forward<void>(',
      'lib/screens/courses/csp/domain_screen.dart': 'Csp11Route.forward<void>(',
      'lib/screens/courses/csp/domain_screen_dark.dart':
          'Csp11Route.forward<void>(',
      'lib/screens/courses/csp/competency_screen.dart':
          'Csp11Route.forward<void>(',
      'lib/screens/courses/csp/study_subtopic_screen.dart':
          'Csp11Route.replacement<void>(',
      'lib/screens/courses/csp/study_subtopic_screen_dark.dart':
          'Csp11Route.replacement<void>(',
    };

    for (final entry in expected.entries) {
      final source = read(entry.key);
      expect(source, contains(entry.value), reason: entry.key);
      expect(
        source,
        contains("package:exam_platform/navigation/csp11_route.dart"),
        reason: entry.key,
      );
    }
  });

  test('Home learning deep links use central forward routes', () {
    for (final path in <String>[
      'lib/screens/home/home_screen.dart',
      'lib/screens/home/home_screen_dark.dart',
    ]) {
      final source = read(path);
      expect(source, contains('Csp11Route.forward<void>('));
      expect(source, contains('initialSubtopicId: position.subtopicId'));
      expect(source, contains('initialSubtopicId: result.subtopicId'));
    }
  });

  test('Quiz changes only question content and reveals submitted feedback', () {
    final source = read('lib/screens/courses/csp/quiz/quiz_screen.dart');

    expect(source, contains(r"'quiz-question-${question.id}'"));
    expect(source, contains(r"'quiz-answers-${question.id}'"));
    expect(source, contains('Csp11SlideFade('));
    expect(source, contains('Csp11StaggeredReveal('));
    expect(source, contains('ExplanationCard('));
    expect(source, contains('ReferenceCard('));
    expect(source, contains('Csp11Route.detail<void>('));
    expect(source, contains('Csp11Route.replacement<void>('));

    final actionBarIndex = source.indexOf('QuizActionBar(');
    final questionMotionIndex = source.indexOf(
      r"'quiz-question-${question.id}'",
    );
    expect(actionBarIndex, greaterThan(questionMotionIndex));
  });

  test('Answer selection motion respects reduced-motion policy', () {
    final source = read(
      'lib/screens/courses/csp/quiz/widgets/answers/answer_option_card.dart',
    );

    expect(source, contains('AnimatedScale('));
    expect(source, contains('Csp11MotionPreferences.reduced(context)'));
    expect(source, contains('Csp11MotionDuration.quick'));
    expect(source, contains('1.006'));
  });

  test('Results use staged completion reveal and animated progress', () {
    final source = read(
      'lib/screens/courses/csp/quiz/result/result_screen.dart',
    );

    expect(source, contains('Csp11StaggeredReveal('));
    expect(source, contains('Duration(milliseconds: 40)'));
    expect(source, contains('Duration(milliseconds: 80)'));
    expect(source, contains('Duration(milliseconds: 120)'));
    expect(source, contains('Duration(milliseconds: 150)'));
    expect(source, contains('TweenAnimationBuilder<double>('));
    expect(source, contains('Csp11MotionDuration.celebration'));
    expect(source, contains('Csp11MotionPreferences.reduced(context)'));
    expect(source, contains('Csp11Route.replacement<void>('));
  });
}
