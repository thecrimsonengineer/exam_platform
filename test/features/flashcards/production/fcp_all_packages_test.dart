import 'dart:io';

import 'package:exam_platform/features/flashcards/io/flashcard_package_json_codec.dart';
import 'package:exam_platform/features/flashcards/validation/fcq100_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const productionRoot = 'assets/flashcards/production';

  List<File> productionPackages() {
    return Directory(productionRoot)
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('_flashcards_v1.json'))
        .toList()
      ..sort((left, right) => left.path.compareTo(right.path));
  }

  test('every admitted FCP package passes FCQ100', () {
    final files = productionPackages();
    expect(files, isNotEmpty);

    for (final file in files) {
      final package = const FlashcardPackageJsonCodec().decode(
        file.readAsStringSync(),
      );
      final result = const Fcq100Validator().validate(package);

      expect(
        result.passed,
        isTrue,
        reason:
            '${file.path}: '
            '${result.failedRules.map((rule) => rule.message).join('; ')}',
      );
      expect(result.score, 100);
      expect(result.maxScore, 100);
    }
  });

  test('every admitted FCP package has a stable canonical JSON round trip', () {
    final files = productionPackages();
    expect(files, isNotEmpty);

    for (final file in files) {
      final codec = const FlashcardPackageJsonCodec();
      final first = codec.encode(codec.decode(file.readAsStringSync()));
      final second = codec.encode(codec.decode(first));

      expect(second, first, reason: file.path);
    }
  });
}
