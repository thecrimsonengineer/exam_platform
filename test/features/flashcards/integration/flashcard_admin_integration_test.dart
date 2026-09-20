import 'dart:io';

import 'package:exam_platform/features/flashcards/flashcards.dart';
import 'package:exam_platform/models/question.dart';
import 'package:exam_platform/models/study_content.dart';
import 'package:exam_platform/screens/admin/flashcards/flashcard_diagnostics_screen.dart';
import 'package:exam_platform/screens/admin/flashcards/flashcard_studio_screen.dart';
import 'package:exam_platform/services/study_content/local_study_content_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Flashcard Studio imports, previews and saves local package', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = MemoryFlashcardPackageRepository();
    final studio = FlashcardStudioService(repository: repository);
    final source = File(
      'assets/flashcards/run3/fc_reference_package.v1.json',
    ).readAsStringSync();

    await tester.pumpWidget(
      MaterialApp(home: FlashcardStudioScreen(studioService: studio)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('flashcard-studio-json')),
      source,
    );
    final preview = find.byKey(const ValueKey('flashcard-studio-preview'));
    await tester.ensureVisible(preview);
    await tester.pumpAndSettle();
    await tester.tap(preview);
    await tester.pumpAndSettle();

    final studioList = find.byKey(const ValueKey('flashcard-studio-list'));
    final studioScrollable = find
        .descendant(of: studioList, matching: find.byType(Scrollable))
        .first;
    final fcqPass = find.textContaining('FCQ100 100/100 PASS');
    await tester.scrollUntilVisible(fcqPass, 300, scrollable: studioScrollable);
    expect(fcqPass, findsOneWidget);
    expect(find.text('Hierarchy of Controls'), findsOneWidget);

    final save = find.byKey(const ValueKey('flashcard-studio-save'));
    expect(save, findsOneWidget);
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(await repository.listPackageIds(), <String>[
      'd03_c02_flashcards_v1',
    ]);
  });

  testWidgets('Flashcard Diagnostics renders four healthy integration panels', (
    tester,
  ) async {
    final contentPackage = const FlashcardPackageJsonCodec().decode(
      File(
        'assets/flashcards/run3/fc_reference_package.v1.json',
      ).readAsStringSync(),
    );
    final integration = FlashcardIntegrationService(
      packageRepository: MemoryFlashcardPackageRepository(
        seed: <FlashcardContentPackage>[contentPackage],
      ),
      collectionRepository: MemoryFlashcardCollectionRepository(),
      reviewRepository: MemoryFlashcardReviewRepository(),
      sessionRepository: MemoryFlashcardReviewSessionRepository(),
      userIdOverride: 'fc7-diagnostics',
    );

    final studyRepository = LocalStudyContentRepository();
    await studyRepository.publish(_validatedStudyContent());

    await tester.pumpWidget(
      MaterialApp(
        home: FlashcardDiagnosticsScreen(
          learnerIdOverride: 'fc7-diagnostics',
          integrationService: integration,
          studyContentRepository: studyRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('FC7 integration health is green'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('flashcard-diagnostics-mapping')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('flashcard-diagnostics-source')),
      findsOneWidget,
    );

    final diagnosticsList = find.byKey(
      const ValueKey('flashcard-diagnostics-list'),
    );
    final diagnosticsScrollable = find
        .descendant(of: diagnosticsList, matching: find.byType(Scrollable))
        .first;
    final placement = find.byKey(
      const ValueKey('flashcard-diagnostics-placement'),
    );
    await tester.scrollUntilVisible(
      placement,
      300,
      scrollable: diagnosticsScrollable,
    );
    expect(placement, findsOneWidget);

    final collection = find.byKey(
      const ValueKey('flashcard-diagnostics-collection'),
    );
    await tester.scrollUntilVisible(
      collection,
      300,
      scrollable: diagnosticsScrollable,
    );
    expect(collection, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

StudyContent _validatedStudyContent() {
  const q1 = Question(
    id: 930001,
    domain: 3,
    competencyId: 'd03_c02',
    subtopicId: 'd03_c02_t01_s01',
    topicId: 'd03_c02_t01',
    question: 'Hierarchy question one for diagnostics coverage.',
    options: <String>['A', 'B', 'C', 'D'],
    correctAnswer: 0,
    explanation: 'Diagnostic fixture explanation one.',
    reference: 'NIOSH',
    difficulty: 'Hard',
    tags: <String>['risk-management', 'controls'],
  );
  const q2 = Question(
    id: 930002,
    domain: 3,
    competencyId: 'd03_c02',
    subtopicId: 'd03_c02_t01_s01',
    topicId: 'd03_c02_t01',
    question: 'Hierarchy question two for diagnostics coverage.',
    options: <String>['A', 'B', 'C', 'D'],
    correctAnswer: 0,
    explanation: 'Diagnostic fixture explanation two.',
    reference: 'NIOSH',
    difficulty: 'Hard',
    tags: <String>['risk-management', 'elimination'],
  );

  return const StudyContent(
    id: 'content-d03-c02-v1',
    domainId: 'd03',
    competencyId: 'd03_c02',
    competencyNumber: 2,
    title: 'Risk Management',
    status: 'validated',
    version: 1,
    topics: <StudyTopic>[
      StudyTopic(
        id: 'd03_c02_t01',
        title: 'Risk controls',
        subtopics: <StudySubtopic>[
          StudySubtopic(
            id: 'd03_c02_t01_s01',
            title: 'Hierarchy',
            questions: <Question>[q1, q2],
          ),
        ],
      ),
    ],
  );
}
