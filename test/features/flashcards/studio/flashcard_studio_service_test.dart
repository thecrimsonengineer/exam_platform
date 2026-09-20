import 'dart:io';

import 'package:exam_platform/features/flashcards/flashcards.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Studio imports, validates, saves, exports and reports coverage',
    () async {
      final repository = MemoryFlashcardPackageRepository();
      final studio = FlashcardStudioService(repository: repository);
      final source = File(
        'assets/flashcards/run3/fc_reference_package.v1.json',
      ).readAsStringSync();

      final imported = studio.importJson(source);
      expect(imported.fcq.passed, isTrue);
      expect(imported.fcq.score, 100);

      await studio.savePackage(imported.contentPackage);

      final index = await studio.buildDeckIndex();
      expect(index.deckCount, 1);
      expect(index.cardCount, 2);
      expect(index.conceptCount, 2);
      expect(index.mappingCount, 2);

      final exported = await studio.exportJson('d03_c02_flashcards_v1');
      final decoded = const FlashcardPackageJsonCodec().decode(exported);
      expect(decoded.packageId, 'd03_c02_flashcards_v1');

      final coverage = await studio.mappingCoverage(
        'd03_c02_flashcards_v1',
        eligibleQuestionIds: const <int>[930001, 930002, 930003],
      );
      expect(coverage.mappingCount, 2);
      expect(coverage.unmappedEligibleQuestionIds, <int>[930003]);
      expect(coverage.eligibleQuestionCoverageRatio, closeTo(2 / 3, 0.0001));
      expect(coverage.conceptsWithoutMappings, isEmpty);

      await studio.deletePackage('d03_c02_flashcards_v1');
      expect((await studio.buildDeckIndex()).deckCount, 0);
    },
  );

  test('Studio rejects structurally broken packages before save', () async {
    final repository = MemoryFlashcardPackageRepository();
    final studio = FlashcardStudioService(repository: repository);
    final source = File(
      'assets/flashcards/run3/fc_reference_package.v1.json',
    ).readAsStringSync();
    final contentPackage = const FlashcardPackageJsonCodec().decode(source);
    final json = contentPackage.toJson();
    final deck = Map<String, dynamic>.from(json['deck'] as Map);
    deck['cardIds'] = <String>['csp11.flashcard.hierarchy_of_controls'];
    json['deck'] = deck;

    final broken = FlashcardContentPackage.fromJson(json);

    await expectLater(studio.savePackage(broken), throwsFormatException);
  });
}
