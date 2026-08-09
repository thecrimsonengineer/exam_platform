import '../models/question.dart';

class QuizDefinition {
  final String id;
  final String title;
  final List<int> questionIds;

  const QuizDefinition({
    required this.id,
    required this.title,
    required this.questionIds,
  });
}

// ==========================================================
// CENTRAL QUIZ CATALOG
// ==========================================================

const List<QuizDefinition> quizCatalog = [
  // ========================================================
  // DOMAIN 7
  // TRAINING
  // NEEDS ASSESSMENT
  // ========================================================

  QuizDefinition(
    id: 'd07_topic_001_quiz',
    title: 'Training Needs Assessment - Topic 1',
    questionIds: [
      1,
    ],
  ),

  QuizDefinition(
    id: 'd07_topic_002_quiz',
    title: 'Training Needs Assessment - Topic 2',
    questionIds: [
      2,
    ],
  ),

  QuizDefinition(
    id: 'd07_topic_003_quiz',
    title: 'Training Needs Assessment - Topic 3',
    questionIds: [
      3,
    ],
  ),

  QuizDefinition(
    id: 'd07_topic_004_quiz',
    title: 'Training Needs Assessment - Topic 4',
    questionIds: [
      4,
    ],
  ),

  QuizDefinition(
    id: 'd07_topic_005_quiz',
    title: 'Training Needs Assessment - Topic 5',
    questionIds: [
      5,
    ],
  ),
];

class QuizCatalog {
  // ========================================================
  // ALL QUIZZES
  // ========================================================

  /// Returns all quiz definitions.
  List<QuizDefinition> getAllQuizzes() {
    return List<QuizDefinition>.from(
      quizCatalog,
    );
  }

  // ========================================================
  // FIND QUIZ
  // ========================================================

  /// Finds a quiz by its unique quiz ID.
  QuizDefinition? getQuizById(
    String quizId,
  ) {
    for (final quiz in quizCatalog) {
      if (quiz.id == quizId) {
        return quiz;
      }
    }

    return null;
  }

  // ========================================================
  // QUESTIONS BY QUIZ
  // ========================================================

  /// Returns the actual Question objects belonging
  /// to a quiz.
  ///
  /// Questions are retrieved from the central
  /// question bank using their IDs.
  List<Question> getQuestionsByQuizId(
    String quizId,
    List<Question> questionBank,
  ) {
    final quiz = getQuizById(quizId);

    if (quiz == null) {
      return <Question>[];
    }

    final Map<int, Question> questionMap = {
      for (final question in questionBank)
        question.id: question,
    };

    return quiz.questionIds
        .map(
          (id) => questionMap[id],
        )
        .whereType<Question>()
        .toList();
  }

  // ========================================================
  // QUESTION COUNT
  // ========================================================

  /// Returns the number of questions assigned
  /// to a quiz.
  int getQuestionCount(
    String quizId,
  ) {
    final quiz = getQuizById(quizId);

    return quiz?.questionIds.length ?? 0;
  }

  // ========================================================
  // QUIZ EXISTS
  // ========================================================

  /// Checks whether a quiz exists.
  bool hasQuiz(
    String quizId,
  ) {
    return getQuizById(quizId) != null;
  }
}