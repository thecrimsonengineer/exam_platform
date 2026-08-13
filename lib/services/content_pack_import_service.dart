import '../models/content_pack.dart';
import '../models/content_pack_import_result.dart';

class ContentPackImportService {
  const ContentPackImportService();

  ContentPackImportResult validate(
    Csp11ContentPack pack,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    if (pack.packId.trim().isEmpty) {
      errors.add('Pack ID is required.');
    }

    if (pack.title.trim().isEmpty) {
      errors.add('Pack title is required.');
    }

    if (pack.items.isEmpty) {
      errors.add('The content pack contains no items.');
    }

    final topicIds = <String>{};

    for (final item in pack.items) {
      if (item.domainId.trim().isEmpty) {
        errors.add('An item is missing a domain ID.');
      }
      if (item.competencyId.trim().isEmpty) {
        errors.add('An item is missing a competency ID.');
      }
      if (item.subtopicId.trim().isEmpty) {
        errors.add('An item is missing a subtopic ID.');
      }
      if (item.topicId.trim().isEmpty) {
        errors.add('An item is missing a topic ID.');
      }
      if (item.title.trim().isEmpty) {
        errors.add('An item is missing a title.');
      }
      if (item.content.trim().isEmpty) {
        errors.add('An item is missing content.');
      }

      if (!topicIds.add(item.topicId)) {
        warnings.add(
          'Duplicate topic ID detected: ${item.topicId}.',
        );
      }
    }

    return ContentPackImportResult(
      ready: errors.isEmpty,
      packId: pack.packId,
      errors: List.unmodifiable(errors),
      warnings: List.unmodifiable(warnings),
    );
  }
}
