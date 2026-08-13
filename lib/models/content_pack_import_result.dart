class ContentPackImportResult {
  final bool ready;
  final String packId;
  final List<String> errors;
  final List<String> warnings;

  const ContentPackImportResult({
    required this.ready,
    required this.packId,
    required this.errors,
    required this.warnings,
  });
}
