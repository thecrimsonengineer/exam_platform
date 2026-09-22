import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exam_platform/services/study_content/published_content_package.dart';

void main() {
  group('FR10A content package gateway contracts', () {
    test('current package metadata refuses a signed URL', () {
      final resolution = ContentPackageResolution.fromJson(
        _resolutionJson(current: true),
      );

      expect(resolution.current, isTrue);
      expect(resolution.signedUrl, isNull);
      expect(resolution.descriptor.competencyId, 'd01_c01');
      expect(resolution.descriptor.version, 3);
    });

    test('changed package requires an HTTPS signed URL', () {
      final resolution = ContentPackageResolution.fromJson(
        _resolutionJson(
          current: false,
          signedUrl: 'https://example.supabase.co/storage/signed/content',
        ),
      );

      expect(resolution.current, isFalse);
      expect(resolution.signedUrl, isNotNull);
      expect(resolution.signedUrl!.scheme, 'https');
    });

    test('changed package rejects a missing signed URL', () {
      expect(
        () => ContentPackageResolution.fromJson(
          _resolutionJson(current: false),
        ),
        throwsFormatException,
      );
    });

    test('catalog descriptor validates checksum and byte count', () {
      expect(
        () => PublishedContentPackageDescriptor.fromJson(<String, dynamic>{
          ..._descriptorJson(),
          'contentChecksumSha256': 'bad-checksum',
        }),
        throwsFormatException,
      );

      expect(
        () => PublishedContentPackageDescriptor.fromJson(<String, dynamic>{
          ..._descriptorJson(),
          'contentSizeBytes': -1,
        }),
        throwsFormatException,
      );
    });
  });

  group('FR10A strict content package decoder', () {
    test('accepts a valid FR7 content package', () {
      final package = _package();

      final verified = const ContentPackageDecoder().decode(
        descriptor: package.descriptor,
        compressedBytes: package.bytes,
      );

      expect(verified.content.id, 'd01_c01-v5');
      expect(verified.content.domainId, 'd01');
      expect(verified.content.competencyId, 'd01_c01');
      expect(verified.content.version, 5);
      expect(verified.content.status, 'published');
    });

    test('rejects compressed byte-count mismatch', () {
      final package = _package();
      final descriptor = PublishedContentPackageDescriptor(
        competencyId: package.descriptor.competencyId,
        version: package.descriptor.version,
        checksumSha256: package.descriptor.checksumSha256,
        compressedBytes: package.descriptor.compressedBytes + 1,
      );

      expect(
        () => const ContentPackageDecoder().decode(
          descriptor: descriptor,
          compressedBytes: package.bytes,
        ),
        throwsFormatException,
      );
    });

    test('rejects compressed SHA-256 mismatch', () {
      final package = _package();
      final descriptor = PublishedContentPackageDescriptor(
        competencyId: package.descriptor.competencyId,
        version: package.descriptor.version,
        checksumSha256: _hex64('0'),
        compressedBytes: package.descriptor.compressedBytes,
      );

      expect(
        () => const ContentPackageDecoder().decode(
          descriptor: descriptor,
          compressedBytes: package.bytes,
        ),
        throwsFormatException,
      );
    });

    test('rejects wrong envelope competency', () {
      final package = _package(
        envelopeOverrides: <String, dynamic>{'competencyId': 'd01_c02'},
      );

      expect(
        () => const ContentPackageDecoder().decode(
          descriptor: package.descriptor,
          compressedBytes: package.bytes,
        ),
        throwsFormatException,
      );
    });

    test('rejects cross-competency StudyContent', () {
      final package = _package(
        contentOverrides: <String, dynamic>{'competencyId': 'd01_c02'},
      );

      expect(
        () => const ContentPackageDecoder().decode(
          descriptor: package.descriptor,
          compressedBytes: package.bytes,
        ),
        throwsFormatException,
      );
    });

    test('rejects a domain that does not match the competency', () {
      final package = _package(
        contentOverrides: <String, dynamic>{'domainId': 'd02'},
      );

      expect(
        () => const ContentPackageDecoder().decode(
          descriptor: package.descriptor,
          compressedBytes: package.bytes,
        ),
        throwsFormatException,
      );
    });

    test('rejects non-published StudyContent', () {
      final package = _package(
        contentOverrides: <String, dynamic>{'status': 'validated'},
      );

      expect(
        () => const ContentPackageDecoder().decode(
          descriptor: package.descriptor,
          compressedBytes: package.bytes,
        ),
        throwsFormatException,
      );
    });

    test('rejects source version mismatch', () {
      final package = _package(
        envelopeOverrides: <String, dynamic>{'sourceVersion': 6},
      );

      expect(
        () => const ContentPackageDecoder().decode(
          descriptor: package.descriptor,
          compressedBytes: package.bytes,
        ),
        throwsFormatException,
      );
    });

    test('rejects competency-number mismatch', () {
      final package = _package(
        contentOverrides: <String, dynamic>{'competencyNumber': 2},
      );

      expect(
        () => const ContentPackageDecoder().decode(
          descriptor: package.descriptor,
          compressedBytes: package.bytes,
        ),
        throwsFormatException,
      );
    });
  });
}

Map<String, dynamic> _descriptorJson() => <String, dynamic>{
  'competencyId': 'd01_c01',
  'contentVersion': 3,
  'contentChecksumSha256': _hex64('a'),
  'contentSizeBytes': 1234,
};

Map<String, dynamic> _resolutionJson({
  required bool current,
  String? signedUrl,
}) {
  return <String, dynamic>{
    ..._descriptorJson(),
    'current': current,
    if (signedUrl != null) 'signedUrl': signedUrl,
  };
}

({PublishedContentPackageDescriptor descriptor, List<int> bytes}) _package({
  Map<String, dynamic> envelopeOverrides = const <String, dynamic>{},
  Map<String, dynamic> contentOverrides = const <String, dynamic>{},
}) {
  final content = <String, dynamic>{
    'id': 'd01_c01-v5',
    'domainId': 'd01',
    'competencyId': 'd01_c01',
    'competencyNumber': 1,
    'title': 'Prevention-Through-Design',
    'status': 'published',
    'version': 5,
    'topics': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'd01_c01_t01',
        'title': 'Design risk',
        'subtopics': <Map<String, dynamic>>[],
      },
    ],
    ...contentOverrides,
  };

  final envelope = <String, dynamic>{
    'schemaVersion': 1,
    'kind': 'content',
    'competencyId': 'd01_c01',
    'sourceVersion': 5,
    'content': content,
    ...envelopeOverrides,
  };

  final encoded = utf8.encode(jsonEncode(envelope));
  final compressed = GZipEncoder().encode(encoded);

  final descriptor = PublishedContentPackageDescriptor(
    competencyId: 'd01_c01',
    version: 3,
    checksumSha256: sha256.convert(compressed).toString(),
    compressedBytes: compressed.length,
  );

  return (descriptor: descriptor, bytes: compressed);
}

String _hex64(String character) {
  if (character.length != 1) {
    throw ArgumentError.value(character, 'character');
  }

  return List<String>.filled(64, character).join();
}
