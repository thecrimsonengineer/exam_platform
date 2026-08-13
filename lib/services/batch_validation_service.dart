import '../models/batch_validation_report.dart';

class BatchValidationService {
  const BatchValidationService();

  BatchValidationReport validate(
    List<Map<String, dynamic>> records,
  ) {
    final items = <BatchValidationItem>[];

    for (final record in records) {
      final id = record['id']?.toString() ?? '';
      final errors = <String>[];
      final warnings = <String>[];

      if (id.isEmpty) {
        errors.add('Missing record ID.');
      }

      if ((record['title']?.toString() ?? '').trim().isEmpty) {
        errors.add('Missing title.');
      }

      if ((record['content']?.toString() ?? '').trim().isEmpty) {
        errors.add('Missing content.');
      }

      if ((record['sourceId']?.toString() ?? '').trim().isEmpty) {
        warnings.add('No source reference is attached.');
      }

      if ((record['competencyId']?.toString() ?? '').trim().isEmpty) {
        errors.add('Missing competency mapping.');
      }

      items.add(
        BatchValidationItem(
          recordId: id,
          errors: List.unmodifiable(errors),
          warnings: List.unmodifiable(warnings),
        ),
      );
    }

    return BatchValidationReport(
      items: List.unmodifiable(items),
    );
  }
}
