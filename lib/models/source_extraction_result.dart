class SourceExtractionResult {
  final String sourceId;
  final String fileName;
  final String mimeType;
  final int byteLength;

  final String extractedText;
  final int pageCount;
  final List<ExtractedSourcePage> pages;

  final bool successful;
  final bool success;

  final String? errorMessage;

  const SourceExtractionResult({
    this.sourceId = '',
    this.fileName = '',
    this.mimeType = '',
    this.byteLength = 0,
    this.extractedText = '',
    this.pageCount = 0,
    this.pages = const [],
    this.successful = false,
    this.success = false,
    this.errorMessage,
  });

  factory SourceExtractionResult.successResult({
    String sourceId = '',
    String fileName = '',
    String mimeType = '',
    int byteLength = 0,
    String extractedText = '',
    int pageCount = 0,
    List<ExtractedSourcePage> pages = const [],
  }) {
    return SourceExtractionResult(
      sourceId: sourceId,
      fileName: fileName,
      mimeType: mimeType,
      byteLength: byteLength,
      extractedText: extractedText,
      pageCount: pageCount,
      pages: pages,
      successful: true,
      success: true,
    );
  }

  factory SourceExtractionResult.failure({
    String sourceId = '',
    String fileName = '',
    String mimeType = '',
    int byteLength = 0,
    String errorMessage = 'Source extraction failed.',
  }) {
    return SourceExtractionResult(
      sourceId: sourceId,
      fileName: fileName,
      mimeType: mimeType,
      byteLength: byteLength,
      successful: false,
      success: false,
      errorMessage: errorMessage,
    );
  }
}

class ExtractedSourcePage {
  final int pageNumber;
  final String text;

  const ExtractedSourcePage({required this.pageNumber, required this.text});
}

/// Compatibility alias for code using the newer naming convention.
typedef SourceExtractedPage = ExtractedSourcePage;
