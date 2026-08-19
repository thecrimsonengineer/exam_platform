import '../models/question.dart';
import '../services/quiz_service.dart';

class QuizController {
  final QuizService _quizService;

  late List<Question> questions;

  int currentQuestion = 0;
  int? selectedAnswer;
  bool submitted = false;
  int score = 0;

  final List<Question> incorrectQuestions = [];

  // ==========================================================
  // DOMAIN QUIZ
  // ==========================================================

  /// Creates a quiz from a specific CSP domain.
  QuizController({required int domain, QuizService? quizService})
    : _quizService = quizService ?? QuizService() {
    questions = _quizService.getQuiz(domain: domain, numberOfQuestions: 10);
  }

  // ==========================================================
  // QUIZ ID
  // ==========================================================

  /// Creates a quiz using the existing quiz catalog.
  QuizController.byQuizId({required String quizId, QuizService? quizService})
    : _quizService = quizService ?? QuizService() {
    questions = _quizService.getQuizById(quizId);
  }

  // ==========================================================
  // COMPETENCY QUIZ
  // ==========================================================

  /// Creates a quiz containing questions from a competency.
  QuizController.byCompetency({
    required String competencyId,
    QuizService? quizService,
  }) : _quizService = quizService ?? QuizService() {
    questions = _quizService.getShuffledQuestionsByCompetency(competencyId);
  }

  // ==========================================================
  // SUBTOPIC QUIZ
  // ==========================================================

  /// Creates a quiz containing questions from a subtopic.
  QuizController.bySubtopic({
    required String subtopicId,
    QuizService? quizService,
  }) : _quizService = quizService ?? QuizService() {
    questions = _quizService.getShuffledQuestionsBySubtopic(subtopicId);
  }

  // ==========================================================
  // MAIN CONTENT TOPIC QUIZ
  // ==========================================================

  /// Creates a quiz containing questions from
  /// one main-content topic.
  QuizController.byTopic({required String topicId, QuizService? quizService})
    : _quizService = quizService ?? QuizService() {
    questions = _quizService.getShuffledQuestionsByTopic(topicId);
  }

  // ==========================================================
  // REVIEW INCORRECT QUESTIONS
  // ==========================================================

  /// Creates a quiz from previously incorrect questions.
  ///
  /// Review questions are already supplied by the caller, so
  /// no QuizService loading is required.
  QuizController.review({
    required List<Question> questions,
    QuizService? quizService,
  }) : _quizService = quizService ?? QuizService() {
    this.questions = List<Question>.from(questions);
  }

  // ==========================================================
  // ANSWER CONTROL
  // ==========================================================

  void selectAnswer(int index) {
    if (submitted) return;

    if (index < 0 || index >= currentQuestionData.options.length) {
      return;
    }

    selectedAnswer = index;
  }

  void submitAnswer() {
    if (submitted) return;

    if (selectedAnswer == null) return;

    submitted = true;

    if (selectedAnswer == currentQuestionData.correctAnswer) {
      score++;
    } else {
      incorrectQuestions.add(currentQuestionData);
    }
  }

  bool nextQuestion() {
    if (isLastQuestion) {
      return false;
    }

    currentQuestion++;
    selectedAnswer = null;
    submitted = false;

    return true;
  }

  void resetQuiz() {
    currentQuestion = 0;
    selectedAnswer = null;
    submitted = false;
    score = 0;
    incorrectQuestions.clear();
  }

  // ==========================================================
  // GETTERS
  // ==========================================================

  Question get currentQuestionData {
    return questions[currentQuestion];
  }

  double get progress {
    if (questions.isEmpty) {
      return 0.0;
    }

    return (currentQuestion + 1) / questions.length;
  }

  bool get isLastQuestion {
    if (questions.isEmpty) {
      return false;
    }

    return currentQuestion == questions.length - 1;
  }

  int get questionNumber => currentQuestion + 1;

  int get totalQuestions => questions.length;

  int get correctAnswers => score;

  int get incorrectAnswers => totalQuestions - score;
}
