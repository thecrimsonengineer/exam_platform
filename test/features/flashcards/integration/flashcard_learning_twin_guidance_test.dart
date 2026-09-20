import 'package:exam_platform/features/flashcards/flashcards.dart';
import 'package:exam_platform/features/learning_twin/integration/learning_twin_flashcard_guidance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('due summary produces sanitized Flashcard review guidance', (
    tester,
  ) async {
    const summary = FlashcardLearningTwinSummary(
      ownedCount: 7,
      unseenCount: 1,
      dueCount: 3,
      weakCount: 2,
      totalReviewEvents: 12,
      dueDomainIds: <String>['d03', 'd06'],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningTwinFlashcardGuidance(summary: summary),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('A short memory review is ready'), findsOneWidget);
    expect(find.textContaining('3 concept cards'), findsOneWidget);
    expect(find.textContaining('2 weaker concepts'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('learning-twin-flashcard-guidance'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('unseen summary explains first reveal activation', (tester) async {
    const summary = FlashcardLearningTwinSummary(
      ownedCount: 2,
      unseenCount: 2,
      dueCount: 0,
      weakCount: 0,
      totalReviewEvents: 0,
      dueDomainIds: <String>[],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningTwinFlashcardGuidance(summary: summary),
        ),
      ),
    );

    expect(find.text('New concept cards are waiting'), findsOneWidget);
    expect(find.textContaining('begins only after'), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss guidance'));
    await tester.pump();

    expect(find.text('New concept cards are waiting'), findsNothing);
  });
}
