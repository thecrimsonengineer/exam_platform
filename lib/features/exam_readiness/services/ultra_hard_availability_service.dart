import '../../../models/question.dart';
import '../../../services/quiz_service.dart';
import '../../../services/ultra_hard_question_contract.dart';

class UltraHardAvailabilityService {
  UltraHardAvailabilityService({QuizService? quizService})
    : _quizService = quizService ?? QuizService.shared;

  final QuizService _quizService;

  Future<Set<String>> loadAvailableCompetencyIds() async {
    await _quizService.initialize();
    return fromQuestions(_quizService.getAllQuestions());
  }

  static Set<String> fromQuestions(Iterable<Question> questions) {
    final counts = <String, int>{};

    for (final question in questions) {
      final competencyId = question.competencyId.trim().toLowerCase();
      final isPublished =
          question.status.trim().toLowerCase() == 'published';
      final isUltraHard = question.tags.any(
        (tag) =>
            tag.trim().toLowerCase() ==
            UltraHardQuestionContract.classificationTag,
      );

      if (!isPublished ||
          !isUltraHard ||
          !RegExp(r'^d\d{2}_c\d{2}
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
).hasMatch(competencyId)) {
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
