class QuestionEntryDraft {
  final String stem;
  final List<String> options;
  final String bestAnswer;
  final String explanation;
  final String? reference;
  final List<String> tags;
  final String? difficulty;
  final String? cognitiveLevel;

  const QuestionEntryDraft({
    required this.stem,
    required this.options,
    required this.bestAnswer,
    required this.explanation,
    this.reference,
    this.tags = const [],
    this.difficulty,
    this.cognitiveLevel,
  });

  bool get hasExactlyFourOptions => options.length == 4;
}
