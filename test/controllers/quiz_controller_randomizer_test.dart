import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:exam_platform/controllers/quiz_controller.dart';
import 'package:exam_platform/models/question.dart';
import 'package:exam_platform/services/quiz_service_interface.dart';

class FakeQuizService implements QuizServiceInterface {
  FakeQuizService(this._questions);

  final List<Question> _questions;

  @override
  List<Question> getQuiz({
    required int domain,
    required int numberOfQuestions,
  }) {
    return List<Question>.from(_questions);
  }

  @override
  List<Question> getQuizById(String quizId) {
    return List<Question>.from(_questions);
  }

  @override
  List<Question> getShuffledQuestionsByCompetency(String competencyId) {
    return List<Question>.from(_questions);
  }

  @override
  List<Question> getShuffledQuestionsBySubtopic(String subtopicId) {
    return List<Question>.from(_questions);
  }

  @override
  List<Question> getShuffledQuestionsByTopic(String topicId) {
    return List<Question>.from(_questions);
  }
}

Question _question({required int id, required int correctAnswer}) {
  return Question(
    id: id,
    domain: 1,
    competencyId: 'd01_c01',
    subtopicId: 'd01_c01_st01',
    topicId: 'd01_c01_t01',
    quizId: 'quiz_01',
    contentPackageId: 'cp_01',
    question: 'Which control is the most effective?',
    options: const [
      'Elimination',
      'Substitution',
      'Engineering control',
      'Administrative control',
    ],
    correctAnswer: correctAnswer,
    explanation: 'The answer follows the hierarchy of controls.',
    reference: 'Test reference',
    difficulty: 'Hard',
    cognitiveLevel: 'application',
    questionType: 'scenario_mcq',
    status: 'published',
    version: 1,
    tags: const ['test'],
  );
}

void main() {
  group('QuizController answer randomizer', () {
    test('keeps all four answer options after randomization', () {
      final question = _question(id: 1, correctAnswer: 0);

      final controller = QuizController(
        domain: 1,
        quizService: FakeQuizService([question]),
        random: Random(1),
      );

      expect(controller.currentOptions.length, 4);

      expect(controller.currentOptions.toSet(), question.options.toSet());
    });

    test('randomized options preserve the original correct answer', () {
      final question = _question(id: 1, correctAnswer: 0);

      final controller = QuizController(
        domain: 1,
        quizService: FakeQuizService([question]),
        random: Random(2),
      );

      final correctDisplayIndex = controller.currentCorrectDisplayIndex;

      expect(
        controller.currentOptions[correctDisplayIndex],
        question.options[question.correctAnswer],
      );

      expect(controller.isCorrectDisplayedOption(correctDisplayIndex), isTrue);
    });

    test('selecting the displayed correct answer increases the score', () {
      final question = _question(id: 1, correctAnswer: 0);

      final controller = QuizController(
        domain: 1,
        quizService: FakeQuizService([question]),
        random: Random(3),
      );

      final correctDisplayIndex = controller.currentCorrectDisplayIndex;

      controller.selectAnswer(correctDisplayIndex);
      controller.submitAnswer();

      expect(controller.score, 1);
      expect(controller.correctAnswers, 1);
      expect(controller.incorrectQuestions, isEmpty);
    });

    test('selecting a displayed wrong answer does not increase the score', () {
      final question = _question(id: 1, correctAnswer: 0);

      final controller = QuizController(
        domain: 1,
        quizService: FakeQuizService([question]),
        random: Random(4),
      );

      final correctDisplayIndex = controller.currentCorrectDisplayIndex;

      final wrongDisplayIndex = List<int>.generate(
        controller.currentOptions.length,
        (index) => index,
      ).firstWhere((index) => index != correctDisplayIndex);

      controller.selectAnswer(wrongDisplayIndex);
      controller.submitAnswer();

      expect(controller.score, 0);
      expect(controller.correctAnswers, 0);
      expect(controller.incorrectQuestions.length, 1);
      expect(controller.incorrectQuestions.single.id, 1);
    });

    test(
      'randomization works when the original correct answer is option B',
      () {
        final question = _question(id: 1, correctAnswer: 1);

        final controller = QuizController(
          domain: 1,
          quizService: FakeQuizService([question]),
          random: Random(5),
        );

        final correctDisplayIndex = controller.currentCorrectDisplayIndex;

        expect(
          controller.currentOptions[correctDisplayIndex],
          question.options[1],
        );

        controller.selectAnswer(correctDisplayIndex);
        controller.submitAnswer();

        expect(controller.score, 1);
      },
    );

    test(
      'randomization works when the original correct answer is option C',
      () {
        final question = _question(id: 1, correctAnswer: 2);

        final controller = QuizController(
          domain: 1,
          quizService: FakeQuizService([question]),
          random: Random(6),
        );

        final correctDisplayIndex = controller.currentCorrectDisplayIndex;

        expect(
          controller.currentOptions[correctDisplayIndex],
          question.options[2],
        );

        controller.selectAnswer(correctDisplayIndex);
        controller.submitAnswer();

        expect(controller.score, 1);
      },
    );

    test(
      'randomization works when the original correct answer is option D',
      () {
        final question = _question(id: 1, correctAnswer: 3);

        final controller = QuizController(
          domain: 1,
          quizService: FakeQuizService([question]),
          random: Random(7),
        );

        final correctDisplayIndex = controller.currentCorrectDisplayIndex;

        expect(
          controller.currentOptions[correctDisplayIndex],
          question.options[3],
        );

        controller.selectAnswer(correctDisplayIndex);
        controller.submitAnswer();

        expect(controller.score, 1);
      },
    );

    test('randomized option order remains stable while answering', () {
      final question = _question(id: 1, correctAnswer: 0);

      final controller = QuizController(
        domain: 1,
        quizService: FakeQuizService([question]),
        random: Random(8),
      );

      final firstOrder = List<String>.from(controller.currentOptions);

      controller.selectAnswer(0);

      final secondOrder = List<String>.from(controller.currentOptions);

      expect(secondOrder, firstOrder);
    });

    test('next question gets its own randomized option order', () {
      final questions = [
        _question(id: 1, correctAnswer: 0),
        _question(id: 2, correctAnswer: 2),
      ];

      final controller = QuizController(
        domain: 1,
        quizService: FakeQuizService(questions),
        random: Random(9),
      );

      expect(controller.currentOptions.length, 4);

      expect(
        controller.currentOptions[controller.currentCorrectDisplayIndex],
        questions[0].options[0],
      );

      expect(controller.nextQuestion(), isTrue);

      expect(controller.currentQuestion, 1);
      expect(controller.currentOptions.length, 4);

      expect(
        controller.currentOptions[controller.currentCorrectDisplayIndex],
        questions[1].options[2],
      );
    });

    test('resetQuiz resets answer state and regenerates option orders', () {
      final question = _question(id: 1, correctAnswer: 0);

      final controller = QuizController(
        domain: 1,
        quizService: FakeQuizService([question]),
        random: Random(10),
      );

      controller.selectAnswer(controller.currentCorrectDisplayIndex);
      controller.submitAnswer();

      expect(controller.submitted, isTrue);
      expect(controller.score, 1);

      controller.resetQuiz();

      expect(controller.currentQuestion, 0);
      expect(controller.selectedAnswer, isNull);
      expect(controller.submitted, isFalse);
      expect(controller.score, 0);
      expect(controller.incorrectQuestions, isEmpty);

      expect(controller.currentOptions.length, 4);

      expect(
        controller.currentOptions[controller.currentCorrectDisplayIndex],
        question.options[question.correctAnswer],
      );
    });
  });
}
