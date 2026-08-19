import 'package:file_selector/file_selector.dart';

import '../models/content_source.dart';
import '../models/source_extraction_result.dart';
import 'content_source_library_service.dart';
import 'source_extraction_adapter.dart';

class SourceUploadService {
  final ContentSourceLibraryService _library;
  final List<SourceExtractionAdapter> _adapters;

  const SourceUploadService({
    this._library = const ContentSourceLibraryService(),
    List<SourceExtractionAdapter> adapters = const [
      PlainTextSourceExtractionAdapter(),
    ],
  }) : _adapters = adapters;

  Future<SourceExtractionResult?> selectAndExtract() async {
    const group = XTypeGroup(
      label: 'Reference documents',
      extensions: ['txt', 'md', 'pdf', 'docx'],
    );

    final file = await openFile(acceptedTypeGroups: [group]);
    if (file == null) return null;

    return extractFile(file);
  }

  Future<SourceExtractionResult> extractFile(XFile file) async {
    final bytes = await file.readAsBytes();
    final mimeType = file.mimeType ?? '';

    final now = DateTime.now();
    final sourceId = 'src_${now.microsecondsSinceEpoch}';

    final source = ContentSource(
      id: sourceId,
      title: file.name,
      type: ContentSourceType.other,
      localFileName: file.name,
      mimeType: mimeType,
      fileSizeBytes: bytes.length,
      status: ContentSourceStatus.analyzing,
      createdAt: now,
      updatedAt: now,
    );

    await _library.save(source);

    for (final adapter in _adapters) {
      if (adapter.supports(fileName: file.name, mimeType: mimeType)) {
        final pages = await adapter.extract(bytes: bytes);
        await _library.save(
          source.copyWith(
            status: ContentSourceStatus.analyzed,
            updatedAt: DateTime.now(),
          ),
        );

        return SourceExtractionResult(
          sourceId: sourceId,
          fileName: file.name,
          mimeType: mimeType,
          byteLength: bytes.length,
          pages: pages,
          successful: true,
        );
      }
    }

    await _library.save(
      source.copyWith(
        status: ContentSourceStatus.registered,
        updatedAt: DateTime.now(),
      ),
    );

    return SourceExtractionResult(
      sourceId: sourceId,
      fileName: file.name,
      mimeType: mimeType,
      byteLength: bytes.length,
      pages: const [],
      successful: false,
      errorMessage: 'No extraction adapter is registered for this file type.',
    );
  }
}
