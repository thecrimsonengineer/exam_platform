import 'dart:convert';
import 'dart:math';

import 'package:exam_platform/features/lab/lab_published_payload_chunks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('published LAB payload codec chunks and reassembles large fields', () {
    final random = Random(112358);
    String largeText(int byteCount) {
      final bytes = List<int>.generate(
        byteCount,
        (_) => 32 + random.nextInt(95),
        growable: false,
      );
      return utf8.decode(bytes);
    }

    final fields = <String, String>{
      'publishedJson': largeText(1200 * 1024),
      'qualityEvidenceJson': largeText(900 * 1024),
      'exhaustiveRouteEvidenceJson': largeText(1800 * 1024),
      'publishEvidenceJson': largeText(1300 * 1024),
    };

    const codec = LabPublishedPayloadChunkCodec();
    final encoded = codec.encode(fields);

    expect(encoded.chunks.length, greaterThan(4));
    expect(
      encoded.chunks.length,
      lessThanOrEqualTo(kLabPublishedPayloadMaxChunksPerVersion),
    );

    for (final chunk in encoded.chunks) {
      expect(
        utf8.encode(jsonEncode(chunk.toJson())).length,
        lessThan(800 * 1024),
      );
    }

    final decoded = codec.decode(
      manifestJson: encoded.manifestJson,
      chunkJson: encoded.chunks.map((chunk) => chunk.toJson()),
    );

    expect(decoded, fields);
  });

  test('published LAB payload codec rejects a tampered chunk', () {
    const codec = LabPublishedPayloadChunkCodec();
    final fields = <String, String>{
      for (final name in kLabPublishedPayloadFieldNames)
        name: List<String>.filled(20000, name).join('|'),
    };
    final encoded = codec.encode(fields);
    final chunkJson = encoded.chunks
        .map((chunk) => Map<String, Object?>.from(chunk.toJson()))
        .toList(growable: false);

    chunkJson.first['dataBase64'] =
        (chunkJson.first['dataBase64'] as String) + 'AA';

    expect(
      () => codec.decode(
        manifestJson: encoded.manifestJson,
        chunkJson: chunkJson,
      ),
      throwsA(isA<LabPublishedPayloadException>()),
    );
  });
}
