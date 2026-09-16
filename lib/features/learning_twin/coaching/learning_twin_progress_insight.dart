enum LearningTwinProgressInsightType {
  startLearning,
  continueLearning,
  addPractice,
  weakDomainRemediation,
  masteryAcknowledgement,
}

final class LearningTwinProgressInsight {
  const LearningTwinProgressInsight({
    required this.type,
    required this.priority,
    required this.title,
    required this.body,
    this.domainId,
    this.domainNumber,
  }) : assert(priority >= 0),
       assert(title != ''),
       assert(body != '');

  final LearningTwinProgressInsightType type;
  final int priority;
  final String title;
  final String body;
  final String? domainId;
  final int? domainNumber;
}
