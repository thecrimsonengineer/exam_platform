import '../models/content_import_row.dart';

class SpreadsheetImportService {
  const SpreadsheetImportService();

  List<String> validateRow(ContentImportRow row) {
    final errors = <String>[];

    if (row.domainId.trim().isEmpty) {
      errors.add('Domain is required.');
    }
    if (row.competencyId.trim().isEmpty) {
      errors.add('Competency is required.');
    }
    if (row.subtopic.trim().isEmpty) {
      errors.add('Subtopic is required.');
    }
    if (row.topic.trim().isEmpty) {
      errors.add('Topic is required.');
    }
    if (row.content.trim().isEmpty) {
      errors.add('Content is required.');
    }

    return List.unmodifiable(errors);
  }

  List<List<String>> parseCsv(String csv) {
    return csv
        .replaceAll('\r\n', '\n')
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map(_splitCsvLine)
        .toList(growable: false);
  }

  List<String> _splitCsvLine(String line) {
    final values = <String>[];
    final buffer = StringBuffer();
    var quoted = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (quoted && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
        continue;
      }

      if (char == ',' && !quoted) {
        values.add(buffer.toString().trim());
        buffer.clear();
        continue;
      }

      buffer.write(char);
    }

    values.add(buffer.toString().trim());
    return values;
  }
}
