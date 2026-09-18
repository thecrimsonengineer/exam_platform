import 'dart:io';

import 'package:exam_platform/screens/courses/csp/quiz/quiz_screen.dart';
import 'package:exam_platform/screens/courses/csp/study_content_screen.dart';
import 'package:exam_platform/screens/courses/csp/study_content_screen_dark.dart';
import 'package:exam_platform/services/settings/theme_mode_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dark quiz tag destination remains dark and preserves deep link', () {
    ThemeModeService.isDarkMode.value = true;

    final destination = buildCsp11QuizTagDestination(
      isDarkMode: ThemeModeService.isDarkMode.value,
      domainId: 'd06',
      competencyId: 'd06_c06',
      domainTitle: 'Occupational Health and Applied Science',
      loadingTitle: 'D06_C06',
      initialTopicId: 'd06_c06_t03',
      initialSubtopicId: 'd06_c06_t03_s02',
    );

    expect(destination, isA<DarkStudyContentScreen>());

    final darkDestination = destination as DarkStudyContentScreen;
    expect(darkDestination.domainId, 'd06');
    expect(darkDestination.competencyId, 'd06_c06');
    expect(darkDestination.initialTopicId, 'd06_c06_t03');
    expect(darkDestination.initialSubtopicId, 'd06_c06_t03_s02');
    expect(ThemeModeService.isDarkMode.value, isTrue);
  });

  test('light quiz tag destination remains light and preserves deep link', () {
    ThemeModeService.isDarkMode.value = false;

    final destination = buildCsp11QuizTagDestination(
      isDarkMode: ThemeModeService.isDarkMode.value,
      domainId: 'd06',
      competencyId: 'd06_c06',
      domainTitle: 'Occupational Health and Applied Science',
      loadingTitle: 'D06_C06',
      initialTopicId: 'd06_c06_t03',
      initialSubtopicId: 'd06_c06_t03_s02',
    );

    expect(destination, isA<StudyContentScreen>());

    final lightDestination = destination as StudyContentScreen;
    expect(lightDestination.initialTopicId, 'd06_c06_t03');
    expect(lightDestination.initialSubtopicId, 'd06_c06_t03_s02');
    expect(ThemeModeService.isDarkMode.value, isFalse);
  });

  test(
    'quiz hierarchy tag tap reads learner theme instead of forcing light',
    () {
      final source = File(
        'lib/screens/courses/csp/quiz/quiz_screen.dart',
      ).readAsStringSync();

      expect(
        source,
        contains('final isDarkMode = ThemeModeService.isDarkMode.value;'),
      );
      expect(source, contains('builder: (_) => buildCsp11QuizTagDestination('));
      expect(source, contains('isDarkMode: isDarkMode,'));
      expect(source, isNot(contains('builder: (_) => StudyContentScreen(')));
    },
  );

  test(
    'dark study destination supports the same topic and subtopic target',
    () {
      final screen = File(
        'lib/screens/courses/csp/study_content_screen_dark.dart',
      ).readAsStringSync();
      final renderer = File(
        'lib/widgets/csp/study_content/study_content_renderer_dark.dart',
      ).readAsStringSync();

      expect(screen, contains('final String? initialTopicId;'));
      expect(screen, contains('initialTopicId: widget.initialTopicId'));
      expect(renderer, contains('final String? initialTopicId;'));
      expect(renderer, contains('final Map<int, GlobalKey> _topicKeys'));
      expect(renderer, contains('int? _requestedTopicIndex()'));
      expect(renderer, contains('Scrollable.ensureVisible('));
    },
  );
}
