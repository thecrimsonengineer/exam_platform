class BatchValidationItem {
  final String recordId;
  final List<String> errors;
  final List<String> warnings;

  const BatchValidationItem({
    required this.recordId,
    required this.errors,
    required this.warnings,
  });

  bool get passed => errors.isEmpty;
}

class BatchValidationReport {
  final List<BatchValidationItem> items;

  const BatchValidationReport({
    required this.items,
  });

  bool get passed => items.every((item) => item.passed);

  int get errorCount =>
      items.fold(0, (sum, item) => sum + item.errors.length);

  int get warningCount =>
      items.fold(0, (sum, item) => sum + item.warnings.length);
}
