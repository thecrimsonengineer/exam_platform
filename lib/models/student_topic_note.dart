class StudentTopicNote {
  final String contentId;
  final String subtopicId;
  final String topicId;
  final String topicTitle;
  final String note;
  final DateTime updatedAt;

  const StudentTopicNote({
    required this.contentId,
    required this.subtopicId,
    required this.topicId,
    required this.topicTitle,
    required this.note,
    required this.updatedAt,
  });

  String get storageId => '$contentId::$subtopicId::$topicId';

  Map<String, dynamic> toJson() => {
        'contentId': contentId,
        'subtopicId': subtopicId,
        'topicId': topicId,
        'topicTitle': topicTitle,
        'note': note,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory StudentTopicNote.fromJson(Map<String, dynamic> json) {
    return StudentTopicNote(
      contentId: json['contentId']?.toString() ?? '',
      subtopicId: json['subtopicId']?.toString() ?? '',
      topicId: json['topicId']?.toString() ?? '',
      topicTitle: json['topicTitle']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      updatedAt: DateTime.tryParse(
            json['updatedAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }
}
