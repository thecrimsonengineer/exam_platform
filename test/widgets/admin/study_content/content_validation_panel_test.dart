import 'package:exam_platform/models/study_content.dart';
import 'package:exam_platform/widgets/admin/study_content/content_validation_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> showPanel(WidgetTester tester, StudyContent content) async {
  tester.view.physicalSize = const Size(1400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ContentValidationPanel(content: content),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

ContentBlock block(String id) {
  return ContentBlock(
    id: id,
    type: 'text',
    data: const {'text': 'Validated content block'},
  );
}

StudySubtopic subtopic({
  required String id,
  required String title,
  required List<ContentBlock> blocks,
}) {
  return StudySubtopic(
    id: id,
    title: title,
    blocks: blocks,
    learningObjectives: const ['Explain the learning point.'],
  );
}

StudyTopic topic({
  required String id,
  required String title,
  required List<StudySubtopic> subtopics,
}) {
  return StudyTopic(id: id, title: title, subtopics: subtopics);
}

StudyContent contentWithTopics(List<StudyTopic> topics) {
  return StudyContent(
    id: 'd01_c01-v1',
    domainId: 'd01',
    competencyId: 'd01_c01',
    competencyNumber: 1,
    title: 'Example competency',
    status: 'Draft',
    version: 1,
    topics: topics,
  );
}

void expectCheckStatus(String label, String status) {
  final row = find
      .ancestor(of: find.text(label), matching: find.byType(Row))
      .first;

  expect(find.descendant(of: row, matching: find.text(status)), findsOneWidget);
}

void main() {
  testWidgets(
    'canonical Topic to Subtopic to block hierarchy passes panel checks',
    (tester) async {
      final content = contentWithTopics([
        topic(
          id: 'topic_a',
          title: 'Topic A',
          subtopics: [
            subtopic(
              id: 'subtopic_a',
              title: 'Subtopic A',
              blocks: [block('block_a')],
            ),
          ],
        ),
      ]);

      await showPanel(tester, content);

      expect(find.text('VALIDATION PASSED'), findsOneWidget);
      expectCheckStatus('Competency exists', 'PASS');
      expectCheckStatus('Topics detected', 'PASS');
      expectCheckStatus('Subtopics detected', 'PASS');
      expectCheckStatus('Content blocks', 'PASS');
      expectCheckStatus('Competency ID', 'PASS');
      expectCheckStatus('Topic IDs', 'PASS');
      expectCheckStatus('Subtopic IDs', 'PASS');
      expect(find.text('Main content topics'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'duplicate topic IDs fail the identifier check and surface validator path',
    (tester) async {
      final content = contentWithTopics([
        topic(
          id: 'topic_duplicate',
          title: 'Topic A',
          subtopics: [
            subtopic(
              id: 'subtopic_a',
              title: 'Subtopic A',
              blocks: [block('block_a')],
            ),
          ],
        ),
        topic(
          id: 'topic_duplicate',
          title: 'Topic B',
          subtopics: [
            subtopic(
              id: 'subtopic_b',
              title: 'Subtopic B',
              blocks: [block('block_b')],
            ),
          ],
        ),
      ]);

      await showPanel(tester, content);

      expect(find.text('ACTION REQUIRED'), findsOneWidget);
      expectCheckStatus('Topic IDs', 'CHECK');
      expectCheckStatus('Subtopic IDs', 'PASS');
      expect(find.text('Duplicate topic ID: topic_duplicate'), findsOneWidget);
      expect(find.text('topics[1].id'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('subtopic IDs are checked globally across parent topics', (
    tester,
  ) async {
    final content = contentWithTopics([
      topic(
        id: 'topic_a',
        title: 'Topic A',
        subtopics: [
          subtopic(
            id: 'subtopic_duplicate',
            title: 'Subtopic A',
            blocks: [block('block_a')],
          ),
        ],
      ),
      topic(
        id: 'topic_b',
        title: 'Topic B',
        subtopics: [
          subtopic(
            id: 'subtopic_duplicate',
            title: 'Subtopic B',
            blocks: [block('block_b')],
          ),
        ],
      ),
    ]);

    await showPanel(tester, content);

    expect(find.text('ACTION REQUIRED'), findsOneWidget);
    expectCheckStatus('Topic IDs', 'PASS');
    expectCheckStatus('Subtopic IDs', 'CHECK');
    expect(
      find.text('Duplicate subtopic ID: subtopic_duplicate'),
      findsOneWidget,
    );
    expect(find.text('topics[1].subtopics[0].id'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('content blocks are read directly from StudySubtopic blocks', (
    tester,
  ) async {
    final content = contentWithTopics([
      topic(
        id: 'topic_a',
        title: 'Topic A',
        subtopics: [
          subtopic(
            id: 'subtopic_a',
            title: 'Subtopic A',
            blocks: [block('block_a'), block('block_b')],
          ),
        ],
      ),
    ]);

    await showPanel(tester, content);

    expectCheckStatus('Content blocks', 'PASS');
    expect(
      find.textContaining('Subtopic contains no content blocks.'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
