enum StudentResumeDecisionType {
  noPosition,
  continueInProgress,
  reviewCompleted,
  continueFromNextSubtopic,
}

class StudentResumeDecision {
  final StudentResumeDecisionType type;
  final String? domainId;
  final int? domainNumber;
  final String? domainTitle;
  final String? competencyId;
  final String? competencyTitle;
  final String? subtopicId;
  final String? subtopicTitle;
  final String? nextSubtopicId;
  final String? nextSubtopicTitle;

  const StudentResumeDecision({
    required this.type,
    this.domainId,
    this.domainNumber,
    this.domainTitle,
    this.competencyId,
    this.competencyTitle,
    this.subtopicId,
    this.subtopicTitle,
    this.nextSubtopicId,
    this.nextSubtopicTitle,
  });

  bool get hasPosition => domainId != null;

  String get actionLabel {
    switch (type) {
      case StudentResumeDecisionType.noPosition:
        return 'START CSP11';
      case StudentResumeDecisionType.continueInProgress:
        return 'CONTINUE LEARNING';
      case StudentResumeDecisionType.reviewCompleted:
        return 'REVIEW SUBTOPIC';
      case StudentResumeDecisionType.continueFromNextSubtopic:
        return 'CONTINUE TO NEXT';
    }
  }
}
