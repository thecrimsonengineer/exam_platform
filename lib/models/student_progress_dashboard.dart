class StudentSubtopicProgressDetail {
  final String subtopicId;
  final String title;
  final bool completed;
  final bool inProgress;
  final int answeredQuestions;
  final int correctQuestions;

  const StudentSubtopicProgressDetail({
    required this.subtopicId,
    required this.title,
    required this.completed,
    required this.inProgress,
    this.answeredQuestions = 0,
    this.correctQuestions = 0,
  });
}

class StudentTopicProgressDetail {
  final String topicId;
  final String title;
  final int subtopicCount;
  final int completedSubtopics;
  final int answeredQuestions;
  final int correctQuestions;
  final List<StudentSubtopicProgressDetail> subtopics;

  const StudentTopicProgressDetail({
    required this.topicId,
    required this.title,
    required this.subtopicCount,
    required this.completedSubtopics,
    this.answeredQuestions = 0,
    this.correctQuestions = 0,
    this.subtopics = const [],
  });

  bool get completed =>
      subtopicCount > 0 && completedSubtopics == subtopicCount;

  bool get inProgress => completedSubtopics > 0 && !completed;

  double get progress =>
      subtopicCount == 0 ? 0 : completedSubtopics / subtopicCount;
}

class StudentCompetencyProgressDetail {
  final String competencyId;
  final int competencyNumber;
  final String title;
  final int topicCount;
  final int completedTopics;
  final int subtopicCount;
  final int completedSubtopics;
  final int answeredQuestions;
  final int correctQuestions;
  final List<StudentTopicProgressDetail> topics;

  const StudentCompetencyProgressDetail({
    required this.competencyId,
    required this.competencyNumber,
    required this.title,
    required this.topicCount,
    required this.completedTopics,
    required this.subtopicCount,
    required this.completedSubtopics,
    this.answeredQuestions = 0,
    this.correctQuestions = 0,
    this.topics = const [],
  });

  double get subtopicProgress =>
      subtopicCount == 0 ? 0 : completedSubtopics / subtopicCount;
}

class StudentDomainProgress {
  final String domainId;
  final int domainNumber;
  final String title;
  final int competencyCount;
  final int subtopicCount;
  final int completedSubtopics;
  final int topicCount;
  final int completedTopics;
  final int answeredQuestions;
  final int correctQuestions;
  final List<StudentCompetencyProgressDetail> competencies;

  const StudentDomainProgress({
    required this.domainId,
    required this.domainNumber,
    required this.title,
    required this.competencyCount,
    required this.subtopicCount,
    required this.completedSubtopics,
    required this.topicCount,
    required this.completedTopics,
    this.answeredQuestions = 0,
    this.correctQuestions = 0,
    this.competencies = const [],
  });

  double get subtopicProgress =>
      subtopicCount == 0 ? 0 : completedSubtopics / subtopicCount;

  double get topicProgress =>
      topicCount == 0 ? 0 : completedTopics / topicCount;

  bool get completed =>
      subtopicCount > 0 && completedSubtopics == subtopicCount;

  bool get inProgress => completedSubtopics > 0 && !completed;

  StudentDomainProgress copyWith({
    int? competencyCount,
    int? subtopicCount,
    int? completedSubtopics,
    int? topicCount,
    int? completedTopics,
    int? answeredQuestions,
    int? correctQuestions,
    List<StudentCompetencyProgressDetail>? competencies,
  }) {
    return StudentDomainProgress(
      domainId: domainId,
      domainNumber: domainNumber,
      title: title,
      competencyCount: competencyCount ?? this.competencyCount,
      subtopicCount: subtopicCount ?? this.subtopicCount,
      completedSubtopics: completedSubtopics ?? this.completedSubtopics,
      topicCount: topicCount ?? this.topicCount,
      completedTopics: completedTopics ?? this.completedTopics,
      answeredQuestions: answeredQuestions ?? this.answeredQuestions,
      correctQuestions: correctQuestions ?? this.correctQuestions,
      competencies: competencies ?? this.competencies,
    );
  }
}

class StudentProgressDashboard {
  final List<StudentDomainProgress> domains;
  final DateTime? latestActivity;

  const StudentProgressDashboard({
    required this.domains,
    required this.latestActivity,
  });

  int get totalSubtopics =>
      domains.fold(0, (sum, item) => sum + item.subtopicCount);

  int get completedSubtopics =>
      domains.fold(0, (sum, item) => sum + item.completedSubtopics);

  int get totalTopics => domains.fold(0, (sum, item) => sum + item.topicCount);

  int get completedTopics =>
      domains.fold(0, (sum, item) => sum + item.completedTopics);

  int get answeredQuestions =>
      domains.fold(0, (sum, item) => sum + item.answeredQuestions);

  int get correctQuestions =>
      domains.fold(0, (sum, item) => sum + item.correctQuestions);

  double get overallProgress =>
      totalSubtopics == 0 ? 0 : completedSubtopics / totalSubtopics;

  double get topicProgress =>
      totalTopics == 0 ? 0 : completedTopics / totalTopics;

  int get completedDomains =>
      domains.where((domain) => domain.completed).length;

  int get inProgressDomains =>
      domains.where((domain) => domain.inProgress).length;

  int get notStartedDomains => domains
      .where(
        (domain) => domain.completedSubtopics == 0 && domain.subtopicCount > 0,
      )
      .length;

  StudentDomainProgress? get nextDomain =>
      domains.cast<StudentDomainProgress?>().firstWhere(
        (domain) =>
            domain != null && !domain.completed && domain.subtopicCount > 0,
        orElse: () => null,
      );
}
