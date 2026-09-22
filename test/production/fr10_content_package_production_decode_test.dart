import 'dart:io';

import 'package:exam_platform/services/study_content/published_content_package.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final packagePath = Platform.environment['FR10_PROOF_PACKAGE_PATH'];
  final competencyId = Platform.environment['FR10_PROOF_COMPETENCY_ID'];
  final contentVersion = int.tryParse(
    Platform.environment['FR10_PROOF_CONTENT_VERSION'] ?? '',
  );
  final checksum = Platform.environment['FR10_PROOF_CHECKSUM'];
  final sizeBytes = int.tryParse(
    Platform.environment['FR10_PROOF_SIZE_BYTES'] ?? '',
  );

  final configured =
      packagePath != null &&
      competencyId != null &&
      contentVersion != null &&
      checksum != null &&
      sizeBytes != null;

  test(
    'FR10F live production package decodes through the app decoder',
    () {
      final bytes = File(packagePath!).readAsBytesSync();
      final descriptor = PublishedContentPackageDescriptor(
        competencyId: competencyId!,
        version: contentVersion!,
        checksumSha256: checksum!,
        compressedBytes: sizeBytes!,
      );

      final decoded = const ContentPackageDecoder().decode(
        descriptor: descriptor,
        compressedBytes: bytes,
      );

      expect(decoded.descriptor.competencyId, competencyId);
      expect(decoded.descriptor.version, contentVersion);
      expect(decoded.content.competencyId, competencyId);
      expect(decoded.content.status, 'published');
      expect(decoded.content.domainId, competencyId.substring(0, 3));
      expect(decoded.content.version, greaterThan(0));
      expect(decoded.content.id, isNotEmpty);
      expect(decoded.content.title, isNotEmpty);
    },
    skip: configured ? false : 'FR10 production proof environment not set.',
  );
}
