import 'dart:io';

import 'package:exam_platform/features/flashcards/flashcards.dart';
import 'package:exam_platform/models/question.dart';
import 'package:exam_platform/screens/courses/csp/quiz/quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Quiz shows reward only after mapped ownership commit', (
    tester,
  ) async {
    final contentPackage = const FlashcardPackageJsonCodec().decode(
      File(
        'assets/flashcards/run3/fc_reference_package.v1.json',
      ).readAsStringSync(),
    );
    final collectionRepository = MemoryFlashcardCollectionRepository();
    final integration = FlashcardIntegrationService(
      packageRepository: MemoryFlashcardPackageRepository(
        seed: <FlashcardContentPackage>[contentPackage],
      ),
      collectionRepository: collectionRepository,
      reviewRepository: MemoryFlashcardReviewRepository(),
      sessionRepository: MemoryFlashcardReviewSessionRepository(),
      userIdOverride: 'fc7-quiz-widget',
    );

    const question = Question(
      id: 930001,
      domain: 3,
      competencyId: 'd03_c02',
      subtopicId: '',
      topicId: '',
      question:
          'Which control approach should normally be preferred when a hazard '
          'can be removed completely?',
      options: <String>[
        'Eliminate the hazard',
        'Issue personal protective equipment',
        'Add a warning sign',
        'Rely on worker awareness',
      ],
      correctAnswer: 0,
      explanation:
          'Removing the hazard prevents the exposure rather than relying on '
          'worker action.',
      reference: 'NIOSH Hierarchy of Controls',
      difficulty: 'Hard',
      tags: <String>['risk-management', 'controls'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: QuizScreen(
          domain: 3,
          customQuestions: const <Question>[question],
          flashcardIntegrationService: integration,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NEW CONCEPT COLLECTED'), findsNothing);

    final answer = find.text('Eliminate the hazard');
    await tester.ensureVisible(answer);
    await tester.tap(answer);
    await tester.pump();

    final submit = find.text('SUBMIT ANSWER');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('NEW CONCEPT COLLECTED'), findsOneWidget);
    expect(find.text('Hierarchy of Controls'), findsWidgets);

    final persisted = await collectionRepository.loadOwnership(
      learnerId: 'fc7-quiz-widget',
      cardId: 'csp11.flashcard.hierarchy_of_controls',
    );
    expect(persisted, isNotNull);
    expect(persisted?.correctSignalCount, 1);
    expect(tester.takeException(), isNull);
  });
}
