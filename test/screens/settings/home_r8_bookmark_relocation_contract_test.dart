import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('HOME-R8 places Bookmarked Questions under Learning & Progress', () {
    for (final path in <String>[
      'lib/screens/settings/settings_screen.dart',
      'lib/screens/settings/settings_screen_dark.dart',
    ]) {
      final source = read(path);

      final learningSection = source.indexOf("'LEARNING & PROGRESS'");
      final fullProgress = source.indexOf("'settings-full-progress'");
      final bookmarks = source.indexOf("'settings-bookmarked-questions'");
      final legalSection = source.indexOf("'LEGAL'");

      expect(learningSection, greaterThanOrEqualTo(0));
      expect(fullProgress, greaterThan(learningSection));
      expect(bookmarks, greaterThan(fullProgress));
      expect(legalSection, greaterThan(bookmarks));

      expect(source, contains("title: 'Bookmarked Questions'"));
      expect(
        source,
        contains(
          "'Review questions you saved from quizzes on this device.'",
        ),
      );
      expect(source, contains('_openBookmarkedQuestions(context)'));
    }
  });

  test('HOME-R8 preserves light and dark bookmark destination parity', () {
    final light = read('lib/screens/settings/settings_screen.dart');
    final dark = read('lib/screens/settings/settings_screen_dark.dart');

    expect(light, contains('BookmarkedQuestionsScreen('));
    expect(light, contains('isDarkMode: false'));
    expect(dark, contains('BookmarkedQuestionsScreen('));
    expect(dark, contains('isDarkMode: true'));

    expect(light, contains('const ProgressScreen()'));
    expect(dark, contains('const DarkProgressScreen()'));
  });

  test('HOME-R8 Home has no Bookmarked Questions navigation destination', () {
    for (final path in <String>[
      'lib/screens/home/home_screen.dart',
      'lib/screens/home/home_screen_dark.dart',
    ]) {
      final source = read(path);

      expect(source, isNot(contains('BookmarkedQuestionsScreen')));
      expect(source, isNot(contains('settings-bookmarked-questions')));
      expect(source, isNot(contains("title: 'Bookmarked Questions'")));
      expect(source, isNot(contains('Icons.bookmark_border_rounded')));
      expect(source, contains('Icons.track_changes_rounded'));
    }
  });

  test('HOME-R8 reuses existing bookmark screen and does not fork storage', () {
    final settingsLight = read('lib/screens/settings/settings_screen.dart');
    final settingsDark = read('lib/screens/settings/settings_screen_dark.dart');
    final bookmarkScreen = read(
      'lib/screens/bookmarks/bookmarked_questions_screen.dart',
    );

    expect(
      settingsLight,
      contains("../bookmarks/bookmarked_questions_screen.dart"),
    );
    expect(
      settingsDark,
      contains("../bookmarks/bookmarked_questions_screen.dart"),
    );
    expect(bookmarkScreen, contains('final BookmarkService _bookmarkService'));
    expect(bookmarkScreen, contains('getBookmarkedQuestions()'));
    expect(bookmarkScreen, contains('removeBookmark(question.id)'));

    final bookmarkService = read('lib/services/bookmark_service.dart');
    expect(
      bookmarkService,
      contains("static const String _bookmarkKey = 'bookmarked_question_ids'"),
    );
    expect(
      bookmarkService,
      contains(
        "static const String _snapshotKey = 'bookmarked_question_snapshots_v2'",
      ),
    );
  });
}
