import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(
    path,
  ).readAsStringSync().replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  test(
    'Home search remains present in the frozen information architecture',
    () {
      for (final path in <String>[
        'lib/screens/home/home_screen.dart',
        'lib/screens/home/home_screen_dark.dart',
      ]) {
        final source = read(path);
        expect(source, contains('StudyContentSearchPanel('));
        expect(source, contains('onSelected: _openSearchResult'));
      }
    },
  );

  test(
    'light and dark search results preserve exact learner route identity',
    () {
      for (final path in <String>[
        'lib/screens/home/home_screen.dart',
        'lib/screens/home/home_screen_dark.dart',
      ]) {
        final source = read(path);
        final searchHandler = source.substring(
          source.indexOf('Future<void> _openSearchResult'),
          source.indexOf('void _openExamReadiness'),
        );

        expect(searchHandler, contains('domainId: result.domainId'));
        expect(searchHandler, contains('competencyId: result.competencyId'));
        expect(searchHandler, contains('initialSubtopicId: result.subtopicId'));
        expect(searchHandler, contains('await _refreshHome()'));
      }

      final lightSource = read('lib/screens/home/home_screen.dart');
      final lightHandler = lightSource.substring(
        lightSource.indexOf('Future<void> _openSearchResult'),
        lightSource.indexOf('void _openExamReadiness'),
      );
      expect(lightHandler, contains('initialTopicId: result.topicId'));

      final darkStudyScreen = read(
        'lib/screens/courses/csp/study_content_screen_dark.dart',
      );
      expect(
        darkStudyScreen,
        contains('initialSubtopicId: widget.initialSubtopicId'),
      );
    },
  );

  test(
    'search panel guards stale requests clear retry and preserved results',
    () {
      final source = read(
        'lib/widgets/csp/home/study_content_search_panel.dart',
      );

      expect(source, contains('final request = ++_requestSerial;'));
      expect(source, contains('request != _requestSerial || query != _query'));
      expect(source, contains("ValueKey('home-study-search-clear')"));
      expect(source, contains("ValueKey('home-study-search-retry')"));
      expect(source, contains('_focusNode.unfocus();'));
      expect(source, contains('await widget.onSelected(result);'));
    },
  );

  test('Home search defaults to protected remote learner delivery', () {
    final source = read('lib/widgets/csp/home/study_content_search_panel.dart');

    expect(source, contains('RemoteStudyContentSearchService()'));
    expect(
      source,
      isNot(contains('widget.searchService ?? StudyContentSearchService()')),
    );
  });
}
