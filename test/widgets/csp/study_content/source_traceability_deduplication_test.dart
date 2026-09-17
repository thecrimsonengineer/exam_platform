import 'package:exam_platform/models/study_content.dart';
import 'package:exam_platform/widgets/csp/study_content/study_subtopic_renderer.dart';
import 'package:exam_platform/widgets/csp/study_content/study_subtopic_renderer_dark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  StudySubtopic buildSubtopic() {
    return const StudySubtopic(
      id: 'd01_c01_s01',
      title: 'Source traceability rendering',
      blocks: [
        ContentBlock(
          id: 'duplicate-traceability-reference',
          type: 'reference',
          data: {
            'title': 'CSP Source Traceability',
            'source': 'Duplicated source row',
            'content': 'Duplicated detail row',
          },
        ),
        ContentBlock(
          id: 'legitimate-inline-reference',
          type: 'reference',
          data: {
            'title': 'Inline Regulatory Reference',
            'source': 'Keep inline source',
            'content': 'Keep inline detail',
          },
        ),
      ],
      references: ['Authoritative source material reference'],
    );
  }

  Future<void> pumpLight(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StudySubtopicRenderer(subtopic: buildSubtopic(), domain: 1),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpDark(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: DarkStudySubtopicRenderer(
              subtopic: buildSubtopic(),
              domain: 1,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectDeduplicatedPresentation() {
    // The duplicate Main Content reference card must be hidden.
    expect(find.text('CSP Source Traceability'), findsNothing);
    expect(find.text('Duplicated source row'), findsNothing);
    expect(find.text('Duplicated detail row'), findsNothing);

    // Source Material -> References remains authoritative and visible.
    expect(find.text('SOURCE MATERIAL'), findsOneWidget);
    expect(find.text('References'), findsOneWidget);
    expect(
      find.text('Authoritative source material reference'),
      findsOneWidget,
    );

    // Other legitimate inline reference blocks remain visible.
    expect(find.text('Inline Regulatory Reference'), findsOneWidget);
    expect(find.text('Keep inline source'), findsOneWidget);
    expect(find.text('Keep inline detail'), findsOneWidget);
  }

  testWidgets(
    'light renderer hides duplicate CSP Source Traceability card only',
    (tester) async {
      await pumpLight(tester);
      expectDeduplicatedPresentation();
    },
  );

  testWidgets(
    'dark renderer hides duplicate CSP Source Traceability card only',
    (tester) async {
      await pumpDark(tester);
      expectDeduplicatedPresentation();
    },
  );
}
