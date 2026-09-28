import 'package:exam_platform/features/flashcards/cloud/flashcard_package_repository.dart';
import 'package:exam_platform/features/flashcards/cloud/published_flashcard_package.dart';
import 'package:exam_platform/screens/flashcards/flashcard_competency_review_screen.dart';
import 'package:exam_platform/screens/flashcards/flashcards_catalog_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ERDP-2 Flashcard execution', () {
    testWidgets('opens the assigned competency directly in the existing deck runtime', (
      tester,
    ) async {
      final repository = _FakeFlashcardPackageRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardCompetencyReviewScreen(
            competencyId: 'd02_c01',
            isDarkMode: false,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.loadedCompetencyIds, <String>['d02_c01']);
      expect(find.byType(FlashcardDeckScreen), findsOneWidget);
      expect(find.text('ERDP-2 Direct Review'), findsOneWidget);
      expect(find.byKey(const ValueKey('flashcard-study-card')), findsOneWidget);
    });

    testWidgets('fails visibly when the assigned competency package cannot load', (
      tester,
    ) async {
      final repository = _FakeFlashcardPackageRepository(failLoad: true);

      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardCompetencyReviewScreen(
            competencyId: 'd02_c01',
            isDarkMode: true,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Unable to open the assigned flashcards.'),
        findsOneWidget,
      );
      expect(find.text('RETRY'), findsOneWidget);
      expect(find.byType(FlashcardDeckScreen), findsNothing);
    });
  });
}

class _FakeFlashcardPackageRepository implements FlashcardPackageRepository {
  _FakeFlashcardPackageRepository({this.failLoad = false});

  final bool failLoad;
  final List<String> loadedCompetencyIds = <String>[];

  @override
  Future<List<PublishedFlashcardPackageDescriptor>> loadCatalog() async =>
      const <PublishedFlashcardPackageDescriptor>[];

  @override
  Future<FlashcardDeckPackage> loadCompetency(String competencyId) async {
    loadedCompetencyIds.add(competencyId);
    if (failLoad) {
      throw StateError('test package unavailable');
    }

    return FlashcardDeckPackage(
      competencyId: competencyId,
      domainId: 'd02',
      deckId: 'erdp2-direct-review',
      title: 'ERDP-2 Direct Review',
      cards: const <FlashcardCard>[
        FlashcardCard(
          id: 'erdp2-card-01',
          frontLabel: 'Management system',
          backDefinition: 'A coordinated framework for managing work.',
          whyItMatters: 'It supports consistent risk control.',
          keyPoint: 'Review the assigned competency, not a generic catalogue.',
          tags: <String>['erdp2', 'retention'],
        ),
      ],
    );
  }
}
