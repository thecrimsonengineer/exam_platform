class BulkEditOperation {
  final List<String> contentIds;
  final String? difficulty;
  final String? cognitiveLevel;
  final List<String>? tags;

  const BulkEditOperation({
    required this.contentIds,
    this.difficulty,
    this.cognitiveLevel,
    this.tags,
  });
}
