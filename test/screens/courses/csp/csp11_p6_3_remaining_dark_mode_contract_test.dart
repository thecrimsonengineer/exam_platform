import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('P6.3 fixes Domain and Topic contrast', () {
    final domain = read('lib/screens/courses/csp/domain_screen_dark.dart');
    final topic = read(
      'lib/widgets/csp/study_content/study_content_renderer_dark.dart',
    );

    expect(domain, contains("Colors.white.withValues(alpha: 0.84)"));
    expect(
      domain,
      contains("Icons.arrow_back_rounded, color: Color(0xFFF4F7FB)"),
    );

    expect(topic, contains('DarkStudyColors.textPrimary'));
    expect(topic, contains('DarkStudyColors.textSecondary'));
    expect(topic, contains('DarkStudySubtopicScreen'));
  });

  test('P6.3 dark subtopic reading stack is complete', () {
    final screen = read(
      'lib/screens/courses/csp/study_subtopic_screen_dark.dart',
    );
    final renderer = read(
      'lib/widgets/csp/study_content/study_subtopic_renderer_dark.dart',
    );
    final blocks = read(
      'lib/widgets/csp/study_content/content_block_renderer_dark.dart',
    );
    final nav = read(
      'lib/widgets/csp/study_content/study_content_navigation_dark.dart',
    );

    expect(screen, contains('class DarkStudySubtopicScreen'));
    expect(screen, contains('DarkStudySubtopicRenderer'));
    expect(screen, contains('DarkStudyContentNavigation'));
    expect(renderer, contains('DarkContentBlockRenderer'));
    expect(blocks, contains('DarkStudyTypography'));
    expect(nav, contains('DarkStudyColors.textPrimary'));
  });

  test('P6.3 dark notes chain is wired end to end', () {
    final root = read('lib/screens/courses/csp/study_notes_screen_dark.dart');
    final sections = read(
      'lib/screens/courses/csp/note_sections_screen_dark.dart',
    );
    final list = read('lib/screens/courses/csp/notes_list_screen_dark.dart');
    final reader = read('lib/screens/courses/csp/note_reader_screen_dark.dart');

    expect(root, contains('DarkNoteSectionsScreen'));
    expect(sections, contains('DarkNotesListScreen'));
    expect(list, contains('DarkNoteReaderScreen'));
    expect(reader, contains('Color(0xFFF4F7FB)'));
    expect(reader, contains('Color(0xFFC4CDDA)'));
  });

  test('P6.3 dark Practice and Legal routes are wired', () {
    final home = read('lib/screens/home/home_screen_dark.dart');
    final settings = read('lib/screens/settings/settings_screen_dark.dart');
    final practice = read(
      'lib/screens/courses/csp/csp_practice_screen_dark.dart',
    );
    final legal = read('lib/screens/settings/legal_document_screen_dark.dart');
    final builder = read('lib/widgets/csp/student_quiz_builder.dart');

    expect(home, contains('DarkCspPracticeScreen'));
    expect(home, contains('DarkDomainScreen'));
    expect(home, contains('DarkStudyContentScreen'));
    expect(settings, contains('DarkLegalDocumentScreen'));
    expect(practice, contains('AppTheme.darkTheme'));
    expect(legal, contains('Color(0xFFC4CDDA)'));
    expect(builder, contains('colorScheme.onSurfaceVariant'));
  });
}
