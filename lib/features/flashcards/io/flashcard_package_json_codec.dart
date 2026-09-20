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

    final contentPackage = FlashcardContentPackage.fromJson(
      Map<String, dynamic>.from(decoded),
    );
    if (contentPackage.schemaVersion !=
        FlashcardContentPackage.currentSchemaVersion) {
      throw FormatException(
        'Unsupported Flashcard package schema: '
        '${contentPackage.schemaVersion}.',
      );
    }
    return contentPackage;
  }

  String encode(FlashcardContentPackage contentPackage) {
    return const JsonEncoder.withIndent('  ').convert(contentPackage.toJson());
  }
}
