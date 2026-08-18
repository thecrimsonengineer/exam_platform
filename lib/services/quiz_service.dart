import 'dart:math';

import '../models/question.dart';
import 'local_question_repository.dart';

/// Central quiz service for the CSP11 application.
///
/// The managed LocalQuestionRepository is the single source of truth.
/// Only published questions are available to students.
///
/// Legacy static question-bank data is intentionally not used.
class QuizService {
  QuizService({LocalQuestionRepository? repository})
    : _repository = repository ?? LocalQuestionRepository.instance;

  final LocalQuestionRepository _repository;

  // ==========================================================
  // INITIALIZATION
  // ==========================================================

  Future<void> initialize() async {
    await _repository.initialize();
  }

  // ==========================================================
  // BASIC PUBLISHED QUESTION ACCESS
  // ==========================================================

  /// Returns every published question in the managed repository.
  List<Question> getAllQuestions() {
    return _published(_repository.questions);
  }

  /// Returns all published questions for a specific domain.
  List<Question> getQuestionsByDomain(int domain) {
    return _published(
      _repository.questions.where((question) => question.domain == domain),
    );
  }

  /// Returns all published questions for a specific competency.
  List<Question> getQuestionsByCompetency(String competencyId) {
    return _published(
      _repository.questions.where(
        (question) => question.competencyId == competencyId,
      ),
    );
  }

  /// Returns all published questions for a specific subtopic.
  List<Question> getQuestionsBySubtopic(String subtopicId) {
    return _published(
      _repository.questions.where(
        (question) => question.subtopicId == subtopicId,
      ),
    );
  }

  /// Returns all published questions for a specific topic.
  List<Question> getQuestionsByTopic(String topicId) {
    return _published(
      _repository.questions.where((question) => question.topicId == topicId),
    );
  }

  /// Returns all published questions for a specific quiz ID.
  List<Question> getQuestionsByQuizId(String quizId) {
    return _published(
      _repository.questions.where((question) => question.quizId == quizId),
    );
  }

  // ==========================================================
  // EXISTING QUIZ CONTROLLER COMPATIBILITY
  // ==========================================================

  /// Domain quiz used by QuizController.
  ///
  /// The current domain quiz defaults to 10 questions.
  List<Question> getQuiz({
    required int domain,
    required int numberOfQuestions,
  }) {
    return buildQuiz(domain: domain, numberOfQuestions: numberOfQuestions);
  }

  /// Quiz-ID-based quiz used by QuizController.
  ///
  /// Questions are randomized but no questions are duplicated.
  List<Question> getQuizById(String quizId) {
    final questions = getQuestionsByQuizId(quizId);

    return _shuffle(questions);
  }

  /// Competency quiz used by QuizController.
  List<Question> getShuffledQuestionsByCompetency(String competencyId) {
    return _shuffle(getQuestionsByCompetency(competencyId));
  }

  /// Subtopic quiz used by QuizController.
  ///
  /// A dedicated subtopic quiz requires at least five published questions.
  /// There is no maximum question count. When more than five published
  /// questions exist, the full published pool is randomized.
  List<Question> getShuffledQuestionsBySubtopic(String subtopicId) {
    final questions = getQuestionsBySubtopic(subtopicId);

    if (!hasMinimumPublishedQuestions(questions.length)) {
      throw StateError(
        'This subtopic has ${questions.length} published questions. '
        'A dedicated subtopic quiz requires at least 5 published questions.',
      );
    }

    return _shuffle(questions);
  }

  /// Returns whether a dedicated subtopic quiz has its minimum
  /// published-question pool. Five is a minimum, not a maximum.
  static bool hasMinimumPublishedQuestions(int publishedCount) =>
      publishedCount >= 5;

  /// Main-content topic quiz used by QuizController.
  List<Question> getShuffledQuestionsByTopic(String topicId) {
    return _shuffle(getQuestionsByTopic(topicId));
  }

  // ==========================================================
  // DYNAMIC MAIN-PAGE QUIZZES
  // ==========================================================

  /// Mixed CSP11 quiz.
  ///
  /// Questions may come from any published domain,
  /// competency, topic or subtopic.
  List<Question> getMixedQuiz({
    required int numberOfQuestions,
    String? difficulty,
    String? cognitiveLevel,
  }) {
    return _buildQuiz(
      getAllQuestions(),
      numberOfQuestions: numberOfQuestions,
      difficulty: difficulty,
      cognitiveLevel: cognitiveLevel,
    );
  }

  /// Quiz restricted to one domain.
  List<Question> getDomainQuiz({
    required int domain,
    required int numberOfQuestions,
    String? difficulty,
    String? cognitiveLevel,
  }) {
    return _buildQuiz(
      getQuestionsByDomain(domain),
      numberOfQuestions: numberOfQuestions,
      difficulty: difficulty,
      cognitiveLevel: cognitiveLevel,
    );
  }

  /// Quiz restricted to one competency.
  List<Question> getCompetencyQuiz({
    required String competencyId,
    required int numberOfQuestions,
    String? difficulty,
    String? cognitiveLevel,
  }) {
    return _buildQuiz(
      getQuestionsByCompetency(competencyId),
      numberOfQuestions: numberOfQuestions,
      difficulty: difficulty,
      cognitiveLevel: cognitiveLevel,
    );
  }

  /// Quiz restricted to one subtopic.
  List<Question> getSubtopicQuiz({
    required String subtopicId,
    int numberOfQuestions = 5,
    String? difficulty,
    String? cognitiveLevel,
  }) {
    return _buildQuiz(
      getQuestionsBySubtopic(subtopicId),
      numberOfQuestions: numberOfQuestions,
      difficulty: difficulty,
      cognitiveLevel: cognitiveLevel,
    );
  }

  /// Quiz restricted to one topic.
  List<Question> getTopicQuiz({
    required String topicId,
    required int numberOfQuestions,
    String? difficulty,
    String? cognitiveLevel,
  }) {
    return _buildQuiz(
      getQuestionsByTopic(topicId),
      numberOfQuestions: numberOfQuestions,
      difficulty: difficulty,
      cognitiveLevel: cognitiveLevel,
    );
  }

  // ==========================================================
  // GENERIC FILTERING
  // ==========================================================

  /// Returns published questions matching all supplied filters.
  List<Question> getFilteredQuestions({
    int? domain,
    String? competencyId,
    String? subtopicId,
    String? topicId,
    String? quizId,
    String? difficulty,
    String? cognitiveLevel,
  }) {
    return _filteredPool(
      domain: domain,
      competencyId: competencyId,
      subtopicId: subtopicId,
      topicId: topicId,
      quizId: quizId,
      difficulty: difficulty,
      cognitiveLevel: cognitiveLevel,
    );
  }

  /// Returns the number of published questions matching
  /// the supplied filters.
  int getAvailableQuestionCount({
    int? domain,
    String? competencyId,
    String? subtopicId,
    String? topicId,
    String? quizId,
    String? difficulty,
    String? cognitiveLevel,
  }) {
    return _filteredPool(
      domain: domain,
      competencyId: competencyId,
      subtopicId: subtopicId,
      topicId: topicId,
      quizId: quizId,
      difficulty: difficulty,
      cognitiveLevel: cognitiveLevel,
    ).length;
  }

  /// Returns the total number of published managed questions.
  int getTotalQuestions() {
    return getAllQuestions().length;
  }

  /// Returns the number of published questions in one domain.
  int getDomainQuestionCount(int domain) {
    return getQuestionsByDomain(domain).length;
  }

  /// Returns the number of published questions in one quiz.
  int getQuizQuestionCount(String quizId) {
    return getQuestionsByQuizId(quizId).length;
  }

  // ==========================================================
  // GENERIC QUIZ BUILDER
  // ==========================================================

  /// Builds a randomized quiz from the managed published pool.
  ///
  /// Questions are never duplicated and the requested number
  /// must not exceed the available published pool.
  List<Question> buildQuiz({
    int? domain,
    String? competencyId,
    String? subtopicId,
    String? topicId,
    String? quizId,
    required int numberOfQuestions,
    String? difficulty,
    String? cognitiveLevel,
  }) {
    if (numberOfQuestions < 1) {
      throw StateError('The quiz must contain at least one question.');
    }

    final pool = _filteredPool(
      domain: domain,
      competencyId: competencyId,
      subtopicId: subtopicId,
      topicId: topicId,
      quizId: quizId,
      difficulty: difficulty,
      cognitiveLevel: cognitiveLevel,
    );

    if (pool.length < numberOfQuestions) {
      throw StateError(
        'Only ${pool.length} published questions are '
        'available for the selected criteria. '
        '$numberOfQuestions were requested.',
      );
    }

    return _shuffle(pool).take(numberOfQuestions).toList();
  }

  // ==========================================================
  // INTERNAL HELPERS
  // ==========================================================

  List<Question> _buildQuiz(
    List<Question> source, {
    required int numberOfQuestions,
    String? difficulty,
    String? cognitiveLevel,
  }) {
    var pool = List<Question>.from(source);

    if (difficulty != null && difficulty.trim().isNotEmpty) {
      pool = pool
          .where(
            (question) =>
                question.difficulty.toLowerCase() ==
                difficulty.trim().toLowerCase(),
          )
          .toList();
    }

    if (cognitiveLevel != null && cognitiveLevel.trim().isNotEmpty) {
      pool = pool
          .where(
            (question) =>
                question.cognitiveLevel.toLowerCase() ==
                cognitiveLevel.trim().toLowerCase(),
          )
          .toList();
    }

    if (pool.length < numberOfQuestions) {
      throw StateError(
        'Only ${pool.length} published questions are '
        'available for the selected criteria. '
        '$numberOfQuestions were requested.',
      );
    }

    return _shuffle(pool).take(numberOfQuestions).toList();
  }

  List<Question> _filteredPool({
    int? domain,
    String? competencyId,
    String? subtopicId,
    String? topicId,
    String? quizId,
    String? difficulty,
    String? cognitiveLevel,
  }) {
    Iterable<Question> pool = _published(_repository.questions);

    if (domain != null) {
      pool = pool.where((question) => question.domain == domain);
    }

    if (competencyId != null && competencyId.trim().isNotEmpty) {
      pool = pool.where((question) => question.competencyId == competencyId);
    }

    if (subtopicId != null && subtopicId.trim().isNotEmpty) {
      pool = pool.where((question) => question.subtopicId == subtopicId);
    }

    if (topicId != null && topicId.trim().isNotEmpty) {
      pool = pool.where((question) => question.topicId == topicId);
    }

    if (quizId != null && quizId.trim().isNotEmpty) {
      pool = pool.where((question) => question.quizId == quizId);
    }

    if (difficulty != null && difficulty.trim().isNotEmpty) {
      pool = pool.where(
        (question) =>
            question.difficulty.toLowerCase() ==
            difficulty.trim().toLowerCase(),
      );
    }

    if (cognitiveLevel != null && cognitiveLevel.trim().isNotEmpty) {
      pool = pool.where(
        (question) =>
            question.cognitiveLevel.toLowerCase() ==
            cognitiveLevel.trim().toLowerCase(),
      );
    }

    return pool.toList();
  }

  List<Question> _published(Iterable<Question> questions) {
    return questions
        .where((question) => question.status.toLowerCase() == 'published')
        .toList();
  }

  List<Question> _shuffle(List<Question> questions) {
    final result = List<Question>.from(questions);

    result.shuffle(Random());

    return result;
  }
}
