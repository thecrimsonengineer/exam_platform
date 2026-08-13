
class StudentDomainProgress {
  final String domainId;
  final int domainNumber;
  final String title;
  final int competencyCount;
  final int subtopicCount;
  final int completedSubtopics;
  final int topicCount;
  final int completedTopics;

  const StudentDomainProgress({
    required this.domainId,
    required this.domainNumber,
    required this.title,
    required this.competencyCount,
    required this.subtopicCount,
    required this.completedSubtopics,
    required this.topicCount,
    required this.completedTopics,
  });

  double get subtopicProgress =>
      subtopicCount == 0 ? 0 : completedSubtopics / subtopicCount;

  double get topicProgress =>
      topicCount == 0 ? 0 : completedTopics / topicCount;

  bool get completed =>
      subtopicCount > 0 && completedSubtopics == subtopicCount;

  bool get inProgress =>
      completedSubtopics > 0 && !completed;

  StudentDomainProgress copyWith({
    int? competencyCount,
    int? subtopicCount,
    int? completedSubtopics,
    int? topicCount,
    int? completedTopics,
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

  int get totalTopics =>
      domains.fold(0, (sum, item) => sum + item.topicCount);

  int get completedTopics =>
      domains.fold(0, (sum, item) => sum + item.completedTopics);

  double get overallProgress =>
      totalSubtopics == 0 ? 0 : completedSubtopics / totalSubtopics;

  double get topicProgress =>
      totalTopics == 0 ? 0 : completedTopics / totalTopics;

  int get completedDomains =>
      domains.where((domain) => domain.completed).length;

  int get inProgressDomains =>
      domains.where((domain) => domain.inProgress).length;

  int get notStartedDomains =>
      domains.where(
        (domain) =>
            domain.completedSubtopics == 0 &&
            domain.subtopicCount > 0,
      ).length;

  StudentDomainProgress? get nextDomain =>
      domains.cast<StudentDomainProgress?>().firstWhere(
            (domain) =>
                domain != null &&
                !domain.completed &&
                domain.subtopicCount > 0,
            orElse: () => null,
          );
}
