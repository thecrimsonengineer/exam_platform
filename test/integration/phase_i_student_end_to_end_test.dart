import 'dart:math';

import 'package:exam_platform/controllers/quiz_controller.dart';
import 'package:exam_platform/models/question.dart';
import 'package:exam_platform/services/quiz_service_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase I Student Quiz Integration', () {
    test(
      'student quiz preserves correct answer after option randomization',
      () {
        final questions = List<Question>.generate(
          5,
          (index) => _question(
            id: index + 1,
            subtopicId: 'd01_c01_st01',
            correctAnswer: 0,
          ),
        );

        final controller = QuizController.review(
          questions: questions,
          quizService: _FakeQuizService(),
          random: Random(42),
        );

        expect(controller.totalQuestions, equals(5));

        final originalOptions = controller.currentQuestionData.options;
        final displayedOptions = controller.currentOptions;

        expect(displayedOptions.length, equals(4));

        expect(
          displayedOptions.toSet(),
          equals(originalOptions.toSet()),
        );

        final correctDisplayIndex =
            controller.currentCorrectDisplayIndex;

        expect(
          displayedOptions[correctDisplayIndex],
          equals(
            originalOptions[
              controller.currentQuestionData.correctAnswer
            ],
          ),
        );

        controller.selectAnswer(correctDisplayIndex);

        expect(
          controller.selectedAnswer,
          equals(correctDisplayIndex),
        );

        controller.submitAnswer();

        expect(controller.submitted, isTrue);
        expect(controller.correctAnswers, equals(1));
        expect(controller.incorrectAnswers, equals(4));
        expect(controller.incorrectQuestions, isEmpty);
      },
    );

    test(
      'student quiz records an incorrect answer against the original question',
      () {
        final questions = <Question>[
          _question(
            id: 101,
            subtopicId: 'd01_c01_st01',
            correctAnswer: 0,
          ),
          _question(
            id: 102,
            subtopicId: 'd01_c01_st01',
            correctAnswer: 0,
          ),
          _question(
            id: 103,
            subtopicId: 'd01_c01_st01',
            correctAnswer: 0,
          ),
          _question(
            id: 104,
            subtopicId: 'd01_c01_st01',
            correctAnswer: 0,
          ),
          _question(
            id: 105,
            subtopicId: 'd01_c01_st01',
            correctAnswer: 0,
          ),
        ];

        final controller = QuizController.review(
          questions: questions,
          quizService: _FakeQuizService(),
          random: Random(7),
        );

        final correctIndex =
            controller.currentCorrectDisplayIndex;

        final incorrectIndex = correctIndex == 0 ? 1 : 0;

        controller.selectAnswer(incorrectIndex);
        controller.submitAnswer();

        expect(controller.submitted, isTrue);
        expect(controller.correctAnswers, equals(0));
        expect(controller.incorrectAnswers, equals(5));

        expect(
          controller.incorrectQuestions,
          hasLength(1),
        );

        expect(
          controller.incorrectQuestions.single.id,
          equals(controller.currentQuestionData.id),
        );
      },
    );

    test(
      'student quiz can move through all questions and reset correctly',
      () {
        final questions = List<Question>.generate(
          5,
          (index) => _question(
            id: 201 + index,
            subtopicId: 'd01_c01_st01',
            correctAnswer: 0,
          ),
        );

        final controller = QuizController.review(
          questions: questions,
          quizService: _FakeQuizService(),
          random: Random(11),
        );

        expect(controller.currentQuestion, equals(0));
        expect(controller.questionNumber, equals(1));
        expect(controller.progress, equals(0.2));

        for (var index = 0; index < 4; index++) {
          final correctIndex =
              controller.currentCorrectDisplayIndex;

          controller.selectAnswer(correctIndex);
          controller.submitAnswer();

          expect(controller.submitted, isTrue);
          expect(controller.nextQuestion(), isTrue);
        }

        expect(controller.currentQuestion, equals(4));
        expect(controller.questionNumber, equals(5));
        expect(controller.isLastQuestion, isTrue);
        expect(controller.progress, equals(1.0));

        final lastCorrectIndex =
            controller.currentCorrectDisplayIndex;

        controller.selectAnswer(lastCorrectIndex);
        controller.submitAnswer();

        expect(controller.correctAnswers, equals(5));
        expect(controller.incorrectAnswers, equals(0));

        expect(controller.nextQuestion(), isFalse);

        controller.resetQuiz();

        expect(controller.currentQuestion, equals(0));
        expect(controller.questionNumber, equals(1));
        expect(controller.score, equals(0));
        expect(controller.selectedAnswer, isNull);
        expect(controller.submitted, isFalse);
        expect(controller.incorrectQuestions, isEmpty);
      },
    );
  });
}

Question _question({
  required int id,
  required String subtopicId,
  required int correctAnswer,
}) {
  return Question(
    id: id,
    domain: 1,
    competencyId: 'd01_c01',
    subtopicId: subtopicId,
    topicId: 'd01_c01_st01_t01',
    quizId: 'phase_i_quiz',
    contentPackageId: 'phase_i_package',
    question: 'Which control is most effective?',
    options: const [
      'Eliminate the hazard',
      'Use administrative controls',
      'Provide personal protective equipment',
      'Provide additional warning signs',
    ],
    correctAnswer: correctAnswer,
    explanation: 'Elimination removes the hazard at source.',
    bestAnswerRationale:
        'Elimination is higher in the hierarchy of controls.',
    reference: 'Phase I integration test',
    difficulty: 'Medium',
    cognitiveLevel: 'Application',
    questionType: 'Single Best Answer',
    status: 'Published',
    version: 1,
    tags: const ['phase-i'],
  );
}

class _FakeQuizService implements QuizServiceInterface {
  @override
  List<Question> getQuiz({
    required int domain,
    required int numberOfQuestions,
  }) {
    return <Question>[];
  }

  @override
  List<Question> getQuizById(String quizId) {
    return <Question>[];
  }

  @override
  List<Question> getShuffledQuestionsByCompetency(
    String competencyId,
  ) {
    return <Question>[];
  }

  @override
  List<Question> getShuffledQuestionsBySubtopic(
    String subtopicId,
  ) {
    return <Question>[];
  }

  @override
  List<Question> getShuffledQuestionsByTopic(
    String topicId,
  ) {
    return <Question>[];
  }
}