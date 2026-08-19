import 'dart:math';

import '../models/question.dart';
import 'cloud_question_repository.dart';

/// Central quiz service for the CSP11 application.
///
/// Student quizzes consume Published questions from Firebase.
///
/// Questions may originate from:
/// 1. Independent question authoring in the managed question repository.
/// 2. Questions associated with a CSP11 content package/version.
///
/// Both are represented as Question documents in the Firebase
/// `questions` collection. The quiz service intentionally does not require
/// a question to have a quizId or contentPackageId in order to participate
/// in normal domain, competency, topic, or subtopic quizzes.
///
/// Offline caching is intentionally deferred to Phase K.
class QuizService {
  QuizService({CloudQuestionRepository? repository})
    : _repository = repository ?? CloudQuestionRepository();

  final CloudQuestionRepository _repository;

  List<Question> _questions = const <Question>[];
  bool _initialized = false;

  bool get isInitialized => _initialized;

  // ==========================================================
  // INITIALIZATION
  // ==========================================================

  /// Loads the complete managed question pool from Firebase.
  ///
  /// Only Published questions are retained for student consumption.
  ///
  /// Questions are allowed to exist independently of a content version.
  /// Questions linked to a content package/version are also retained.
  Future<void> initialize() async {
    final questions = await _repository.loadAll();

    _questions = _published(questions);
    _initialized = true;
  }

  /// Reloads the published question pool from Firebase.
  ///
  /// This is useful when newly published questions have been added after
  /// the service was initialized during the current application session.
  Future<void> refresh() async {
    await initialize();
  }

  // ==========================================================
  // BASIC PUBLISHED QUESTION ACCESS
  // ==========================================================

  /// Returns every published question available to the student platform.
  ///
  /// This includes:
  /// - independently authored published questions
  /// - published questions linked to content packages/versions
  List<Question> getAllQuestions() {
    return _published(_questions);
  }

  /// Returns all published questions for a specific domain.
  List<Question> getQuestionsByDomain(int domain) {
    return _published(
      _questions.where((question) => question.domain == domain),
    );
  }

  /// Returns all published questions for a specific competency.
  List<Question> getQuestionsByCompetency(String competencyId) {
    final normalizedId = competencyId.trim();

    if (normalizedId.isEmpty) {
      return <Question>[];
    }

    return _published(
      _questions.where((question) => question.competencyId == normalizedId),
    );
  }

  /// Returns all published questions for a specific subtopic.
  ///
  /// The subtopic relationship is the primary mapping used by dedicated
  /// CSP11 subtopic quizzes.
  List<Question> getQuestionsBySubtopic(String subtopicId) {
    final normalizedId = subtopicId.trim();

    if (normalizedId.isEmpty) {
      return <Question>[];
    }

    return _published(
      _questions.where((question) => question.subtopicId == normalizedId),
    );
  }

  /// Returns all published questions for a specific topic.
  List<Question> getQuestionsByTopic(String topicId) {
    final normalizedId = topicId.trim();

    if (normalizedId.isEmpty) {
      return <Question>[];
    }

    return _published(
      _questions.where((question) => question.topicId == normalizedId),
    );
  }

  /// Returns all published questions for a specific quiz ID.
  ///
  /// quizId is optional in the Question model. Therefore this method only
  /// returns questions that explicitly carry the requested quizId.
  List<Question> getQuestionsByQuizId(String quizId) {
    final normalizedId = quizId.trim();

    if (normalizedId.isEmpty) {
      return <Question>[];
    }

    return _published(
      _questions.where((question) => question.quizId == normalizedId),
    );
  }

  /// Returns all published questions associated with a content package.
  ///
  /// This can be used when a quiz is intentionally tied to a particular
  /// content package/version.
  List<Question> getQuestionsByContentPackage(String contentPackageId) {
    final normalizedId = contentPackageId.trim();

    if (normalizedId.isEmpty) {
      return <Question>[];
    }

    return _published(
      _questions.where((question) => question.contentPackageId == normalizedId),
    );
  }

  // ==========================================================
  // EXISTING QUIZ CONTROLLER COMPATIBILITY
  // ==========================================================

  /// Domain quiz used by QuizController.
  ///
  /// The current domain quiz defaults to the requested number of questions.
  List<Question> getQuiz({
    required int domain,
    required int numberOfQuestions,
  }) {
    return buildQuiz(domain: domain, numberOfQuestions: numberOfQuestions);
  }

  /// Quiz-ID-based quiz used by QuizController.
  ///
  /// Questions are randomized and never duplicated.
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
  /// Five is the minimum, not the maximum.
  ///
  /// Questions may be independent or linked to a content package/version.
  /// The subtopicId is the mapping used to collect them.
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
  /// published-question pool.
  static bool hasMinimumPublishedQuestions(int publishedCount) {
    return publishedCount >= 5;
  }

  /// Main-content topic quiz used by QuizController.
  List<Question> getShuffledQuestionsByTopic(String topicId) {
    return _shuffle(getQuestionsByTopic(topicId));
  }

  // ==========================================================
  // DYNAMIC MAIN-PAGE QUIZZES
  // ==========================================================

  /// Mixed CSP11 quiz.
  ///
  /// Questions may come from:
  /// - any published domain
  /// - any published competency
  /// - any published topic
  /// - any published subtopic
  /// - independent questions
  /// - content-version-linked questions
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
  ///
  /// Questions may be independent or associated with a content version.
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

  /// Quiz restricted to one content package/version.
  ///
  /// This is useful when the UI needs a quiz tied specifically to the
  /// published content package currently being studied.
  List<Question> getContentPackageQuiz({
    required String contentPackageId,
    required int numberOfQuestions,
    String? difficulty,
    String? cognitiveLevel,
  }) {
    return _buildQuiz(
      getQuestionsByContentPackage(contentPackageId),
      numberOfQuestions: numberOfQuestions,
      difficulty: difficulty,
      cognitiveLevel: cognitiveLevel,
    );
  }

  // ==========================================================
  // GENERIC FILTERING
  // ==========================================================

  /// Returns published questions matching all supplied filters.
  ///
  /// All filters are optional.
  ///
  /// Important:
  /// contentPackageId is optional because independently authored questions
  /// may not belong to a content package/version.
  List<Question> getFilteredQuestions({
    int? domain,
    String? competencyId,
    String? subtopicId,
    String? topicId,
    String? quizId,
    String? contentPackageId,
    String? difficulty,
    String? cognitiveLevel,
  }) {
    return _filteredPool(
      domain: domain,
      competencyId: competencyId,
      subtopicId: subtopicId,
      topicId: topicId,
      quizId: quizId,
      contentPackageId: contentPackageId,
      difficulty: difficulty,
      cognitiveLevel: cognitiveLevel,
    );
  }

  /// Returns the number of published questions matching the supplied
  /// filters.
  int getAvailableQuestionCount({
    int? domain,
    String? competencyId,
    String? subtopicId,
    String? topicId,
    String? quizId,
    String? contentPackageId,
    String? difficulty,
    String? cognitiveLevel,
  }) {
    return _filteredPool(
      domain: domain,
      competencyId: competencyId,
      subtopicId: subtopicId,
      topicId: topicId,
      quizId: quizId,
      contentPackageId: contentPackageId,
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

  /// Returns the number of published questions in one competency.
  int getCompetencyQuestionCount(String competencyId) {
    return getQuestionsByCompetency(competencyId).length;
  }

  /// Returns the number of published questions in one topic.
  int getTopicQuestionCount(String topicId) {
    return getQuestionsByTopic(topicId).length;
  }

  /// Returns the number of published questions in one subtopic.
  int getSubtopicQuestionCount(String subtopicId) {
    return getQuestionsBySubtopic(subtopicId).length;
  }

  /// Returns the number of published questions in one quiz.
  int getQuizQuestionCount(String quizId) {
    return getQuestionsByQuizId(quizId).length;
  }

  /// Returns the number of published questions in one content package.
  int getContentPackageQuestionCount(String contentPackageId) {
    return getQuestionsByContentPackage(contentPackageId).length;
  }

  // ==========================================================
  // GENERIC QUIZ BUILDER
  // ==========================================================

  /// Builds a randomized quiz from the managed published pool.
  ///
  /// Questions are never duplicated.
  ///
  /// The requested number must not exceed the available published pool.
  List<Question> buildQuiz({
    int? domain,
    String? competencyId,
    String? subtopicId,
    String? topicId,
    String? quizId,
    String? contentPackageId,
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
      contentPackageId: contentPackageId,
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
    if (numberOfQuestions < 1) {
      throw StateError('The quiz must contain at least one question.');
    }

    var pool = List<Question>.from(source);

    if (difficulty != null && difficulty.trim().isNotEmpty) {
      final normalizedDifficulty = difficulty.trim().toLowerCase();

      pool = pool
          .where(
            (question) =>
                question.difficulty.toLowerCase() == normalizedDifficulty,
          )
          .toList();
    }

    if (cognitiveLevel != null && cognitiveLevel.trim().isNotEmpty) {
      final normalizedCognitiveLevel = cognitiveLevel.trim().toLowerCase();

      pool = pool
          .where(
            (question) =>
                question.cognitiveLevel.toLowerCase() ==
                normalizedCognitiveLevel,
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
    String? contentPackageId,
    String? difficulty,
    String? cognitiveLevel,
  }) {
    Iterable<Question> pool = _published(_questions);

    if (domain != null) {
      pool = pool.where((question) => question.domain == domain);
    }

    if (competencyId != null && competencyId.trim().isNotEmpty) {
      final normalizedId = competencyId.trim();

      pool = pool.where((question) => question.competencyId == normalizedId);
    }

    if (subtopicId != null && subtopicId.trim().isNotEmpty) {
      final normalizedId = subtopicId.trim();

      pool = pool.where((question) => question.subtopicId == normalizedId);
    }

    if (topicId != null && topicId.trim().isNotEmpty) {
      final normalizedId = topicId.trim();

      pool = pool.where((question) => question.topicId == normalizedId);
    }

    if (quizId != null && quizId.trim().isNotEmpty) {
      final normalizedId = quizId.trim();

      pool = pool.where((question) => question.quizId == normalizedId);
    }

    if (contentPackageId != null && contentPackageId.trim().isNotEmpty) {
      final normalizedId = contentPackageId.trim();

      pool = pool.where(
        (question) => question.contentPackageId == normalizedId,
      );
    }

    if (difficulty != null && difficulty.trim().isNotEmpty) {
      final normalizedDifficulty = difficulty.trim().toLowerCase();

      pool = pool.where(
        (question) => question.difficulty.toLowerCase() == normalizedDifficulty,
      );
    }

    if (cognitiveLevel != null && cognitiveLevel.trim().isNotEmpty) {
      final normalizedCognitiveLevel = cognitiveLevel.trim().toLowerCase();

      pool = pool.where(
        (question) =>
            question.cognitiveLevel.toLowerCase() == normalizedCognitiveLevel,
      );
    }

    return pool.toList();
  }

  List<Question> _published(Iterable<Question> questions) {
    return questions
        .where(
          (question) => question.status.trim().toLowerCase() == 'published',
        )
        .toList();
  }

  List<Question> _shuffle(List<Question> questions) {
    final result = List<Question>.from(questions);

    result.shuffle(Random());

    return result;
  }
}
