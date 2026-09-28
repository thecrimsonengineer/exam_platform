import 'study_plan_block.dart';

enum StudyPlanExecutionTargetKind {
  studyContent,
  practiceSession,
  review,
  flashcardReview,
  examSimulation,
}

class StudyPlanExecutionTarget {
  const StudyPlanExecutionTarget({
    required this.kind,
    required this.blockId,
    required this.blockType,
    required this.domainId,
    required this.domainNumber,
    required this.domainTitle,
    required this.competencyId,
    required this.competencyTitle,
    required this.plannedMinutes,
    required this.questionCount,
    this.topicId,
    this.subtopicId,
    this.cardIds = const <String>[],
    this.dueOnly = false,
    this.weakOnly = false,
    this.sourceEvidenceIds = const <String>[],
    this.targetCardCount,
    this.reviewReason,
  });

  final StudyPlanExecutionTargetKind kind;
  final String blockId;
  final StudyPlanBlockType blockType;
  final String domainId;
  final int domainNumber;
  final String domainTitle;
  final String competencyId;
  final String competencyTitle;
  final int plannedMinutes;
  final int questionCount;
  final String? topicId;
  final String? subtopicId;

  /// Optional explicit card scope for a targeted Flashcard review.
  final List<String> cardIds;

  /// Requests cards currently due for spaced review when runtime SRS state is available.
  final bool dueOnly;

  /// Requests weak-card filtering when learner retention state is available.
  final bool weakOnly;

  /// Evidence identifiers that caused this review assignment, when available.
  final List<String> sourceEvidenceIds;

  /// Optional target number of cards. Null lets the Flashcards runtime choose safely.
  final int? targetCardCount;

  /// Human-readable reason for the targeted review assignment.
  final String? reviewReason;

  List<String> get competencyIds => <String>[competencyId];

  int get targetMinutes => plannedMinutes;
}
