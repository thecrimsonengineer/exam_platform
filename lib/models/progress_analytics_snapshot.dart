class ProgressDailyActivity {
  final String dateKey;
  final int seconds;

  const ProgressDailyActivity({required this.dateKey, required this.seconds});

  int get minutes => (seconds / 60).round();

  Map<String, dynamic> toJson() => {'dateKey': dateKey, 'seconds': seconds};

  factory ProgressDailyActivity.fromJson(Map<String, dynamic> json) {
    return ProgressDailyActivity(
      dateKey: json['dateKey']?.toString() ?? '',
      seconds: _toInt(json['seconds']),
    );
  }
}

class ProgressDomainAnalyticsSummary {
  final String domainId;
  final int domainNumber;
  final String title;
  final int completedTopics;
  final int totalTopics;
  final int completedSubtopics;
  final int totalSubtopics;
  final int answeredQuestions;
  final int correctQuestions;

  const ProgressDomainAnalyticsSummary({
    required this.domainId,
    required this.domainNumber,
    required this.title,
    required this.completedTopics,
    required this.totalTopics,
    required this.completedSubtopics,
    required this.totalSubtopics,
    required this.answeredQuestions,
    required this.correctQuestions,
  });

  double get progress =>
      totalSubtopics == 0 ? 0 : completedSubtopics / totalSubtopics;

  double get accuracy =>
      answeredQuestions == 0 ? 0 : correctQuestions / answeredQuestions;

  String get status {
    if (totalSubtopics > 0 && completedSubtopics == totalSubtopics) {
      return 'Completed';
    }
    if (completedSubtopics > 0 || answeredQuestions > 0) {
      return 'In progress';
    }
    return 'Not started';
  }

  Map<String, dynamic> toJson() => {
    'domainId': domainId,
    'domainNumber': domainNumber,
    'title': title,
    'completedTopics': completedTopics,
    'totalTopics': totalTopics,
    'completedSubtopics': completedSubtopics,
    'totalSubtopics': totalSubtopics,
    'answeredQuestions': answeredQuestions,
    'correctQuestions': correctQuestions,
  };

  factory ProgressDomainAnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return ProgressDomainAnalyticsSummary(
      domainId: json['domainId']?.toString() ?? '',
      domainNumber: _toInt(json['domainNumber']),
      title: json['title']?.toString() ?? '',
      completedTopics: _toInt(json['completedTopics']),
      totalTopics: _toInt(json['totalTopics']),
      completedSubtopics: _toInt(json['completedSubtopics']),
      totalSubtopics: _toInt(json['totalSubtopics']),
      answeredQuestions: _toInt(json['answeredQuestions']),
      correctQuestions: _toInt(json['correctQuestions']),
    );
  }
}

class ProgressAnalyticsSnapshot {
  final DateTime generatedAt;
  final int completedDomains;
  final int totalDomains;
  final int completedTopics;
  final int totalTopics;
  final int completedSubtopics;
  final int totalSubtopics;
  final int answeredQuestions;
  final int correctQuestions;
  final DateTime? latestActivity;
  final List<ProgressDailyActivity> dailyActivity;
  final List<ProgressDomainAnalyticsSummary> domains;

  const ProgressAnalyticsSnapshot({
    required this.generatedAt,
    required this.completedDomains,
    required this.totalDomains,
    required this.completedTopics,
    required this.totalTopics,
    required this.completedSubtopics,
    required this.totalSubtopics,
    required this.answeredQuestions,
    required this.correctQuestions,
    required this.latestActivity,
    required this.dailyActivity,
    required this.domains,
  });

  double get overallProgress =>
      totalSubtopics == 0 ? 0 : completedSubtopics / totalSubtopics;

  double get topicProgress =>
      totalTopics == 0 ? 0 : completedTopics / totalTopics;

  double get accuracy =>
      answeredQuestions == 0 ? 0 : correctQuestions / answeredQuestions;

  int get weeklySeconds =>
      dailyActivity.fold(0, (sum, item) => sum + item.seconds);

  int get weeklyMinutes => (weeklySeconds / 60).round();

  int get activeDays => dailyActivity.where((item) => item.seconds > 0).length;

  int get studyStreakDays {
    if (dailyActivity.isEmpty) {
      return 0;
    }

    var streak = 0;
    for (final item in dailyActivity.reversed) {
      if (item.seconds <= 0) {
        break;
      }
      streak++;
    }
    return streak;
  }

  ProgressAnalyticsSnapshot copyWith({
    DateTime? generatedAt,
    List<ProgressDailyActivity>? dailyActivity,
  }) {
    return ProgressAnalyticsSnapshot(
      generatedAt: generatedAt ?? this.generatedAt,
      completedDomains: completedDomains,
      totalDomains: totalDomains,
      completedTopics: completedTopics,
      totalTopics: totalTopics,
      completedSubtopics: completedSubtopics,
      totalSubtopics: totalSubtopics,
      answeredQuestions: answeredQuestions,
      correctQuestions: correctQuestions,
      latestActivity: latestActivity,
      dailyActivity: dailyActivity ?? this.dailyActivity,
      domains: domains,
    );
  }

  Map<String, dynamic> toJson() => {
    'generatedAt': generatedAt.toIso8601String(),
    'completedDomains': completedDomains,
    'totalDomains': totalDomains,
    'completedTopics': completedTopics,
    'totalTopics': totalTopics,
    'completedSubtopics': completedSubtopics,
    'totalSubtopics': totalSubtopics,
    'answeredQuestions': answeredQuestions,
    'correctQuestions': correctQuestions,
    'latestActivity': latestActivity?.toIso8601String(),
    'dailyActivity': dailyActivity.map((item) => item.toJson()).toList(),
    'domains': domains.map((item) => item.toJson()).toList(),
  };

  factory ProgressAnalyticsSnapshot.fromJson(Map<String, dynamic> json) {
    return ProgressAnalyticsSnapshot(
      generatedAt:
          DateTime.tryParse(json['generatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      completedDomains: _toInt(json['completedDomains']),
      totalDomains: _toInt(json['totalDomains']),
      completedTopics: _toInt(json['completedTopics']),
      totalTopics: _toInt(json['totalTopics']),
      completedSubtopics: _toInt(json['completedSubtopics']),
      totalSubtopics: _toInt(json['totalSubtopics']),
      answeredQuestions: _toInt(json['answeredQuestions']),
      correctQuestions: _toInt(json['correctQuestions']),
      latestActivity: DateTime.tryParse(
        json['latestActivity']?.toString() ?? '',
      ),
      dailyActivity: _mapList(
        json['dailyActivity'],
      ).map(ProgressDailyActivity.fromJson).toList(growable: false),
      domains: _mapList(
        json['domains'],
      ).map(ProgressDomainAnalyticsSummary.fromJson).toList(growable: false),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }

  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}
