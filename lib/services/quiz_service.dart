import 'dart:math';

import '../models/question.dart';
import '../models/study_content.dart';
import 'cloud_question_repository.dart';
import 'quiz_service_interface.dart';
import 'study_content/cloud_content_repository.dart';

/// Central quiz service for the CSP11 application.
///
/// Student quizzes can receive questions from two Firebase-backed sources:
///
/// 1. Independently managed questions in the `questions` collection.
/// 2. Questions embedded inside published StudyContent packages/versions.
///
/// Both sources are combined into one published student question pool.
///
/// Only Published questions are exposed to the student quiz system.
///
/// Offline caching and synchronization are intentionally deferred to
/// Phase K.
class QuizService implements QuizServiceInterface {
  QuizService({
    CloudQuestionRepository? repository,
    CloudQuestionRepository? questionRepository,
    CloudContentRepository? contentRepository,
  }) : _questionRepository =
           questionRepository ?? repository ?? CloudQuestionRepository(),
       _contentRepository = contentRepository ?? CloudContentRepository();

  /// Firebase repository for independently managed questions.
  final CloudQuestionRepository _questionRepository;

  /// Firebase repository for published StudyContent packages/versions.
  final CloudContentRepository _contentRepository;

  List<Question> _questions = const <Question>[];

  bool _initialized = false;

  bool get isInitialized => _initialized;

  // ==========================================================
  // INITIALIZATION
  // ==========================================================

  /// Loads the complete published student question pool.
  ///
  /// Questions are collected from:
  ///
  /// - the Firebase `questions` collection
  /// - questions embedded inside published StudyContent
  ///
  /// Duplicate question IDs are removed.
  ///
  /// Questions originating from published StudyContent are treated as
  /// published because the containing content package/version itself is
  /// published.
  Future<void> initialize() async {
    final independentQuestions = await _questionRepository.loadAll();
    final publishedContent = await _contentRepository.loadPublished();

    final merged = <int, Question>{};

    // ----------------------------------------------------------
    // SOURCE 1
    // Independently managed Firebase questions
    // ----------------------------------------------------------

    for (final question in independentQuestions) {
      if (!_isPublished(question)) {
        continue;
      }

      if (question.id <= 0) {
        continue;
      }

      merged[question.id] = question;
    }

    // ----------------------------------------------------------
    // SOURCE 2
    // Questions embedded in published content
    // ----------------------------------------------------------

    for (final content in publishedContent) {
      if (!_isPublishedContent(content)) {
        continue;
      }

      _addContentQuestions(content: content, target: merged);
    }

    _questions = merged.values.toList()..sort((a, b) => a.id.compareTo(b.id));

    _initialized = true;
  }

  /// Reloads the published question pool from Firebase.
  ///
  /// Useful when new questions or content versions have been published
  /// after the current session was initialized.
  Future<void> refresh() async {
    await initialize();
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
  List<Question> getQuiz({
    required int domain,
    required int numberOfQuestions,
  }) {
    return buildQuiz(domain: domain, numberOfQuestions: numberOfQuestions);
  }

  /// Quiz-ID-based quiz used by QuizController.
  List<Question> getQuizById(String quizId) {
    return _shuffle(getQuestionsByQuizId(quizId));
  }

  /// Competency quiz used by QuizController.
  List<Question> getShuffledQuestionsByCompetency(String competencyId) {
    return _shuffle(getQuestionsByCompetency(competencyId));
  }

  /// Subtopic quiz used by QuizController.
  ///
  /// A dedicated subtopic quiz requires at least five published
  /// questions.
  ///
  /// Five is the minimum, not the maximum.
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
  // CONTENT-VERSION QUESTION IMPORT
  // ==========================================================

  /// Adds questions embedded in one published StudyContent package.
  ///
  /// The containing StudyContent is already published because it came
  /// from CloudContentRepository.loadPublished().
  ///
  /// Missing hierarchy metadata is filled from the content hierarchy:
  ///
  /// domain       <- StudyContent.domainId
  /// competency   <- StudyContent.competencyId
  /// subtopic     <- StudySubtopic.id
  /// content      <- StudyContent.id
  /// version      <- StudyContent.version
  /// status       <- published
  void _addContentQuestions({
    required StudyContent content,
    required Map<int, Question> target,
  }) {
    final domain = _parseDomainNumber(content.domainId);
    final competencyId = content.competencyId.trim();
    final contentPackageId = content.id.trim();

    for (final subtopic in content.subtopics) {
      final subtopicId = subtopic.id.trim();

      for (final question in subtopic.questions) {
        if (question.id <= 0) {
          continue;
        }

        if (!_isPublished(question)) {
          continue;
        }

        final normalized = _normalizeContentQuestion(
          question: question,
          domain: domain,
          competencyId: competencyId,
          subtopicId: subtopicId,
          contentPackageId: contentPackageId,
          contentVersion: content.version,
        );

        // Do not overwrite an independently managed Firebase
        // question with an embedded copy using the same ID.
        //
        // The central questions collection is the stronger managed
        // source when both sources contain the same question ID.
        target.putIfAbsent(normalized.id, () => normalized);
      }
    }
  }

  /// Creates the student-facing representation of an embedded
  /// content question.
  Question _normalizeContentQuestion({
    required Question question,
    required int domain,
    required String competencyId,
    required String subtopicId,
    required String contentPackageId,
    required int contentVersion,
  }) {
    return Question(
      id: question.id,
      domain: question.domain > 0 ? question.domain : domain,
      competencyId: question.competencyId.trim().isNotEmpty
          ? question.competencyId.trim()
          : competencyId,
      subtopicId: question.subtopicId.trim().isNotEmpty
          ? question.subtopicId.trim()
          : subtopicId,
      topicId: question.topicId.trim(),
      quizId: question.quizId.trim(),
      contentPackageId: question.contentPackageId.trim().isNotEmpty
          ? question.contentPackageId.trim()
          : contentPackageId,
      question: question.question,
      options: List<String>.from(question.options),
      correctAnswer: question.correctAnswer,
      explanation: question.explanation,
      bestAnswerRationale: question.bestAnswerRationale,
      reference: question.reference,
      difficulty: question.difficulty,
      cognitiveLevel: question.cognitiveLevel,
      questionType: question.questionType,
      status: 'published',
      version: question.version > 0 ? question.version : contentVersion,
      tags: List<String>.from(question.tags),
    );
  }

  // ==========================================================
  // STATUS / ID HELPERS
  // ==========================================================

  bool _isPublished(Question question) {
    return question.status.trim().toLowerCase() == 'published';
  }

  bool _isPublishedContent(StudyContent content) {
    return content.status.trim().toLowerCase() == 'published';
  }

  List<Question> _published(Iterable<Question> questions) {
    return questions.where(_isPublished).toList();
  }

  int _parseDomainNumber(String domainId) {
    final normalized = domainId.trim();

    if (normalized.isEmpty) {
      return 0;
    }

    final match = RegExp(
      r'(?:d|domain[_-]?)(\d+)',
      caseSensitive: false,
    ).firstMatch(normalized);

    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 0;
    }

    return int.tryParse(normalized) ?? 0;
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
