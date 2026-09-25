import 'package:flutter_test/flutter_test.dart';

import '../../../tool/fcc_flashcard_publish/fcc_flashcard_publish_core.dart';

void main() {
  test('FCC frozen FCP1/FCP2 source is exactly 21 packages / 252 cards', () {
    final plan = const FccFlashcardPackageBuilder().build(
      sources: loadFccFrozenFcp12Sources(),
    );

    expect(plan.packageCount, fccExpectedPackageCount);
    expect(plan.cardCount, fccExpectedCardCount);
    expect(plan.newPackageCount, fccExpectedPackageCount);
    expect(plan.reusedPackageCount, 0);

    final ids = plan.packages.map((item) => item.competencyId).toList();
    expect(ids, fccExpectedCompetencyCardCounts.keys.toList());

    for (final package in plan.packages) {
      expect(
        package.storagePath,
        'flashcards/${package.competencyId}/v1.json.gz',
      );
      expect(package.version, 1);
      expect(
        package.artifact.cardCount,
        fccExpectedCompetencyCardCounts[package.competencyId],
      );
      expect(package.artifact.checksumSha256, hasLength(64));
      expect(package.artifact.uncompressedChecksumSha256, hasLength(64));
    }
  });

  test('FCC reuses a byte-identical immutable package version', () {
    final first = const FccFlashcardPackageBuilder().build(
      sources: loadFccFrozenFcp12Sources(),
    );
    final target = first.packages.first;

    final second = const FccFlashcardPackageBuilder().build(
      sources: loadFccFrozenFcp12Sources(),
      existingPackageRows: <Map<String, dynamic>>[
        <String, dynamic>{
          'package_kind': 'flashcards',
          'package_key': target.competencyId,
          'version': 1,
          'storage_bucket': fccBucketId,
          'storage_path': target.storagePath,
          'checksum_sha256': target.artifact.checksumSha256,
          'compressed_bytes': target.artifact.compressedByteCount,
          'item_count': target.artifact.cardCount,
          'is_current': true,
        },
      ],
    );

    final reused = second.packages.firstWhere(
      (item) => item.competencyId == target.competencyId,
    );
    expect(reused.reusesExistingPackage, isTrue);
    expect(reused.version, 1);
  });
}
