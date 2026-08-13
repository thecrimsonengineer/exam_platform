import 'dart:convert';

/// Learner state for a persisted CSP11 learning item.
enum StudentLearningState {
  notStarted,
  inProgress,
  completed,
}

extension StudentLearningStateX on StudentLearningState {
  String get value {
    switch (this) {
      case StudentLearningState.notStarted:
        return 'not_started';
      case StudentLearningState.inProgress:
        return 'in_progress';
      case StudentLearningState.completed:
        return 'completed';
    }
  }

  String get label {
    switch (this) {
      case StudentLearningState.notStarted:
        return 'Not Started';
      case StudentLearningState.inProgress:
        return 'In Progress';
      case StudentLearningState.completed:
        return 'Completed';
    }
  }

  static StudentLearningState fromValue(String? value) {
    switch (value) {
      case 'in_progress':
        return StudentLearningState.inProgress;
      case 'completed':
        return StudentLearningState.completed;
      case 'not_started':
      default:
        return StudentLearningState.notStarted;
    }
  }
}

/// Persisted progress for one real CSP11 subtopic.
///
/// The record is keyed by the subtopic ID in the repository. The study
/// content ID and version are also stored so a future content-version change
/// can be handled without treating old progress as the new version's progress.
class StudentSubtopicProgress {
  final String domainId;
  final int domainNumber;
  final String domainTitle;
  final String competencyId;
  final String competencyTitle;
  final String subtopicId;
  final String subtopicTitle;
  final String studyContentId;
  final int studyContentVersion;
  final StudentLearningState state;
  final DateTime lastOpenedAt;
  final DateTime? completedAt;

  const StudentSubtopicProgress({
    required this.domainId,
    required this.domainNumber,
    required this.domainTitle,
    required this.competencyId,
    required this.competencyTitle,
    required this.subtopicId,
    required this.subtopicTitle,
    required this.studyContentId,
    required this.studyContentVersion,
    required this.state,
    required this.lastOpenedAt,
    required this.completedAt,
  });

  StudentSubtopicProgress copyWith({
    String? domainId,
    int? domainNumber,
    String? domainTitle,
    String? competencyId,
    String? competencyTitle,
    String? subtopicId,
    String? subtopicTitle,
    String? studyContentId,
    int? studyContentVersion,
    StudentLearningState? state,
    DateTime? lastOpenedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return StudentSubtopicProgress(
      domainId: domainId ?? this.domainId,
      domainNumber: domainNumber ?? this.domainNumber,
      domainTitle: domainTitle ?? this.domainTitle,
      competencyId: competencyId ?? this.competencyId,
      competencyTitle: competencyTitle ?? this.competencyTitle,
      subtopicId: subtopicId ?? this.subtopicId,
      subtopicTitle: subtopicTitle ?? this.subtopicTitle,
      studyContentId: studyContentId ?? this.studyContentId,
      studyContentVersion: studyContentVersion ?? this.studyContentVersion,
      state: state ?? this.state,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'domainId': domainId,
      'domainNumber': domainNumber,
      'domainTitle': domainTitle,
      'competencyId': competencyId,
      'competencyTitle': competencyTitle,
      'subtopicId': subtopicId,
      'subtopicTitle': subtopicTitle,
      'studyContentId': studyContentId,
      'studyContentVersion': studyContentVersion,
      'state': state.value,
      'lastOpenedAt': lastOpenedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory StudentSubtopicProgress.fromJson(Map<String, dynamic> json) {
    final lastOpenedAt = DateTime.tryParse(
      json['lastOpenedAt']?.toString() ?? '',
    );

    if (lastOpenedAt == null) {
      throw const FormatException('Invalid subtopic progress timestamp.');
    }

    final completedAt = DateTime.tryParse(
      json['completedAt']?.toString() ?? '',
    );

    return StudentSubtopicProgress(
      domainId: json['domainId']?.toString() ?? '',
      domainNumber: _toInt(json['domainNumber']),
      domainTitle: json['domainTitle']?.toString() ?? '',
      competencyId: json['competencyId']?.toString() ?? '',
      competencyTitle: json['competencyTitle']?.toString() ?? '',
      subtopicId: json['subtopicId']?.toString() ?? '',
      subtopicTitle: json['subtopicTitle']?.toString() ?? '',
      studyContentId: json['studyContentId']?.toString() ?? '',
      studyContentVersion: _toInt(json['studyContentVersion'], defaultValue: 1),
      state: StudentLearningStateX.fromValue(json['state']?.toString()),
      lastOpenedAt: lastOpenedAt,
      completedAt: completedAt,
    );
  }

  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? defaultValue;
  }
}

/// Lightweight aggregate information used later by domain, competency,
/// and Progress dashboard screens.
class StudentProgressSummary {
  final int total;
  final int completed;
  final int inProgress;
  final int notStarted;

  const StudentProgressSummary({
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.notStarted,
  });

  double get completionRatio {
    if (total <= 0) {
      return 0;
    }

    return completed / total;
  }

  double get activityRatio {
    if (total <= 0) {
      return 0;
    }

    return (completed + inProgress) / total;
  }

  static StudentProgressSummary fromStates(
    Iterable<StudentLearningState> states,
  ) {
    var completed = 0;
    var inProgress = 0;
    var notStarted = 0;

    for (final state in states) {
      switch (state) {
        case StudentLearningState.completed:
          completed++;
        case StudentLearningState.inProgress:
          inProgress++;
        case StudentLearningState.notStarted:
          notStarted++;
      }
    }

    return StudentProgressSummary(
      total: completed + inProgress + notStarted,
      completed: completed,
      inProgress: inProgress,
      notStarted: notStarted,
    );
  }
}

/// JSON utility kept here so the persisted contract stays explicit.
String encodeStudentProgressMap(
  Map<String, StudentSubtopicProgress> progress,
) {
  return jsonEncode(
    progress.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
  );
}
