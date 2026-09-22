import 'study_plan_block.dart';

enum StudyPlanExecutionTargetKind {
  studyContent,
  practiceSession,
  review,
  examSimulation,
}

class StudyPlanExecutionTarget {
  const StudyPlanExecutionTarget({
    required this.kind,
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
  });

  final StudyPlanExecutionTargetKind kind;
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
}
