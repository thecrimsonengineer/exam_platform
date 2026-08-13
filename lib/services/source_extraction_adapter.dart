import 'dart:typed_data';

import '../models/source_extraction_result.dart';

abstract class SourceExtractionAdapter {
  bool supports({
    required String fileName,
    required String? mimeType,
  });

  Future<List<ExtractedSourcePage>> extract({
    required Uint8List bytes,
  });
}

/// Minimal text adapter for plain-text sources and development testing.
/// PDF/DOCX adapters should implement SourceExtractionAdapter separately.
class PlainTextSourceExtractionAdapter
    implements SourceExtractionAdapter {
  const PlainTextSourceExtractionAdapter();

  @override
  bool supports({
    required String fileName,
    required String? mimeType,
  }) {
    final name = fileName.toLowerCase();
    return name.endsWith('.txt') ||
        name.endsWith('.md') ||
        mimeType == 'text/plain' ||
        mimeType == 'text/markdown';
  }

  @override
  Future<List<ExtractedSourcePage>> extract({
    required Uint8List bytes,
  }) async {
    final text = String.fromCharCodes(bytes);
    return [
      ExtractedSourcePage(
        pageNumber: 1,
        text: text,
      ),
    ];
  }
}
