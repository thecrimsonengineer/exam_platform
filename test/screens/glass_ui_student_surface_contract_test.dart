import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('student glass foundation supports blur and both themes', () {
    final glass = read('lib/theme/glass/student_glass.dart');
    final theme = read('lib/app/theme.dart');

    expect(glass, contains('BackdropFilter'));
    expect(glass, contains('StudentGlassSurface'));
    expect(glass, contains('StudentGlassScaffold'));
    expect(glass, contains('StudentGlassPalette'));
    expect(glass, contains('static const light'));
    expect(glass, contains('static const dark'));

    expect(theme, contains('studentGlassLightTheme'));
    expect(theme, contains('studentGlassDarkTheme'));
  });

  test('primary learner navigation pages use the glass scaffold', () {
    const paths = <String>[
      'lib/screens/home/home_screen.dart',
      'lib/screens/home/home_screen_dark.dart',
      'lib/screens/courses/csp/csp_study_hub_screen.dart',
      'lib/screens/courses/csp/csp_study_hub_screen_dark.dart',
      'lib/screens/flashcards/flashcards_screen.dart',
      'lib/screens/progress/progress_analytics_screen.dart',
      'lib/screens/practice/practice_hub_screen.dart',
      'lib/screens/settings/settings_screen.dart',
      'lib/screens/settings/settings_screen_dark.dart',
      'lib/screens/bookmarks/bookmarked_questions_screen.dart',
      'lib/screens/courses/csp/quiz/quiz_screen.dart',
      'lib/screens/courses/csp/quiz/result/result_screen.dart',
    ];

    for (final path in paths) {
      expect(
        read(path),
        contains('StudentGlassScaffold'),
        reason: '$path must stay on the student glass shell.',
      );
    }

    final darkFlashcards = read(
      'lib/screens/flashcards/flashcards_screen_dark.dart',
    );
    expect(
      darkFlashcards,
      contains('return FlashcardsScreen(controller: controller);'),
      reason: 'Dark Flashcards must delegate to the shared glass shell.',
    );
  });

  test('all core Exam Readiness pages keep the glass shell', () {
    const paths = <String>[
      'lib/features/exam_readiness/screens/exam_plan_setup_screen.dart',
      'lib/features/exam_readiness/screens/exam_readiness_plan_screen.dart',
      'lib/features/exam_readiness/screens/readiness_profile_screen.dart',
      'lib/features/exam_readiness/screens/competency_readiness_screen.dart',
      'lib/features/exam_readiness/screens/todays_plan_screen.dart',
      'lib/features/exam_readiness/screens/advanced_readiness_screen.dart',
    ];

    for (final path in paths) {
      expect(
        read(path),
        contains('StudentGlassScaffold'),
        reason: '$path must stay on the glass Exam Readiness shell.',
      );
    }
  });

  test('Quiz and Learning Twin retain true blur-backed glass surfaces', () {
    final question = read(
      'lib/screens/courses/csp/quiz/widgets/question/question_card.dart',
    );
    final answer = read(
      'lib/screens/courses/csp/quiz/widgets/answers/answer_option_card.dart',
    );
    final twin = read('lib/features/learning_twin/ui/learning_twin_card.dart');
    final overviewHero = read('lib/widgets/csp/hero_card.dart');

    expect(question, contains('StudentGlassSurface'));
    expect(question, contains('gradient: QuizColors.questionGradient'));
    expect(answer, contains('StudentGlassSurface'));
    expect(twin, contains('StudentGlassCard'));
    expect(overviewHero, contains('StudentGlassSurface'));
  });

  test('high-frequency learner routes retain glass card surfaces', () {
    const paths = <String>[
      'lib/screens/home/home_screen.dart',
      'lib/screens/home/home_screen_dark.dart',
      'lib/screens/courses/courses_screen.dart',
      'lib/screens/courses/csp/csp_study_hub_screen.dart',
      'lib/screens/courses/csp/csp_study_hub_screen_dark.dart',
      'lib/screens/courses/csp/domain_screen.dart',
      'lib/screens/courses/csp/domain_screen_dark.dart',
      'lib/screens/courses/csp/study_content_screen.dart',
      'lib/screens/courses/csp/study_content_screen_dark.dart',
      'lib/screens/courses/csp/study_subtopic_screen.dart',
      'lib/screens/courses/csp/study_subtopic_screen_dark.dart',
      'lib/screens/courses/csp/csp_practice_screen.dart',
      'lib/screens/courses/csp/csp_practice_screen_dark.dart',
      'lib/screens/bookmarks/bookmarked_questions_screen.dart',
      'lib/screens/progress/progress_analytics_screen.dart',
      'lib/screens/settings/settings_screen.dart',
      'lib/screens/settings/settings_screen_dark.dart',
    ];

    for (final path in paths) {
      expect(
        read(path),
        contains('StudentGlassSurface'),
        reason: '$path must keep blur-backed learner surfaces.',
      );
    }
  });

  test('glass consumers use the package import contract', () {
    const paths = <String>[
      'lib/screens/home/home_screen.dart',
      'lib/screens/navigation/bottom_navigation.dart',
      'lib/screens/progress/widgets/progress_charts.dart',
      'lib/widgets/continue_learning_card.dart',
      'lib/widgets/csp/home/study_content_search_panel.dart',
      'lib/widgets/csp/study_content/study_content_renderer.dart',
      'lib/widgets/csp/study_content/study_subtopic_renderer.dart',
      'lib/widgets/featured_course_card.dart',
    ];

    const expected =
        "import 'package:exam_platform/theme/glass/student_glass.dart';";

    for (final path in paths) {
      expect(
        read(path),
        contains(expected),
        reason: '$path must use the stable package glass import.',
      );
    }
  });

  test('student auth shell is glass while admin remains legacy themed', () {
    final auth = read('lib/screens/auth/auth_experience_shell.dart');
    final gate = read('lib/screens/auth/auth_gate.dart');
    final adminHome = read('lib/screens/admin/admin_home_screen.dart');

    expect(auth, contains('StudentGlassScaffold'));
    expect(auth, contains('StudentGlassSurface'));
    expect(gate, contains('AppTheme.lightTheme'));
    expect(adminHome, isNot(contains('StudentGlassScaffold')));
  });
}
