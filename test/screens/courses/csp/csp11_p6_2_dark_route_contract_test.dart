import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('P6.2 dark Study opens the dark Domain route', () {
    final source = read(
      'lib/screens/courses/csp/csp_study_hub_screen_dark.dart',
    );

    expect(source, contains("import 'domain_screen_dark.dart';"));
    expect(source, contains('DarkDomainScreen(domainNumber:'));
  });

  test('P6.2 dark Domain opens dark Topic content', () {
    final source = read('lib/screens/courses/csp/domain_screen_dark.dart');

    expect(source, contains('class DarkDomainScreen'));
    expect(source, contains('DarkStudyContentScreen('));
    expect(source, contains('QuizScreen(domain: widget.domainNumber)'));
  });

  test('P6.2 provides a dedicated dark Topic accordion renderer', () {
    final screen = read(
      'lib/screens/courses/csp/study_content_screen_dark.dart',
    );
    final renderer = read(
      'lib/widgets/csp/study_content/study_content_renderer_dark.dart',
    );

    expect(screen, contains('class DarkStudyContentScreen'));
    expect(screen, contains('DarkStudyContentRenderer('));
    expect(renderer, contains('class DarkStudyContentRenderer'));
    expect(renderer, contains('DarkStudyColors'));
    expect(renderer, contains('StudySubtopicScreen('));
  });

  test('P6.2 quiz palette is dark-mode aware for Quiz and Result', () {
    final colors = read('lib/screens/courses/csp/quiz/theme/quiz_colors.dart');
    final quiz = read('lib/screens/courses/csp/quiz/quiz_screen.dart');
    final result = read(
      'lib/screens/courses/csp/quiz/result/result_screen.dart',
    );

    expect(colors, contains('ThemeModeService.isDarkMode.value'));
    expect(colors, contains('static LinearGradient get pageGradient'));
    expect(colors, contains('Color(0xFF0A111D)'));
    expect(colors, contains('Color(0xFF111B2C)'));
    expect(quiz, contains('QuizColors.pageGradient'));
    expect(result, contains('QuizColors.pageGradient'));
  });
}
