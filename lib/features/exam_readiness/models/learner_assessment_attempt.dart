import '../../../models/question.dart';
import '../../../services/ultra_hard_question_contract.dart';

enum LearnerConfidenceLevel { low, medium, high }

enum AttemptDifficultyLane { standard, hard, ultraHard }

class LearnerAssessmentAttempt {
  const LearnerAssessmentAttempt({
    required this.attemptId,
    required this.questionId,
    required this.domainNumber,
    required this.competencyId,
    required this.topicId,
    required this.subtopicId,
    required this.correct,
    required this.answeredAt,
    required this.cognitiveLevel,
    required this.questionType,
    required this.difficultyLane,
    required this.publishedAtAttempt,
    required this.questionVersion,
    required this.sessionKind,
    this.confidence,
  });

  final String attemptId;
  final int questionId;
  final int domainNumber;
  final String competencyId;
  final String topicId;
  final String subtopicId;
  final bool correct;
  final DateTime answeredAt;
  final String cognitiveLevel;
  final String questionType;
  final AttemptDifficultyLane difficultyLane;
  final bool publishedAtAttempt;
  final int questionVersion;
  final String sessionKind;
  final LearnerConfidenceLevel? confidence;

  factory LearnerAssessmentAttempt.fromQuestion({
    required Question question,
    required bool correct,
    required DateTime answeredAt,
    String? attemptId,
    String sessionKind = 'practice',
    LearnerConfidenceLevel? confidence,
  }) {
    final normalizedTags = question.tags
        .map((tag) => tag.trim().toLowerCase())
        .toSet();

    final lane =
        normalizedTags.contains(UltraHardQuestionContract.classificationTag)
        ? AttemptDifficultyLane.ultraHard
        : question.difficulty.trim().toLowerCase().contains('hard')
        ? AttemptDifficultyLane.hard
        : AttemptDifficultyLane.standard;

    final generatedId = attemptId?.trim().isNotEmpty == true
        ? attemptId!.trim()
        : '${question.id}-${answeredAt.microsecondsSinceEpoch}';

    return LearnerAssessmentAttempt(
      attemptId: generatedId,
      questionId: question.id,
      domainNumber: question.domain,
      competencyId: question.competencyId.trim().toLowerCase(),
      topicId: question.topicId.trim(),
      subtopicId: question.subtopicId.trim(),
      correct: correct,
      answeredAt: answeredAt,
      cognitiveLevel: question.cognitiveLevel.trim().toLowerCase(),
      questionType: question.questionType.trim().toLowerCase(),
      difficultyLane: lane,
      publishedAtAttempt: question.status.trim().toLowerCase() == 'published',
      questionVersion: question.version,
      sessionKind: sessionKind.trim().isEmpty ? 'practice' : sessionKind.trim(),
      confidence: confidence,
    );
  }

  bool get hasCanonicalCompetencyId =>
      RegExp(r'^d\d{2}_c\d{2}$').hasMatch(competencyId);

  Map<String, dynamic> toJson() {
    return {
      'attemptId': attemptId,
      'questionId': questionId,
      'domainNumber': domainNumber,
      'competencyId': competencyId,
      'topicId': topicId,
      'subtopicId': subtopicId,
      'correct': correct,
      'answeredAt': answeredAt.toIso8601String(),
      'cognitiveLevel': cognitiveLevel,
      'questionType': questionType,
      'difficultyLane': difficultyLane.name,
      'publishedAtAttempt': publishedAtAttempt,
      'questionVersion': questionVersion,
      'sessionKind': sessionKind,
      'confidence': confidence?.name,
    };
  }

  factory LearnerAssessmentAttempt.fromJson(Map<String, dynamic> json) {
    final answeredAt = DateTime.tryParse(json['answeredAt']?.toString() ?? '');
    if (answeredAt == null) {
      throw const FormatException('Invalid assessment-attempt timestamp.');
    }

    return LearnerAssessmentAttempt(
      attemptId: json['attemptId']?.toString() ?? '',
      questionId: _toInt(json['questionId']),
      domainNumber: _toInt(json['domainNumber']),
      competencyId: json['competencyId']?.toString() ?? '',
      topicId: json['topicId']?.toString() ?? '',
      subtopicId: json['subtopicId']?.toString() ?? '',
      correct: json['correct'] == true,
      answeredAt: answeredAt,
      cognitiveLevel: json['cognitiveLevel']?.toString() ?? '',
      questionType: json['questionType']?.toString() ?? '',
      difficultyLane: _difficultyLane(json['difficultyLane']),
      publishedAtAttempt: json['publishedAtAttempt'] == true,
      questionVersion: _toInt(json['questionVersion'], fallback: 1),
      sessionKind: json['sessionKind']?.toString() ?? 'practice',
      confidence: _confidence(json['confidence']),
    );
  }
}

AttemptDifficultyLane _difficultyLane(dynamic value) {
  final name = value?.toString();
  for (final item in AttemptDifficultyLane.values) {
    if (item.name == name) return item;
  }
  return AttemptDifficultyLane.standard;
}

LearnerConfidenceLevel? _confidence(dynamic value) {
  final name = value?.toString();
  for (final item in LearnerConfidenceLevel.values) {
    if (item.name == name) return item;
  }
  return null;
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
