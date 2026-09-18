import 'package:exam_platform/features/exam_readiness/models/learner_assessment_attempt.dart';
import 'package:exam_platform/features/exam_readiness/services/learner_evidence_aggregation_service.dart';
import 'package:exam_platform/models/question.dart';

LearnerAssessmentAttempt m7bAttempt({
  String attemptId = 'a1',
  int questionId = 1,
  int domainNumber = 3,
  String competencyId = 'd03_c02',
  String topicId = 't1',
  String subtopicId = 's1',
  bool correct = true,
  DateTime? answeredAt,
  String cognitiveLevel = 'application',
  AttemptDifficultyLane difficultyLane = AttemptDifficultyLane.hard,
  bool publishedAtAttempt = true,
  int questionVersion = 1,
  String sessionKind = 'practice',
  LearnerConfidenceLevel? confidence,
}) {
  return LearnerAssessmentAttempt(
    attemptId: attemptId,
    questionId: questionId,
    domainNumber: domainNumber,
    competencyId: competencyId,
    topicId: topicId,
    subtopicId: subtopicId,
    correct: correct,
    answeredAt: answeredAt ?? DateTime(2026, 9, 18, 10),
    cognitiveLevel: cognitiveLevel,
    questionType: 'scenario_mcq',
    difficultyLane: difficultyLane,
    publishedAtAttempt: publishedAtAttempt,
    questionVersion: questionVersion,
    sessionKind: sessionKind,
    confidence: confidence,
  );
}

CompetencyEvidenceScope m7bScope({
  String competencyId = 'd03_c02',
  int topics = 4,
  int subtopics = 8,
}) {
  return CompetencyEvidenceScope(
    competencyId: competencyId,
    topicIds: {for (var i = 1; i <= topics; i++) 't$i'},
    subtopicIds: {for (var i = 1; i <= subtopics; i++) 's$i'},
  );
}

Question m7bQuestion({
  int id = 1,
  String competencyId = 'd03_c02',
  String topicId = 't1',
  String subtopicId = 's1',
  String status = 'published',
  String difficulty = 'Hard',
  String cognitiveLevel = 'application',
  List<String> tags = const ['scenario'],
}) {
  return Question(
    id: id,
    domain: 3,
    competencyId: competencyId,
    subtopicId: subtopicId,
    topicId: topicId,
    question: 'A sufficiently detailed M7B fixture question?',
    options: const ['A', 'B', 'C', 'D'],
    correctAnswer: 0,
    explanation: 'Fixture explanation.',
    reference: 'Fixture source.',
    difficulty: difficulty,
    cognitiveLevel: cognitiveLevel,
    questionType: 'scenario_mcq',
    status: status,
    version: 2,
    tags: tags,
  );
}
