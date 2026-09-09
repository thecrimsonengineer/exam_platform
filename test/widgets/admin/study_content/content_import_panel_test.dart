import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exam_platform/services/study_content/content_import_service.dart';
import 'package:exam_platform/widgets/admin/study_content/content_import_panel.dart';

Future<void> showPanel(
  WidgetTester tester,
  ValueChanged<ContentImportResult> onImported,
) async {
  tester.view.physicalSize = const Size(1400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ContentImportPanel(onImported: onImported),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<Map<String, dynamic>> loadExample(WidgetTester tester) async {
  await tester.tap(find.text('Load Example'));
  await tester.pumpAndSettle();
  final text = tester
      .widget<TextField>(find.byType(TextField))
      .controller!
      .text;
  return jsonDecode(text) as Map<String, dynamic>;
}

void expectMetric(WidgetTester tester, String label, int value) {
  final column = find
      .ancestor(of: find.text(label), matching: find.byType(Column))
      .first;
  expect(
    find.descendant(of: column, matching: find.text('$value')),
    findsOneWidget,
  );
}

Future<void> importContent(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Import Content'));
  await tester.tap(find.text('Import Content'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('built-in example imports canonical hierarchy without errors', (
    tester,
  ) async {
    ContentImportResult? imported;
    await showPanel(tester, (result) => imported = result);
    final sample = await loadExample(tester);
    expect(sample['domainId'], 'd07');
    expect(sample['competencyId'], 'd07_c01');
    expect(sample.containsKey('subtopics'), isFalse);
    expect(jsonEncode(sample), isNot(contains('mainContent')));
    expect(jsonEncode(sample), isNot(contains('domain_07')));
    await importContent(tester);
    expect(imported, isNotNull);
    expect(imported!.errorCount, 0);
    expect(imported!.warningCount, 0);
    final topic = imported!.content!.topics.single;
    final child = topic.subtopics.single;
    expect(child.blocks.length, 2);
    expect(child.learningObjectives.length, 2);
    expect(
      child.quizzes.single.quizId,
      'd07_c01-v1_subtopic_training_gaps_quiz',
    );
    for (final item in {
      'Topics': 1,
      'Subtopics': 1,
      'Content Blocks': 2,
      'Learning Objectives': 2,
      'Examples': 0,
      'Case Studies': 0,
      'References': 0,
      'Quiz References': 1,
    }.entries) {
      expectMetric(tester, item.key, item.value);
    }
    expect(find.text('Main Topics'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('counts blocks metadata and quiz links across multiple topics', (
    tester,
  ) async {
    ContentImportResult? imported;
    await showPanel(tester, (result) => imported = result);
    final sample = await loadExample(tester);
    final originalTopic =
        (sample['topics'] as List).single as Map<String, dynamic>;
    final originalChild =
        (originalTopic['subtopics'] as List).single as Map<String, dynamic>;
    final extraChild = Map<String, dynamic>.from(originalChild)
      ..['id'] = 'subtopic_extra'
      ..['examples'] = ['Example A', 'Example B', 'Example C']
      ..['caseStudies'] = ['Case A']
      ..['references'] = ['Reference A', 'Reference B']
      ..['quizzes'] = [
        {'quizId': 'extra_quiz_a'},
        {'quizId': 'extra_quiz_b'},
      ];
    sample['topics'] = [
      originalTopic,
      {
        'id': 'topic_extra',
        'title': 'Extra topic',
        'subtopics': [extraChild],
      },
    ];
    await tester.enterText(find.byType(TextField), jsonEncode(sample));
    await importContent(tester);
    expect(imported!.isSuccessful, isTrue);
    expect(imported!.content!.topics.length, 2);
    for (final item in {
      'Topics': 2,
      'Subtopics': 2,
      'Content Blocks': 4,
      'Learning Objectives': 4,
      'Examples': 3,
      'Case Studies': 1,
      'References': 2,
      'Quiz References': 3,
    }.entries) {
      expectMetric(tester, item.key, item.value);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty topic list produces zero statistics without crashing', (
    tester,
  ) async {
    ContentImportResult? imported;
    await showPanel(tester, (result) => imported = result);
    final sample = await loadExample(tester);
    sample['topics'] = [];
    await tester.enterText(find.byType(TextField), jsonEncode(sample));
    await importContent(tester);
    expect(imported!.isSuccessful, isTrue);
    expect(imported!.hasWarnings, isTrue);
    for (final label in [
      'Topics',
      'Subtopics',
      'Content Blocks',
      'Learning Objectives',
      'Examples',
      'Case Studies',
      'References',
      'Quiz References',
    ]) {
      expectMetric(tester, label, 0);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('malformed JSON does not call successful-import callback', (
    tester,
  ) async {
    var calls = 0;
    await showPanel(tester, (_) => calls++);
    await tester.enterText(find.byType(TextField), '{invalid');
    await importContent(tester);
    expect(calls, 0);
    expect(find.text('Import Failed'), findsOneWidget);
    expect(find.textContaining('Invalid JSON:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
