import 'dart:math';

import 'package:exam_platform/models/question.dart';
import 'package:exam_platform/models/study_content.dart';

import 'questions/learner_question_package_delivery_service.dart';
import 'questions/published_question_package.dart';
import 'quiz_service_interface.dart';

/// Learner quiz service backed by FR9 verified competency packages.
///
/// The service owns only the currently prepared protected question scope.
/// It never performs a global learner Firestore question/content preload.
class QuizService implements QuizServiceInterface {
  static QuizService? _shared;

  static QuizService get shared => _shared ??= QuizService();

  static void clearSharedProtectedSession() {
    _shared?.clearProtectedSession();
  }

  QuizService({
    LearnerQuestionPackageDeliveryService? deliveryService,
    Object? repository,
    Object? questionRepository,
    Object? contentRepository,
  }) : _deliveryService =
           deliveryService ?? LearnerQuestionPackageDeliveryService();

  final LearnerQuestionPackageDeliveryService _deliveryService;

  List<Question> _questions = const <Question>[];
  Future<void>? _preparationFuture;
  int _protectedSessionGeneration = 0;
  _PreparedQuizScope? _preparedScope;

  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Compatibility view for legacy widgets.
  ///
  /// FR9 learner quiz assembly no longer consumes StudyContent.
  List<StudyContent> getPublishedContent() => const <StudyContent>[];

  /// The former whole-bank initializer is permanently disabled for learners.
  Future<void> initialize({bool forceRefresh = false}) async {
    throw StateError(
      'Global learner quiz initialization is disabled. '
      'Prepare an explicit FR9 question scope instead.',
    );
  }

  Future<List<PublishedQuestionPackageDescriptor>>
  loadCatalogMetadata() {
    return _deliveryService.loadCatalog();
  }

  Future<void> prepareCompetencies(
    Iterable<String> competencyIds, {
    bool forceRefresh = false,
  }) async {
    final normalized = competencyIds
        .map((id) => id.trim().toLowerCase())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    if (normalized.isEmpty) {
      throw StateError('At least one competency is required for practice.');
    }

    final scopeKey = normalized.join('|');
    final scope = _PreparedQuizScope(domain: 0, quizId: scopeKey);

    if (_initialized && !forceRefresh && _preparedScope == scope) {
      return;
    }

    final generation = _protectedSessionGeneration;
    final merged = <int, Question>{};

    for (final competencyId in normalized) {
      final questions = await _deliveryService.loadCompetency(competencyId);

      if (generation != _protectedSessionGeneration) {
        return;
      }

      for (final question in questions) {
        if (_isPublished(question) && question.id > 0) {
          merged.putIfAbsent(question.id, () => question);
        }
      }
    }

    final nextQuestions = merged.values.toList()
      ..sort((left, right) => left.id.compareTo(right.id));

    if (generation != _protectedSessionGeneration) {
      return;
    }

    _questions = List<Question>.unmodifiable(nextQuestions);
    _preparedScope = scope;
    _initialized = true;
  }

  Future<void> prepareScope({
    required int domain,
    String? quizId,
    String? competencyId,
    String? subtopicId,
    String? topicId,
    bool forceRefresh = false,
  }) async {
    final scope = _PreparedQuizScope(
      domain: domain,
      quizId: quizId,
      competencyId: competencyId,
      subtopicId: subtopicId,
      topicId: topicId,
    );

    if (_initialized && !forceRefresh && _preparedScope == scope) {
      return;
    }

    final activePreparation = _preparationFuture;
    if (activePreparation != null) {
      await activePreparation;

      if (_initialized && !forceRefresh && _preparedScope == scope) {
        return;
      }
    }

    final generation = _protectedSessionGeneration;
    final nextPreparation = _prepare(scope, generation);
    _preparationFuture = nextPreparation;

    try {
      await nextPreparation;
    } finally {
      if (identical(_preparationFuture, nextPreparation)) {
        _preparationFuture = null;
      }
    }
  }

  Future<void> _prepare(_PreparedQuizScope scope, int generation) async {
    final loaded = await _deliveryService.loadForScope(
      domain: scope.domain,
      quizId: scope.quizId,
      competencyId: scope.competencyId,
      subtopicId: scope.subtopicId,
      topicId: scope.topicId,
    );

    if (generation != _protectedSessionGeneration) {
      return;
    }

    final merged = <int, Question>{};

    for (final question in loaded) {
      if (!_isPublished(question) || question.id <= 0) {
        continue;
      }

      merged.putIfAbsent(question.id, () => question);
    }

    final nextQuestions = merged.values.toList()
      ..sort((left, right) => left.id.compareTo(right.id));

    if (generation != _protectedSessionGeneration) {
      return;
    }

    _questions = List<Question>.unmodifiable(nextQuestions);
    _preparedScope = scope;
    _initialized = true;
  }

  Future<void> refresh() async {
    final scope = _preparedScope;

    if (scope == null) {
      throw StateError('No learner quiz scope is prepared.');
    }

    await prepareScope(
      domain: scope.domain,
      quizId: scope.quizId,
      competencyId: scope.competencyId,
      subtopicId: scope.subtopicId,
      topicId: scope.topicId,
      forceRefresh: true,
    );
  }

  void clearProtectedSession() {
    _protectedSessionGeneration++;
    _questions = const <Question>[];
    _preparationFuture = null;
    _preparedScope = null;
    _initialized = false;
  }

  // ==========================================================
  // BASIC PUBLISHED QUESTION ACCESS
  // ==========================================================

  /// Returns every published question available to students.
  ///
  /// This includes both independent questions and questions originating
  /// from published content versions.
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
  /// The subtopic ID is the primary mapping used for dedicated
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

  /// Returns all published questions explicitly assigned to a quiz ID.
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
  @override
  List<Question> getQuiz({
    required int domain,
    required int numberOfQuestions,
  }) {
    return buildQuiz(domain: domain, numberOfQuestions: numberOfQuestions);
  }

  /// Quiz-ID-based quiz used by QuizController.
  @override
  List<Question> getQuizById(String quizId) {
    return _shuffle(getQuestionsByQuizId(quizId));
  }

  /// Competency quiz used by QuizController.
  @override
  List<Question> getShuffledQuestionsByCompetency(String competencyId) {
    return _shuffle(getQuestionsByCompetency(competencyId));
  }

  /// Subtopic quiz used by QuizController.
  ///
  /// A dedicated subtopic quiz requires at least five published
  /// questions.
  ///
  /// Five is the minimum, not the maximum.
  @override
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

  /// Topic quiz used by QuizController.
  @override
  List<Question> getShuffledQuestionsByTopic(String topicId) {
    return _shuffle(getQuestionsByTopic(topicId));
  }

  /// Returns whether a subtopic has enough published questions
  /// for a dedicated quiz.
  static bool hasMinimumPublishedQuestions(int publishedCount) {
    return publishedCount >= 5;
  }

  // ==========================================================
  // DYNAMIC QUIZ BUILDERS
  // ==========================================================

  /// Builds a mixed CSP11 quiz.
  ///
  /// Questions may come from any published domain, competency,
  /// topic, subtopic, content package, or independent question source.
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

  /// Builds a quiz restricted to one domain.
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

  /// Builds a quiz restricted to one competency.
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

  /// Builds a quiz restricted to one subtopic.
  ///
  /// Questions may be independent or embedded in a published
  /// content version.
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

  /// Builds a quiz restricted to one topic.
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

  /// Builds a quiz restricted to one content package/version.
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

  /// Returns the number of published questions matching
  /// the supplied filters.
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

  // ==========================================================
  // QUESTION COUNTS
  // ==========================================================

  int getTotalQuestions() {
    return getAllQuestions().length;
  }

  int getDomainQuestionCount(int domain) {
    return getQuestionsByDomain(domain).length;
  }

  int getCompetencyQuestionCount(String competencyId) {
    return getQuestionsByCompetency(competencyId).length;
  }

  int getTopicQuestionCount(String topicId) {
    return getQuestionsByTopic(topicId).length;
  }

  int getSubtopicQuestionCount(String subtopicId) {
    return getQuestionsBySubtopic(subtopicId).length;
  }

  int getQuizQuestionCount(String quizId) {
    return getQuestionsByQuizId(quizId).length;
  }

  int getContentPackageQuestionCount(String contentPackageId) {
    return getQuestionsByContentPackage(contentPackageId).length;
  }

  // ==========================================================
  // GENERIC QUIZ BUILDER
  // ==========================================================

  /// Builds a randomized quiz from the published question pool.
  ///
  /// Questions are never duplicated.
  ///
  /// The requested number must not exceed the available pool.
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
  // INTERNAL QUIZ HELPERS
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

  // ==========================================================
  // STATUS / ID HELPERS
  // ==========================================================

  bool _isPublished(Question question) {
    return question.status.trim().toLowerCase() == 'published';
  }

  List<Question> _published(Iterable<Question> questions) {
    return questions.where(_isPublished).toList();
  }

  // ==========================================================
  // RANDOMIZATION
  // ==========================================================

  List<Question> _shuffle(List<Question> questions) {
    final result = List<Question>.from(questions);

    result.shuffle(Random());

    return result;
  }
}

class _PreparedQuizScope {
  const _PreparedQuizScope({
    required this.domain,
    this.quizId,
    this.competencyId,
    this.subtopicId,
    this.topicId,
  });

  final int domain;
  final String? quizId;
  final String? competencyId;
  final String? subtopicId;
  final String? topicId;

  @override
  bool operator ==(Object other) {
    return other is _PreparedQuizScope &&
        domain == other.domain &&
        _normalize(quizId) == _normalize(other.quizId) &&
        _normalize(competencyId) == _normalize(other.competencyId) &&
        _normalize(subtopicId) == _normalize(other.subtopicId) &&
        _normalize(topicId) == _normalize(other.topicId);
  }

  @override
  int get hashCode => Object.hash(
    domain,
    _normalize(quizId),
    _normalize(competencyId),
    _normalize(subtopicId),
    _normalize(topicId),
  );

  static String _normalize(String? value) => value?.trim().toLowerCase() ?? '';
}
