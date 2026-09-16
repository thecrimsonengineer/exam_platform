import 'learning_twin_practice_context.dart';

/// Sanitized practice-result contract for the Learning Twin.
///
/// It intentionally contains only aggregate session metadata. Protected
/// question-bank payloads stay in the quiz/result UI layer.
final class LearningTwinPracticeResultContext {
  const LearningTwinPracticeResultContext({
    required this.practiceContext,
    required this.score,
    required this.totalQuestions,
  }) : assert(score >= 0),
       assert(totalQuestions >= 0),
       assert(score <= totalQuestions);

  final LearningTwinPracticeContext practiceContext;
  final int score;
  final int totalQuestions;

  int get incorrectCount => totalQuestions - score;

  double get accuracy => totalQuestions == 0 ? 0.0 : score / totalQuestions;

  int get accuracyPercent => (accuracy * 100).round();

  bool get isPerfect => totalQuestions > 0 && score == totalQuestions;
}
