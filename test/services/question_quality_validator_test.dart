import 'package:flutter_test/flutter_test.dart';

import 'package:exam_platform/models/question.dart';
import 'package:exam_platform/services/question_quality_validator.dart';

void main() {
  group('QuestionQualityValidator H0.3', () {
    late QuestionQualityValidator validator;

    setUp(() {
      validator = const QuestionQualityValidator();
    });

    Question makeQuestion({
      int id = 1,
      String question = 'Which culture response is best?',
      List<String>? options,
      int correctAnswer = 0,
      String explanation =
          'The best answer addresses the underlying organizational mechanism and uses the evidence in the scenario rather than relying on a superficial metric or symbolic response.',
      String reference = 'CSP11 quality-gate reference',
      String difficulty = 'hard',
      String cognitiveLevel = 'analysis',
      String questionType = 'scenario_mcq',
      List<String>? tags,
    }) {
      return Question(
        id: id,
        domain: 2,
        competencyId: 'd02_c03',
        subtopicId: 'd02_c03_t01_s01',
        topicId: 'd02_c03_t01',
        quizId: 'd02_c03_t01_s01_quiz',
        contentPackageId: 'd02_c03-v1',
        question: question,
        options: options ??
            const [
              'Address the organizational mechanism shown by the evidence.',
              'Repeat the existing message without changing the work system.',
              'Focus only on the latest outcome measure and close the review.',
              'Increase employee discipline without examining management conditions.',
            ],
        correctAnswer: correctAnswer,
        explanation: explanation,
        reference: reference,
        difficulty: difficulty,
        cognitiveLevel: cognitiveLevel,
        questionType: questionType,
        status: 'draft',
        version: 1,
        tags: tags ?? const ['EHS culture', 'CSP11'],
      );
    }

    List<String> codes(Question question) =>
        validator.validateReport(question).issues.map((issue) => issue.code).toList();

    test('valid question produces clean passing report', () {
      final result = validator.validateReport(makeQuestion());
      expect(result.passed, isTrue);
      expect(result.blocked, isFalse);
      expect(result.issues, isEmpty);
    });

    test('short non-empty stem has no character-length warning', () {
      final result = validator.validateReport(
        makeQuestion(question: 'Best action?'),
      );
      expect(result.passed, isTrue);
      expect(result.blocked, isFalse);
      expect(codes(makeQuestion(question: 'Best action?')),
          isNot(contains('weak_question_stem')));
    });

    test('very long stem has no maximum character limit', () {
      final longStem = '${'A detailed workplace culture scenario. ' * 400}Which action is best?';
      final result = validator.validateReport(makeQuestion(question: longStem));
      expect(result.passed, isTrue);
      expect(result.blocked, isFalse);
      expect(result.issues.where((issue) => issue.field == 'question'), isEmpty);
    });

    test('empty stem still blocks', () {
      final result = validator.validateReport(makeQuestion(question: '   '));
      expect(result.blocked, isTrue);
      expect(codes(makeQuestion(question: '   ')), contains('missing_question_stem'));
    });

    test('question type must be scenario_mcq', () {
      expect(
        codes(makeQuestion(questionType: 'direct_mcq')),
        contains('invalid_question_type'),
      );
    });

    test('cognitive level must be application or analysis', () {
      expect(
        codes(makeQuestion(cognitiveLevel: 'knowledge')),
        contains('invalid_cognitive_level'),
      );
    });

    test('difficulty must be hard', () {
      expect(
        codes(makeQuestion(difficulty: 'medium')),
        contains('invalid_difficulty'),
      );
    });

    test('exactly four options required', () {
      expect(
        codes(makeQuestion(options: const ['A', 'B', 'C'])),
        contains('invalid_option_count'),
      );
    });

    test('empty option blocks', () {
      expect(
        codes(makeQuestion(options: const [
          'First balanced option here.',
          '',
          'Third balanced option here.',
          'Fourth balanced option here.',
        ])),
        contains('empty_answer_option'),
      );
    });

    test('duplicate option blocks', () {
      expect(
        codes(makeQuestion(options: const [
          'First balanced option here.',
          'Second balanced option here.',
          'Second balanced option here.',
          'Fourth balanced option here.',
        ])),
        contains('duplicate_answer_option'),
      );
    });

    test('correct answer must be a valid zero-based index', () {
      expect(codes(makeQuestion(correctAnswer: -1)), contains('invalid_correct_answer'));
      expect(codes(makeQuestion(correctAnswer: 4)), contains('invalid_correct_answer'));
    });

    test('missing explanation blocks and weak explanation warns', () {
      expect(codes(makeQuestion(explanation: '')), contains('missing_explanation'));
      expect(codes(makeQuestion(explanation: 'Too short.')), contains('weak_explanation'));
    });

    test('reference is required', () {
      expect(codes(makeQuestion(reference: '')), contains('missing_reference'));
    });

    test('at least two tags expected', () {
      expect(codes(makeQuestion(tags: const [])), contains('insufficient_tags'));
    });

    test('uniquely longest BEST answer warns', () {
      final resultCodes = codes(makeQuestion(options: const [
        'Address the organizational mechanism and redesign the management system so the repeated pressure is removed at its source.',
        'Repeat the safety message.',
        'Review the latest metric.',
        'Coach the employee again.',
      ]));
      expect(resultCodes, contains('best_answer_length_bias'));
    });

    test('option length imbalance warns', () {
      final resultCodes = codes(makeQuestion(options: const [
        'Use the control.',
        'Repeat the message to the workforce during the next scheduled meeting and ask supervisors to monitor the issue closely.',
        'Review the metric.',
        'Coach the worker.',
      ], correctAnswer: 2));
      expect(resultCodes, contains('option_length_imbalance'));
    });

    test('answer-length checks can be disabled', () {
      const disabled = QuestionQualityValidator(answerLengthCheckEnabled: false);
      final result = disabled.validateReport(makeQuestion(options: const [
        'Address the organizational mechanism and redesign the management system so the repeated pressure is removed at its source.',
        'Repeat the safety message.',
        'Review the latest metric.',
        'Coach the employee again.',
      ]));
      final resultCodes = result.issues.map((issue) => issue.code).toList();
      expect(resultCodes, isNot(contains('best_answer_length_bias')));
      expect(resultCodes, isNot(contains('option_length_imbalance')));
    });
  });
}
