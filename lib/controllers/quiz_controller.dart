import 'dart:math';

import '../models/question.dart';
import '../services/quiz_service.dart';
import '../services/quiz_service_interface.dart';

class QuizController {
  final QuizServiceInterface _quizService;
  final Random _random;

  late List<Question> questions;

  int currentQuestion = 0;
  int? selectedAnswer;
  bool submitted = false;
  int score = 0;

  final List<Question> incorrectQuestions = [];

  /// Randomized display options for each question.
  ///
  /// The list at index [questionIndex] contains the original option
  /// indexes in the order they should be displayed.
  late List<List<int>> _optionOrders;

  // ==========================================================
  // DOMAIN QUIZ
  // ==========================================================

  QuizController({
    required int domain,
    QuizServiceInterface? quizService,
    Random? random,
  }) : _quizService = quizService ?? QuizService(),
       _random = random ?? Random() {
    questions = _quizService.getQuiz(domain: domain, numberOfQuestions: 10);

    _initializeOptionOrders();
  }

  // ==========================================================
  // QUIZ ID
  // ==========================================================

  QuizController.byQuizId({
    required String quizId,
    QuizServiceInterface? quizService,
    Random? random,
  }) : _quizService = quizService ?? QuizService(),
       _random = random ?? Random() {
    questions = _quizService.getQuizById(quizId);

    _initializeOptionOrders();
  }

  // ==========================================================
  // COMPETENCY QUIZ
  // ==========================================================

  QuizController.byCompetency({
    required String competencyId,
    QuizServiceInterface? quizService,
    Random? random,
  }) : _quizService = quizService ?? QuizService(),
       _random = random ?? Random() {
    questions = _quizService.getShuffledQuestionsByCompetency(competencyId);

    _initializeOptionOrders();
  }

  // ==========================================================
  // SUBTOPIC QUIZ
  // ==========================================================

  QuizController.bySubtopic({
    required String subtopicId,
    QuizServiceInterface? quizService,
    Random? random,
  }) : _quizService = quizService ?? QuizService(),
       _random = random ?? Random() {
    questions = _quizService.getShuffledQuestionsBySubtopic(subtopicId);

    _initializeOptionOrders();
  }

  // ==========================================================
  // MAIN CONTENT TOPIC QUIZ
  // ==========================================================

  QuizController.byTopic({
    required String topicId,
    QuizServiceInterface? quizService,
    Random? random,
  }) : _quizService = quizService ?? QuizService(),
       _random = random ?? Random() {
    questions = _quizService.getShuffledQuestionsByTopic(topicId);

    _initializeOptionOrders();
  }

  // ==========================================================
  // REVIEW INCORRECT QUESTIONS
  // ==========================================================

  QuizController.review({
    required List<Question> questions,
    QuizServiceInterface? quizService,
    Random? random,
  }) : _quizService = quizService ?? QuizService(),
       _random = random ?? Random() {
    this.questions = List<Question>.from(questions);

    _initializeOptionOrders();
  }

  // ==========================================================
  // OPTION RANDOMIZATION
  // ==========================================================

  void _initializeOptionOrders() {
    _optionOrders = List<List<int>>.generate(questions.length, (questionIndex) {
      final optionCount = questions[questionIndex].options.length;

      final order = List<int>.generate(optionCount, (index) => index);

      order.shuffle(_random);

      return order;
    });
  }

  /// Returns the original option index for a displayed option index.

  /// Returns the options in their randomized display order.
  List<String> get currentOptions {
    final question = currentQuestionData;
    final order = _optionOrders[currentQuestion];

    return List<String>.unmodifiable(
      order.map((originalIndex) => question.options[originalIndex]),
    );
  }

  /// Returns the displayed position of the original correct answer.
  int get currentCorrectDisplayIndex {
    final correctOriginalIndex = currentQuestionData.correctAnswer;

    return _optionOrders[currentQuestion].indexOf(correctOriginalIndex);
  }

  /// Returns whether a displayed option index is the correct answer.
  bool isCorrectDisplayedOption(int displayedIndex) {
    return displayedIndex == currentCorrectDisplayIndex;
  }

  // ==========================================================
  // ANSWER CONTROL
  // ==========================================================

  void selectAnswer(int index) {
    if (submitted) return;

    if (index < 0 || index >= currentOptions.length) {
      return;
    }

    selectedAnswer = index;
  }

  void submitAnswer() {
    if (submitted) return;

    if (selectedAnswer == null) return;

    submitted = true;

    if (isCorrectDisplayedOption(selectedAnswer!)) {
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

    _initializeOptionOrders();
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
