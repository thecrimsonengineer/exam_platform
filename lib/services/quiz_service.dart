import '../data/question_bank.dart';
import '../data/quiz_catalog.dart';
import '../models/question.dart';

class QuizService {
  /// Returns all questions from the question bank.
  List<Question> getAllQuestions() {
    return List<Question>.from(questionBank);
  }

  // ==========================================================
  // DOMAIN
  // ==========================================================

  /// Returns questions for a specific domain.
  List<Question> getQuestionsByDomain(int domain) {
    return questionBank
        .where(
          (question) => question.domain == domain,
        )
        .toList();
  }

  /// Returns a shuffled list of questions for a domain.
  List<Question> getShuffledQuestions(int domain) {
    final questions = getQuestionsByDomain(domain);
    questions.shuffle();
    return questions;
  }

  /// Returns a limited number of shuffled questions for a domain.
  List<Question> getQuiz({
    required int domain,
    required int numberOfQuestions,
  }) {
    final questions = getShuffledQuestions(domain);

    if (questions.length <= numberOfQuestions) {
      return questions;
    }

    return questions
        .take(numberOfQuestions)
        .toList();
  }

  // ==========================================================
  // COMPETENCY
  // ==========================================================

  /// Returns all questions belonging to a competency.
  List<Question> getQuestionsByCompetency(
    String competencyId,
  ) {
    return questionBank
        .where(
          (question) =>
              question.competencyId == competencyId,
        )
        .toList();
  }

  /// Returns shuffled questions for a competency.
  List<Question> getShuffledQuestionsByCompetency(
    String competencyId,
  ) {
    final questions =
        getQuestionsByCompetency(competencyId);

    questions.shuffle();

    return questions;
  }

  // ==========================================================
  // SUBTOPIC
  // ==========================================================

  /// Returns all questions belonging to a subtopic.
  List<Question> getQuestionsBySubtopic(
    String subtopicId,
  ) {
    return questionBank
        .where(
          (question) =>
              question.subtopicId == subtopicId,
        )
        .toList();
  }

  /// Returns shuffled questions for a subtopic.
  List<Question> getShuffledQuestionsBySubtopic(
    String subtopicId,
  ) {
    final questions =
        getQuestionsBySubtopic(subtopicId);

    questions.shuffle();

    return questions;
  }

  // ==========================================================
  // MAIN CONTENT TOPIC
  // ==========================================================

  /// Returns all questions belonging to a specific
  /// main-content topic.
  List<Question> getQuestionsByTopic(
    String topicId,
  ) {
    return questionBank
        .where(
          (question) =>
              question.topicId == topicId,
        )
        .toList();
  }

  /// Returns shuffled questions for a specific
  /// main-content topic.
  List<Question> getShuffledQuestionsByTopic(
    String topicId,
  ) {
    final questions =
        getQuestionsByTopic(topicId);

    questions.shuffle();

    return questions;
  }

  // ==========================================================
  // QUIZ ID
  // ==========================================================

  /// Returns the questions assigned to a specific quiz ID.
  ///
  /// The quiz catalog determines which question IDs belong
  /// to the quiz. The actual Question objects remain in the
  /// central question bank.
  List<Question> getQuestionsByQuizId(
    String quizId,
  ) {
    final quizCatalog = QuizCatalog();

    return quizCatalog.getQuestionsByQuizId(
      quizId,
      getAllQuestions(),
    );
  }

  /// Returns a shuffled quiz using a quiz ID.
  List<Question> getQuizById(
    String quizId, {
    bool shuffle = true,
  }) {
    final questions =
        getQuestionsByQuizId(quizId);

    if (shuffle) {
      questions.shuffle();
    }

    return questions;
  }

  /// Returns the definition of a quiz.
  QuizDefinition? getQuizDefinition(
    String quizId,
  ) {
    final quizCatalog = QuizCatalog();

    return quizCatalog.getQuizById(quizId);
  }

  /// Checks whether a quiz ID exists.
  bool hasQuiz(String quizId) {
    final quizCatalog = QuizCatalog();

    return quizCatalog.hasQuiz(quizId);
  }

  // ==========================================================
  // COUNTS
  // ==========================================================

  /// Returns the total number of questions in
  /// the question bank.
  int getTotalQuestions() {
    return questionBank.length;
  }

  /// Returns the number of questions in a domain.
  int getDomainQuestionCount(int domain) {
    return getQuestionsByDomain(domain).length;
  }

  /// Returns the number of questions in a competency.
  int getCompetencyQuestionCount(
    String competencyId,
  ) {
    return getQuestionsByCompetency(
      competencyId,
    ).length;
  }

  /// Returns the number of questions in a subtopic.
  int getSubtopicQuestionCount(
    String subtopicId,
  ) {
    return getQuestionsBySubtopic(
      subtopicId,
    ).length;
  }

  /// Returns the number of questions in a
  /// main-content topic.
  int getTopicQuestionCount(
    String topicId,
  ) {
    return getQuestionsByTopic(
      topicId,
    ).length;
  }

  /// Returns the number of questions assigned to
  /// a quiz.
  int getQuizQuestionCount(
    String quizId,
  ) {
    final quizCatalog = QuizCatalog();

    return quizCatalog.getQuestionCount(
      quizId,
    );
  }
}