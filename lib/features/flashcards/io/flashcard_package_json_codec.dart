import 'dart:convert';

import '../models/flashcard_content_package.dart';

class FlashcardPackageJsonCodec {
  const FlashcardPackageJsonCodec();

  FlashcardContentPackage decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException(
        'Flashcard package JSON root must be an object.',
      );
    }

    return FlashcardContentPackage.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  String encode(FlashcardContentPackage package) {
    return const JsonEncoder.withIndent('  ').convert(package.toJson());
  }
}
