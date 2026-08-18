import '../../models/question.dart';
import '../../models/studio_question_context.dart';
import '../../models/study_content.dart';
import '../question_bank_service.dart';
import '../question_quality_validator.dart';

/// Studio-facing boundary for managed CSP11 question operations.
///
/// The Studio owns the authoring workflow, while persistence remains
/// centralized in QuestionBankService and LocalQuestionRepository.
class StudioQuestionService {
  StudioQuestionService({
    QuestionBankService? questionBankService,
  }) : _questionBankService = questionBankService ?? QuestionBankService();

  final QuestionBankService _questionBankService;

  Future<void> initialize() => _questionBankService.initialize();

  List<Question> allManagedQuestions() =>
      _questionBankService.allManagedQuestions();

  List<Question> questionsForQuizId(String quizId) =>
      _questionBankService.byQuizId(quizId);

  List<Question> questionsForContext(
    StudioQuestionContext context, {
    String? quizIdOverride,
  }) {
    final quizId = (quizIdOverride ?? context.quizId).trim();
    // The quiz ID is already the primary managed-question scope. Keep the
    // subtopic check as a safety guard, but do not add stricter package-field
    // filtering here because existing imported questions may predate the
    // current contentPackageId metadata. This preserves the current Studio
    // visibility behaviour while the service boundary is introduced.
    final questions = questionsForQuizId(quizId)
        .where((question) => question.subtopicId == context.subtopicId)
        .toList();

    questions.sort((a, b) => a.id.compareTo(b.id));
    return questions;
  }

  StudioQuestionContext contextFor({
    required StudyContent content,
    required StudySubtopic subtopic,
    String topicId = '',
  }) {
    return StudioQuestionContext.fromContent(
      content: content,
      subtopic: subtopic,
      topicId: topicId,
    );
  }

  /// Resolves the quiz identity for a Studio subtopic.
  ///
  /// Existing linked IDs and already-managed question IDs are preserved for
  /// compatibility. If neither exists, the deterministic Studio context ID
  /// is used. This keeps ID resolution in the service boundary instead of
  /// duplicating it in individual Studio widgets.
  String resolveQuizId({
    required StudyContent content,
    required StudySubtopic subtopic,
    String? preferredQuizId,
  }) {
    final linkedQuizId = subtopic.quizzes
        .map((quiz) => quiz.quizId.trim())
        .firstWhere((quizId) => quizId.isNotEmpty, orElse: () => '');

    if (linkedQuizId.isNotEmpty) {
      return linkedQuizId;
    }

    final preferred = preferredQuizId?.trim() ?? '';
    if (preferred.isNotEmpty &&
        questionsForQuizId(preferred).any(
          (question) => question.subtopicId == subtopic.id,
        )) {
      return preferred;
    }

    final candidates = allManagedQuestions()
        .where(
          (question) =>
              question.subtopicId == subtopic.id &&
              question.status.toLowerCase() == 'published',
        )
        .toList();

    final counts = <String, int>{};
    for (final question in candidates) {
      final candidateQuizId = question.quizId.trim();
      if (candidateQuizId.isNotEmpty) {
        counts[candidateQuizId] = (counts[candidateQuizId] ?? 0) + 1;
      }
    }

    if (counts.isNotEmpty) {
      final sortedQuizIds = counts.entries.toList()
        ..sort((a, b) {
          final countComparison = b.value.compareTo(a.value);
          if (countComparison != 0) {
            return countComparison;
          }
          return a.key.compareTo(b.key);
        });
      return sortedQuizIds.first.key;
    }

    return StudioQuestionContext.canonicalQuizId(content.id, subtopic.id);
  }

  List<QuestionQualityIssue> validate(Question question) =>
      _questionBankService.validate(question);

  Future<List<QuestionQualityIssue>> saveDraft(Question question) =>
      _questionBankService.saveDraft(question);

  Future<void> publish(Question question) =>
      _questionBankService.publish(question);

  Future<void> delete(int questionId) =>
      _questionBankService.delete(questionId);

  int nextQuestionId() => _questionBankService.nextQuestionId();

  Question randomizeOptions(Question question) =>
      _questionBankService.randomizeOptions(question);

  bool get answerLengthCheckEnabled =>
      _questionBankService.answerLengthCheckEnabled;

  set answerLengthCheckEnabled(bool enabled) {
    _questionBankService.answerLengthCheckEnabled = enabled;
  }
}
