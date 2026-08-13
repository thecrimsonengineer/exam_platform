enum StudentTopicLearningState {
  notStarted,
  completed,
}

class StudentTopicProgress {
  final String contentId;
  final int contentVersion;
  final String subtopicId;
  final String topicId;
  final String topicTitle;
  final StudentTopicLearningState state;
  final DateTime? completedAt;

  const StudentTopicProgress({
    required this.contentId,
    required this.contentVersion,
    required this.subtopicId,
    required this.topicId,
    required this.topicTitle,
    required this.state,
    required this.completedAt,
  });

  String get storageId => '$contentId::$subtopicId::$topicId';

  StudentTopicProgress copyWith({
    String? contentId,
    int? contentVersion,
    String? subtopicId,
    String? topicId,
    String? topicTitle,
    StudentTopicLearningState? state,
    DateTime? completedAt,
  }) {
    return StudentTopicProgress(
      contentId: contentId ?? this.contentId,
      contentVersion: contentVersion ?? this.contentVersion,
      subtopicId: subtopicId ?? this.subtopicId,
      topicId: topicId ?? this.topicId,
      topicTitle: topicTitle ?? this.topicTitle,
      state: state ?? this.state,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contentId': contentId,
      'contentVersion': contentVersion,
      'subtopicId': subtopicId,
      'topicId': topicId,
      'topicTitle': topicTitle,
      'state': state.name,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory StudentTopicProgress.fromJson(Map<String, dynamic> json) {
    final stateName = json['state']?.toString() ?? 'notStarted';

    return StudentTopicProgress(
      contentId: json['contentId']?.toString() ?? '',
      contentVersion:
          int.tryParse(json['contentVersion']?.toString() ?? '') ?? 1,
      subtopicId: json['subtopicId']?.toString() ?? '',
      topicId: json['topicId']?.toString() ?? '',
      topicTitle: json['topicTitle']?.toString() ?? '',
      state: StudentTopicLearningState.values.firstWhere(
        (value) => value.name == stateName,
        orElse: () => StudentTopicLearningState.notStarted,
      ),
      completedAt: DateTime.tryParse(
        json['completedAt']?.toString() ?? '',
      ),
    );
  }
}
