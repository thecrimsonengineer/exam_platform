class FlashcardPlacement {
  const FlashcardPlacement({
    required this.domainId,
    required this.competencyId,
    this.topicId = '',
    this.subtopicId = '',
  });

  final String domainId;
  final String competencyId;
  final String topicId;
  final String subtopicId;

  factory FlashcardPlacement.fromJson(Map<String, dynamic> json) {
    return FlashcardPlacement(
      domainId: json['domainId']?.toString() ?? '',
      competencyId: json['competencyId']?.toString() ?? '',
      topicId: json['topicId']?.toString() ?? '',
      subtopicId: json['subtopicId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'domainId': domainId,
      'competencyId': competencyId,
      if (topicId.isNotEmpty) 'topicId': topicId,
      if (subtopicId.isNotEmpty) 'subtopicId': subtopicId,
    };
  }
}
