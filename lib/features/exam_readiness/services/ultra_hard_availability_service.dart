import '../../../models/question.dart';
import '../../../services/quiz_service.dart';
import '../../../services/ultra_hard_question_contract.dart';

class UltraHardAvailabilityService {
  UltraHardAvailabilityService({QuizService? quizService})
    : _quizService = quizService ?? QuizService.shared;

  final QuizService _quizService;

  Future<Set<String>> loadAvailableCompetencyIds() async {
    // The learner may publish new DQG300 questions after the shared quiz
    // catalogue was first initialized. Ultra Hard availability must use the
    // current published cloud catalogue rather than a stale in-memory copy.
    await _quizService.refresh();
    return fromQuestions(_quizService.getAllQuestions());
  }

  static Set<String> fromQuestions(Iterable<Question> questions) {
    final counts = <String, int>{};

    for (final question in questions) {
      final competencyId = question.competencyId.trim().toLowerCase();
      final isPublished = question.status.trim().toLowerCase() == 'published';
      final isUltraHard = question.tags.any(
        (tag) =>
            tag.trim().toLowerCase() ==
            UltraHardQuestionContract.classificationTag,
      );
      final isCanonicalCompetency = RegExp(
        r'^d\d{2}_c\d{2}$',
      ).hasMatch(competencyId);

      if (!isPublished || !isUltraHard || !isCanonicalCompetency) {
        continue;
      }

      counts[competencyId] = (counts[competencyId] ?? 0) + 1;
    }

    return counts.entries
        .where((entry) => entry.value >= 5)
        .map((entry) => entry.key)
        .toSet();
  }
}
