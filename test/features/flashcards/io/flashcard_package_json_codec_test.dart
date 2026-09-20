import 'dart:io';

import 'package:exam_platform/features/flashcards/flashcards.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const codec = FlashcardPackageJsonCodec();

  test(
    'reference package JSON round trip is byte stable after first encode',
    () {
      final source = File(
        'assets/flashcards/run3/fc_reference_package.v1.json',
      ).readAsStringSync();

      final decoded = codec.decode(source);
      final first = codec.encode(decoded);
      final second = codec.encode(codec.decode(first));

      expect(second, first);
      expect(decoded.packageId, 'd03_c02_flashcards_v1');
      expect(decoded.cards, hasLength(2));
      expect(decoded.sources, hasLength(1));
    },
  );

  test('unsupported schema fails closed at the import boundary', () {
    const source = '{"schemaVersion":"future.v99","deck":{}}';

    expect(() => codec.decode(source), throwsFormatException);
  });

  test('non-object JSON root fails closed', () {
    expect(() => codec.decode('[]'), throwsFormatException);
  });
}
