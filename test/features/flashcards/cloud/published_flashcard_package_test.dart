import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:exam_platform/features/flashcards/cloud/published_flashcard_package.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FCC-2 decodes and verifies a signed flashcard package', () {
    final payload = <String, dynamic>{
      'schemaVersion': 'csp11.flashcards.package.v1',
      'deck': <String, dynamic>{
        'id': 'd01_c01_flashcards_v1',
        'domainId': 'd01',
        'competencyId': 'd01_c01',
        'title': 'Test Deck',
        'version': 1,
        'lifecycle': 'validated',
        'cardIds': <String>['card_1'],
      },
      'concepts': <Object?>[],
      'cards': <Object?>[
        <String, dynamic>{
          'id': 'card_1',
          'conceptId': 'concept_1',
          'version': 1,
          'type': 'principle',
          'frontLabel': 'Prevention through Design',
          'backDefinition': 'Design hazards out before exposure occurs.',
          'whyItMatters': 'Early design decisions can remove later exposure.',
          'keyPoint': 'Control risk as early as practical.',
          'primaryPlacement': <String, dynamic>{
            'domainId': 'd01',
            'competencyId': 'd01_c01',
          },
          'sourceRefs': <Object?>[],
          'lifecycle': 'validated',
          'tags': <String>['design'],
        },
      ],
      'questionMappings': <Object?>[],
      'sources': <Object?>[],
    };

    final compressed = gzip.encode(utf8.encode(jsonEncode(payload)));
    final descriptor = PublishedFlashcardPackageDescriptor(
      competencyId: 'd01_c01',
      version: 1,
      checksumSha256: sha256.convert(compressed).toString(),
      compressedBytes: compressed.length,
      flashcardCount: 1,
    );

    final verified = const FlashcardPackageDecoder().decode(
      descriptor: descriptor,
      compressedBytes: compressed,
    );

    expect(verified.package.competencyId, 'd01_c01');
    expect(verified.package.title, 'Test Deck');
    expect(verified.package.cards, hasLength(1));
    expect(
      verified.package.cards.single.frontLabel,
      'Prevention through Design',
    );
  });

  test('FCC-2 rejects checksum drift', () {
    final descriptor = PublishedFlashcardPackageDescriptor(
      competencyId: 'd01_c01',
      version: 1,
      checksumSha256: List<String>.filled(64, '0').join(),
      compressedBytes: 3,
      flashcardCount: 1,
    );

    expect(
      () => const FlashcardPackageDecoder().decode(
        descriptor: descriptor,
        compressedBytes: const <int>[1, 2, 3],
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('FCC-2 delivery descriptor uses exact protected response fields', () {
    final descriptor = PublishedFlashcardPackageDescriptor.fromJson(
      <String, dynamic>{
        'competencyId': 'd02_c14',
        'flashcardVersion': 1,
        'flashcardChecksumSha256': List<String>.filled(64, 'a').join(),
        'flashcardSizeBytes': 1200,
        'flashcardCount': 18,
      },
    );

    expect(descriptor.competencyId, 'd02_c14');
    expect(descriptor.flashcardCount, 18);
    expect(
      descriptor.toKnownRequestJson(),
      <String, dynamic>{
        'competencyId': 'd02_c14',
        'knownFlashcardVersion': 1,
        'knownFlashcardChecksumSha256': List<String>.filled(64, 'a').join(),
      },
    );
  });
}
