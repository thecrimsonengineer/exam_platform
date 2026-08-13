import '../models/bulk_edit_operation.dart';

class BulkEditService {
  const BulkEditService();

  List<Map<String, dynamic>> apply(
    BulkEditOperation operation,
    List<Map<String, dynamic>> records,
  ) {
    final selected = operation.contentIds.toSet();

    return records.map((record) {
      final copy = Map<String, dynamic>.from(record);
      final id = copy['id']?.toString() ?? '';

      if (!selected.contains(id)) {
        return copy;
      }

      if (operation.difficulty != null) {
        copy['difficulty'] = operation.difficulty;
      }

      if (operation.cognitiveLevel != null) {
        copy['cognitiveLevel'] = operation.cognitiveLevel;
      }

      if (operation.tags != null) {
        copy['tags'] = List<String>.from(operation.tags!);
      }

      copy['status'] = 'Draft';
      return copy;
    }).toList(growable: false);
  }
}
