import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exam_platform/models/study_content.dart';
import 'package:exam_platform/widgets/admin/study_content/structure/content_structure_panel.dart';

StudyContent packageWith(List<StudyTopic> topics) => StudyContent(
  id: 'd01_c01-v1',
  domainId: 'd01',
  competencyId: 'd01_c01',
  competencyNumber: 1,
  title: 'Inspector fixture',
  status: 'Draft',
  version: 1,
  topics: topics,
);

Future<void> showInspector(WidgetTester tester, StudyContent? content) async {
  tester.view.physicalSize = const Size(1400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: ContentStructurePanel(content: content)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows missing-package and empty-topic states', (tester) async {
    await showInspector(tester, null);
    expect(find.text('No imported content'), findsOneWidget);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ContentStructurePanel(content: packageWith([]))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No topics detected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders canonical children and resets both expansion levels', (
    tester,
  ) async {
    final content = packageWith(const [
      StudyTopic(
        id: 'topic_a',
        title: 'Alpha',
        subtopics: [
          StudySubtopic(
            id: 'shared_child_id',
            title: 'Alpha child',
            blocks: [
              ContentBlock(
                id: 'alpha_block',
                type: 'text',
                data: {'text': 'Alpha block body'},
              ),
            ],
            learningObjectives: ['Alpha objective'],
            keyPoints: ['Alpha key point'],
            examples: ['Alpha example'],
            caseStudies: ['Alpha case'],
            formulas: ['Alpha formula'],
            references: ['Alpha reference'],
            examTips: ['Alpha exam tip'],
            commonMistakes: ['Alpha mistake'],
            keyTakeaways: ['Alpha takeaway'],
            quizzes: [QuizReference(quizId: 'alpha_quiz')],
          ),
        ],
      ),
      StudyTopic(
        id: 'topic_b',
        title: 'Beta',
        subtopics: [StudySubtopic(id: 'shared_child_id', title: 'Beta child')],
      ),
      StudyTopic(id: 'topic_empty', title: 'Empty topic'),
    ]);
    await showInspector(tester, content);
    expect(find.text('3 topics | 2 subtopics'), findsOneWidget);
    expect(find.text('Alpha block body'), findsNothing);

    for (var cycle = 0; cycle < 2; cycle++) {
      await tester.tap(find.text('Expand All'));
      await tester.pumpAndSettle();
      expect(find.text('Alpha child'), findsOneWidget);
      expect(find.text('Beta child'), findsOneWidget);
      expect(find.text('Alpha block body'), findsOneWidget);
      expect(find.text('alpha_block'), findsOneWidget);
      expect(find.text('Alpha objective'), findsOneWidget);
      for (final text in [
        'Alpha key point',
        'Alpha example',
        'Alpha case',
        'Alpha formula',
        'Alpha reference',
        'Alpha exam tip',
        'Alpha mistake',
        'Alpha takeaway',
      ]) {
        expect(find.text('1. $text'), findsOneWidget);
      }
      expect(find.text('alpha_quiz'), findsOneWidget);
      expect(find.text('No content blocks supplied.'), findsOneWidget);
      expect(find.text('No subtopics in this topic.'), findsOneWidget);
      expect(find.text('Main Content'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Collapse All'));
      await tester.pumpAndSettle();
      expect(find.text('Alpha child'), findsNothing);
      expect(find.text('Alpha block body'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });
}
