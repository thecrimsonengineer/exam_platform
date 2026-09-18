enum LearningTwinPracticeMode {
  dailyChallenge,
  randomQuiz,
  weakAreas,
  customQuiz,
  ultraHardExamReadiness,
}

/// Sanitized pre-practice contract for the Learning Twin.
///
/// This object deliberately carries only session metadata. It must never
/// contain Question objects, question text, answer options, correct answers,
/// explanations, references, or other protected question-bank payloads.
final class LearningTwinPracticeContext {
  const LearningTwinPracticeContext({
    required this.mode,
    required this.questionCount,
    this.domainNumber,
    this.competencyId,
    this.subtopicId,
    this.usedFallback = false,
  }) : assert(questionCount > 0),
       assert(domainNumber == null || domainNumber > 0);

  final LearningTwinPracticeMode mode;
  final int questionCount;
  final int? domainNumber;
  final String? competencyId;
  final String? subtopicId;
  final bool usedFallback;

  String? get domainId {
    final value = domainNumber;
    if (value == null) {
      return null;
    }

    return 'd${value.toString().padLeft(2, '0')}';
  }

  bool get hasFocusedWeakArea =>
      mode == LearningTwinPracticeMode.weakAreas &&
      !usedFallback &&
      domainNumber != null;
}
