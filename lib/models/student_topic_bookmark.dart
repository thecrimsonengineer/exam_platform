class StudentTopicBookmark {
  final String contentId;
  final String subtopicId;
  final String topicId;
  final String topicTitle;
  final DateTime savedAt;

  const StudentTopicBookmark({
    required this.contentId,
    required this.subtopicId,
    required this.topicId,
    required this.topicTitle,
    required this.savedAt,
  });

  String get storageId => '$contentId::$subtopicId::$topicId';

  Map<String, dynamic> toJson() => {
        'contentId': contentId,
        'subtopicId': subtopicId,
        'topicId': topicId,
        'topicTitle': topicTitle,
        'savedAt': savedAt.toIso8601String(),
      };

  factory StudentTopicBookmark.fromJson(Map<String, dynamic> json) {
    return StudentTopicBookmark(
      contentId: json['contentId']?.toString() ?? '',
      subtopicId: json['subtopicId']?.toString() ?? '',
      topicId: json['topicId']?.toString() ?? '',
      topicTitle: json['topicTitle']?.toString() ?? '',
      savedAt: DateTime.tryParse(
            json['savedAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }
}
