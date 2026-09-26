import 'dart:async';

import 'package:exam_platform/services/study_content_search_service.dart';
import 'package:exam_platform/widgets/csp/home/study_content_search_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _SearchHandler = Future<List<StudyContentSearchResult>> Function(
  String query,
  int limit,
);

class _FakeSearchService extends StudyContentSearchService {
  _FakeSearchService(this.handler)
    : super(loadPublishedContent: () async => const []);

  final _SearchHandler handler;

  @override
  Future<List<StudyContentSearchResult>> search(
    String rawQuery, {
    int limit = 8,
  }) {
    return handler(rawQuery, limit);
  }
}

StudyContentSearchResult _result({
  required String id,
  required String title,
}) {
  return StudyContentSearchResult(
    domainId: 'd03',
    domainLabel: 'D03',
    domainTitle: 'Risk Management',
    competencyId: 'd03_c02',
    competencyTitle: 'Risk Management Strategies',
    topicId: 'd03_c02_t01',
    topicTitle: 'Risk Analysis',
    subtopicId: id,
    subtopicTitle: title,
    matchSection: 'Subtopic',
    snippet: title,
    score: 1600,
  );
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required StudyContentSearchService service,
  Future<void> Function(StudyContentSearchResult)? onSelected,
  bool isDarkMode = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: StudyContentSearchPanel(
            isDarkMode: isDarkMode,
            searchService: service,
            onSelected: onSelected ?? (_) async {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('meaningful query immediately replaces stale result state', (
    tester,
  ) async {
    final second = Completer<List<StudyContentSearchResult>>();
    final service = _FakeSearchService((query, limit) {
      if (query == 'hierarchy') {
        return Future.value(<StudyContentSearchResult>[
          _result(id: 'd03_c02_t01_s01', title: 'Hierarchy of Controls'),
        ]);
      }
      return second.future;
    });

    await _pumpPanel(tester, service: service);

    final field = find.byKey(const ValueKey('home-study-search-field'));
    await tester.tap(field);
    await tester.enterText(field, 'hierarchy');
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();

    expect(find.text('Hierarchy of Controls'), findsOneWidget);

    await tester.enterText(field, 'hazard');
    await tester.pump();

    expect(find.text('Hierarchy of Controls'), findsNothing);
    expect(find.text('Searching published study content…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 250));
    second.complete(<StudyContentSearchResult>[
      _result(id: 'd03_c02_t01_s02', title: 'Job Hazard Analysis'),
    ]);
    await tester.pump();

    expect(find.text('Job Hazard Analysis'), findsOneWidget);
  });

  testWidgets('clear remains available while a request is in flight', (
    tester,
  ) async {
    final pending = Completer<List<StudyContentSearchResult>>();
    final service = _FakeSearchService((query, limit) => pending.future);

    await _pumpPanel(tester, service: service);

    final field = find.byKey(const ValueKey('home-study-search-field'));
    await tester.tap(field);
    await tester.enterText(field, 'hazard');
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const ValueKey('home-study-search-clear')), findsOneWidget);
    expect(find.text('Searching published study content…'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-study-search-clear')));
    await tester.pump();

    expect(find.text('Searching published study content…'), findsNothing);
    expect(find.text('hazard'), findsNothing);

    pending.complete(<StudyContentSearchResult>[
      _result(id: 'd03_c02_t01_s02', title: 'Job Hazard Analysis'),
    ]);
    await tester.pump();

    expect(find.text('Job Hazard Analysis'), findsNothing);
  });

  testWidgets('selected results remain available after returning focus', (
    tester,
  ) async {
    var selected = 0;
    final service = _FakeSearchService(
      (query, limit) async => <StudyContentSearchResult>[
        _result(id: 'd03_c02_t01_s01', title: 'Hierarchy of Controls'),
      ],
    );

    await _pumpPanel(
      tester,
      service: service,
      onSelected: (_) async {
        selected++;
      },
    );

    final field = find.byKey(const ValueKey('home-study-search-field'));
    await tester.tap(field);
    await tester.enterText(field, 'hierarchy');
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();

    await tester.tap(
      find.byKey(
        const ValueKey('home-study-search-result-d03_c02_t01_s01'),
      ),
    );
    await tester.pump();

    expect(selected, 1);
    expect(find.byKey(const ValueKey('home-study-search-dropdown')), findsNothing);

    await tester.tap(field);
    await tester.pump();

    expect(find.text('Hierarchy of Controls'), findsOneWidget);
  });

  testWidgets('error state provides a working retry action', (tester) async {
    var calls = 0;
    final service = _FakeSearchService((query, limit) async {
      calls++;
      if (calls == 1) {
        throw StateError('offline');
      }
      return <StudyContentSearchResult>[
        _result(id: 'd03_c02_t01_s01', title: 'Hierarchy of Controls'),
      ];
    });

    await _pumpPanel(tester, service: service, isDarkMode: true);

    final field = find.byKey(const ValueKey('home-study-search-field'));
    await tester.tap(field);
    await tester.enterText(field, 'hierarchy');
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();

    expect(find.byKey(const ValueKey('home-study-search-retry')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-study-search-retry')));
    await tester.pump();
    await tester.pump();

    expect(calls, 2);
    expect(find.text('Hierarchy of Controls'), findsOneWidget);
  });
}
