class QuestionConceptMapping {
  const QuestionConceptMapping({
    required this.questionId,
    required this.conceptId,
  });

  final int questionId;
  final String conceptId;

  factory QuestionConceptMapping.fromJson(Map<String, dynamic> json) {
    return QuestionConceptMapping(
      questionId: _toInt(json['questionId']),
      conceptId: json['conceptId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'questionId': questionId, 'conceptId': conceptId};
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
