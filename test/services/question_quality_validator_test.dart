import 'package:flutter_test/flutter_test.dart';

import 'package:exam_platform/models/question.dart';
import 'package:exam_platform/models/question_validation_report.dart';
import 'package:exam_platform/services/question_quality_validator.dart';

void main() {
  group('QuestionQualityValidator H0.3', () {
    late QuestionQualityValidator validator;

    setUp(() {
      validator = const QuestionQualityValidator();
    });

    Question makeQuestion({
      int id = 1,
      String question =
          'A safety manager identifies a recurring exposure during a high-risk workplace task. '
          'The existing controls are not fully effective and workers remain exposed to the hazard. '
          'Which action should the manager take first to reduce the risk most effectively?',
      List<String>? options,
      int correctAnswer = 0,
      String explanation =
          'The best answer addresses the risk at its source and provides the strongest practical control. '
          'This approach is preferred because it reduces reliance on worker behaviour and administrative controls.',
      String reference = 'CSP11 hierarchy of controls and risk control principles',
      String difficulty = 'hard',
      String cognitiveLevel = 'application',
      String questionType = 'scenario_mcq',
      List<String>? tags,
    }) {
      return Question(
        id: id,
        domain: 7,
        competencyId: 'd07_c02',
        subtopicId: 'd07_c02_01',
        topicId: 'd07_c02_01_t01',
        quizId: 'd07_c02-v1_d07_c02_01_quiz',
        contentPackageId: 'd07_c02-v1',
        question: question,
        options: options ??
            const [
              'Eliminate the hazard where reasonably practicable.',
              'Tell workers to remain alert while performing the task.',
              'Provide additional warning signs around the work area.',
              'Ask workers to report the hazard during the next meeting.',
            ],
        correctAnswer: correctAnswer,
        explanation: explanation,
        reference: reference,
        difficulty: difficulty,
        cognitiveLevel: cognitiveLevel,
        questionType: questionType,
        status: 'draft',
        version: 1,
        tags: tags ?? const [
          'risk control',
          'hierarchy of controls',
        ],
      );
    }

    QuestionValidationReport report(Question question) {
      return validator.validateReport(question);
    }

    List<String> codes(QuestionValidationReport report) {
      return report.issues.map((issue) => issue.code).toList();
    }

    QuestionQualityIssue issueFor(
      QuestionValidationReport report,
      String code,
    ) {
      return report.issues.firstWhere((issue) => issue.code == code);
    }

    test('valid question produces a clean passing report', () {
      final result = report(makeQuestion());

      expect(result.passed, isTrue);
      expect(result.blocked, isFalse);
      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);
      expect(result.errorCount, 0);
      expect(result.warningCount, 0);
      expect(result.issueCount, 0);
      expect(result.summary, 'PASSED • NO ISSUES');
    });

    test('wrong question type produces blocking error', () {
      final result = report(
        makeQuestion(questionType: 'direct_mcq'),
      );

      final issue = issueFor(result, 'invalid_question_type');

      expect(result.passed, isFalse);
      expect(result.blocked, isTrue);
      expect(issue.field, 'questionType');
      expect(issue.severity, QuestionIssueSeverity.error);
      expect(issue.isError, isTrue);
    });

    test('wrong cognitive level produces blocking error', () {
      final result = report(
        makeQuestion(cognitiveLevel: 'knowledge'),
      );

      final issue = issueFor(result, 'invalid_cognitive_level');

      expect(issue.field, 'cognitiveLevel');
      expect(issue.severity, QuestionIssueSeverity.error);
      expect(result.blocked, isTrue);
    });

    test('wrong difficulty produces blocking error', () {
      final result = report(
        makeQuestion(difficulty: 'medium'),
      );

      final issue = issueFor(result, 'invalid_difficulty');

      expect(issue.field, 'difficulty');
      expect(issue.severity, QuestionIssueSeverity.error);
      expect(result.blocked, isTrue);
    });

    test('missing question stem produces blocking error', () {
      final result = report(makeQuestion(question: ''));

      final issue = issueFor(result, 'missing_question_stem');

      expect(issue.field, 'question');
      expect(issue.severity, QuestionIssueSeverity.error);
      expect(result.blocked, isTrue);
    });

    test('weak question stem produces warning only', () {
      final result = report(
        makeQuestion(
          question: 'Which control should be selected first?',
        ),
      );

      final issue = issueFor(result, 'weak_question_stem');

      expect(issue.field, 'question');
      expect(issue.severity, QuestionIssueSeverity.warning);
      expect(result.passed, isTrue);
      expect(result.blocked, isFalse);
    });

    test('wrong option count produces blocking error', () {
      final result = report(
        makeQuestion(
          options: const [
            'First option',
            'Second option',
            'Third option',
          ],
        ),
      );

      final issue = issueFor(result, 'invalid_option_count');

      expect(issue.field, 'options');
      expect(issue.severity, QuestionIssueSeverity.error);
      expect(result.blocked, isTrue);
    });

    test('empty answer option produces blocking error', () {
      final result = report(
        makeQuestion(
          options: const [
            'Eliminate the hazard.',
            '',
            'Provide additional warning signs.',
            'Ask workers to report the hazard.',
          ],
        ),
      );

      final issue = issueFor(result, 'empty_answer_option');

      expect(issue.field, 'options');
      expect(issue.severity, QuestionIssueSeverity.error);
      expect(result.blocked, isTrue);
    });

    test('duplicate answer option produces blocking error', () {
      final result = report(
        makeQuestion(
          options: const [
            'Eliminate the hazard.',
            'Tell workers to remain alert.',
            'Tell workers to remain alert.',
            'Ask workers to report the hazard.',
          ],
        ),
      );

      final issue = issueFor(result, 'duplicate_answer_option');

      expect(issue.field, 'options');
      expect(issue.severity, QuestionIssueSeverity.error);
      expect(result.blocked, isTrue);
    });

    test('invalid BEST answer below zero produces blocking error', () {
      final result = report(
        makeQuestion(correctAnswer: -1),
      );

      final issue = issueFor(result, 'invalid_correct_answer');

      expect(issue.field, 'correctAnswer');
      expect(issue.severity, QuestionIssueSeverity.error);
      expect(result.blocked, isTrue);
    });

    test('invalid BEST answer beyond option range produces blocking error', () {
      final result = report(
        makeQuestion(correctAnswer: 4),
      );

      expect(
        codes(result),
        contains('invalid_correct_answer'),
      );
      expect(result.blocked, isTrue);
    });

    test('missing explanation produces blocking error', () {
      final result = report(
        makeQuestion(explanation: ''),
      );

      final issue = issueFor(result, 'missing_explanation');

      expect(issue.field, 'explanation');
      expect(issue.severity, QuestionIssueSeverity.error);
      expect(result.blocked, isTrue);
    });

    test('weak explanation produces warning only', () {
      final result = report(
        makeQuestion(
          explanation: 'The first option is best.',
        ),
      );

      final issue = issueFor(result, 'weak_explanation');

      expect(issue.field, 'explanation');
      expect(issue.severity, QuestionIssueSeverity.warning);
      expect(result.passed, isTrue);
      expect(result.blocked, isFalse);
    });

    test('missing reference produces blocking error', () {
      final result = report(
        makeQuestion(reference: ''),
      );

      final issue = issueFor(result, 'missing_reference');

      expect(issue.field, 'reference');
      expect(issue.severity, QuestionIssueSeverity.error);
      expect(result.blocked, isTrue);
    });

    test('insufficient tags produces warning only', () {
      final result = report(
        makeQuestion(tags: const []),
      );

      final issue = issueFor(result, 'insufficient_tags');

      expect(issue.field, 'tags');
      expect(issue.severity, QuestionIssueSeverity.warning);
      expect(result.passed, isTrue);
      expect(result.blocked, isFalse);
    });

    test('BEST answer uniquely longest produces warning', () {
      final result = report(
        makeQuestion(
          options: const [
            'Eliminate the hazard through a permanent engineering change '
                'that removes the exposure from the task.',
            'Tell workers to remain alert.',
            'Provide warning signs.',
            'Review the issue.',
          ],
        ),
      );

      expect(
        codes(result),
        contains('best_answer_length_bias'),
      );

      final issue = issueFor(result, 'best_answer_length_bias');

      expect(issue.field, 'options');
      expect(issue.severity, QuestionIssueSeverity.warning);
    });

    test('BEST answer tied for longest does not trigger length bias', () {
      final result = report(
        makeQuestion(
          options: const [
            'Eliminate the hazard from the task completely.',
            'Use engineering controls to isolate workers from the hazard.',
            'Provide warning signs around the work area.',
            'Ask workers to report the hazard again.',
          ],
        ),
      );

      expect(
        codes(result),
        isNot(contains('best_answer_length_bias')),
      );
    });

    test('option length imbalance produces warning', () {
      final result = report(
        makeQuestion(
          options: const [
            'Eliminate the hazard.',
            'Tell workers to remain continuously alert during every stage of the task.',
            'Provide additional warning signs around the work area.',
            'Ask workers to report the hazard during the next scheduled meeting.',
          ],
        ),
      );

      expect(
        codes(result),
        contains('option_length_imbalance'),
      );

      final issue = issueFor(result, 'option_length_imbalance');

      expect(issue.field, 'options');
      expect(issue.severity, QuestionIssueSeverity.warning);
    });

    test('answer-length checks can be disabled', () {
      const disabledValidator = QuestionQualityValidator(
        answerLengthCheckEnabled: false,
      );

      final question = makeQuestion(
        options: const [
          'Eliminate the hazard completely through permanent removal.',
          'Tell workers to remain alert.',
          'Provide warning signs.',
          'Review the issue later.',
        ],
      );

      final result = disabledValidator.validateReport(question);
      final resultCodes = result.issues.map((issue) => issue.code);

      expect(
        resultCodes,
        isNot(contains('best_answer_length_bias')),
      );
      expect(
        resultCodes,
        isNot(contains('option_length_imbalance')),
      );
    });

    test('warning-only report passes', () {
      final result = report(
        makeQuestion(
          question: 'Which control should be selected first?',
          explanation: 'The first option is preferred.',
          tags: const [],
        ),
      );

      expect(result.errors, isEmpty);
      expect(result.errorCount, 0);
      expect(result.warningCount, greaterThan(0));
      expect(result.passed, isTrue);
      expect(result.blocked, isFalse);
      expect(result.summary, contains('PASSED'));
    });

    test('error report blocks', () {
      final result = report(
        makeQuestion(
          questionType: 'direct_mcq',
        ),
      );

      expect(result.errors, isNotEmpty);
      expect(result.errorCount, greaterThan(0));
      expect(result.passed, isFalse);
      expect(result.blocked, isTrue);
      expect(result.summary, contains('BLOCKED'));
    });

    test('multiple errors are reported together', () {
      final result = report(
        makeQuestion(
          question: '',
          options: const [],
          correctAnswer: -1,
          explanation: '',
          reference: '',
          difficulty: 'easy',
          cognitiveLevel: 'knowledge',
          questionType: 'direct_mcq',
        ),
      );

      final resultCodes = codes(result);

      expect(result.errorCount, greaterThan(1));
      expect(result.passed, isFalse);
      expect(result.blocked, isTrue);

      expect(resultCodes, contains('invalid_question_type'));
      expect(resultCodes, contains('invalid_cognitive_level'));
      expect(resultCodes, contains('invalid_difficulty'));
      expect(resultCodes, contains('missing_question_stem'));
      expect(resultCodes, contains('invalid_option_count'));
      expect(resultCodes, contains('missing_explanation'));
      expect(resultCodes, contains('missing_reference'));
    });

    test('mixed errors and warnings remain blocked by errors', () {
      final result = report(
        makeQuestion(
          question: 'Which control should be selected?',
          explanation: 'Use this control.',
          reference: '',
          tags: const [],
        ),
      );

      expect(result.errors, isNotEmpty);
      expect(result.warnings, isNotEmpty);
      expect(result.passed, isFalse);
      expect(result.blocked, isTrue);
      expect(result.errorCount, greaterThan(0));
      expect(result.warningCount, greaterThan(0));
    });

    test('issue ordering follows the frozen CSP11 structure', () {
      final result = report(
        makeQuestion(
          questionType: 'wrong_type',
          cognitiveLevel: 'knowledge',
          difficulty: 'easy',
          question: '',
          options: const [],
          correctAnswer: -1,
          explanation: '',
          reference: '',
          tags: const [],
        ),
      );

      final resultCodes = codes(result);

      expect(
        resultCodes,
        equals([
          'invalid_question_type',
          'invalid_cognitive_level',
          'invalid_difficulty',
          'missing_question_stem',
          'invalid_option_count',
          'missing_explanation',
          'missing_reference',
          'insufficient_tags',
        ]),
      );
    });

    test('issue ordering remains deterministic across repeated validation', () {
      final question = makeQuestion(
        questionType: 'wrong_type',
        cognitiveLevel: 'knowledge',
        difficulty: 'easy',
        question: '',
        options: const [],
        correctAnswer: -1,
        explanation: '',
        reference: '',
        tags: const [],
      );

      final first = report(question);
      final second = report(question);

      expect(
        first.issues.map((issue) => issue.code).toList(),
        equals(second.issues.map((issue) => issue.code).toList()),
      );

      expect(
        first.issues.map((issue) => issue.field).toList(),
        equals(second.issues.map((issue) => issue.field).toList()),
      );

      expect(
        first.issues.map((issue) => issue.severity).toList(),
        equals(second.issues.map((issue) => issue.severity).toList()),
      );
    });

    test('no duplicate issue codes are emitted in one validation run', () {
      final result = report(
        makeQuestion(
          question: '',
          options: const [],
          explanation: '',
          reference: '',
          tags: const [],
        ),
      );

      final resultCodes = codes(result);

      expect(
        resultCodes.toSet().length,
        resultCodes.length,
      );
    });

    test('malformed empty input does not crash', () {
      expect(
        () => report(
          makeQuestion(
            question: '',
            options: const [],
            correctAnswer: -1,
            explanation: '',
            reference: '',
            tags: const [],
          ),
        ),
        returnsNormally,
      );
    });

    test('malformed fewer-than-four options does not crash', () {
      expect(
        () => report(
          makeQuestion(
            options: const ['Only one option'],
            correctAnswer: 0,
          ),
        ),
        returnsNormally,
      );
    });

    test('malformed more-than-four options does not crash', () {
      expect(
        () => report(
          makeQuestion(
            options: const [
              'Option one',
              'Option two',
              'Option three',
              'Option four',
              'Option five',
            ],
          ),
        ),
        returnsNormally,
      );
    });

    test('malformed out-of-range BEST answer does not crash', () {
      expect(
        () => report(
          makeQuestion(
            correctAnswer: 99,
          ),
        ),
        returnsNormally,
      );
    });

    test('empty tags do not crash', () {
      expect(
        () => report(
          makeQuestion(tags: const []),
        ),
        returnsNormally,
      );
    });

    test('duplicate options do not crash', () {
      expect(
        () => report(
          makeQuestion(
            options: const [
              'Same answer',
              'Same answer',
              'Another answer',
              'Final answer',
            ],
          ),
        ),
        returnsNormally,
      );
    });

    test('unexpected capitalization is handled safely for cognitive level', () {
      final result = report(
        makeQuestion(cognitiveLevel: 'APPLICATION'),
      );

      expect(
        codes(result),
        isNot(contains('invalid_cognitive_level')),
      );
    });

    test('unexpected capitalization is handled safely for difficulty', () {
      final result = report(
        makeQuestion(difficulty: 'HARD'),
      );

      expect(
        codes(result),
        isNot(contains('invalid_difficulty')),
      );
    });

    test('unexpected capitalization behavior for question type is deterministic', () {
      final question = makeQuestion(
        questionType: 'SCENARIO_MCQ',
      );

      final first = report(question);
      final second = report(question);

      expect(
        codes(first),
        equals(codes(second)),
      );
    });

    test('all emitted issue codes belong to the frozen H0.3 vocabulary', () {
      const allowedCodes = {
        'invalid_question_type',
        'invalid_cognitive_level',
        'invalid_difficulty',
        'missing_question_stem',
        'invalid_option_count',
        'empty_answer_option',
        'duplicate_answer_option',
        'invalid_correct_answer',
        'missing_explanation',
        'missing_reference',
        'weak_question_stem',
        'best_answer_length_bias',
        'option_length_imbalance',
        'weak_explanation',
        'insufficient_tags',
      };

      final questions = <Question>[
        makeQuestion(questionType: 'wrong'),
        makeQuestion(cognitiveLevel: 'wrong'),
        makeQuestion(difficulty: 'wrong'),
        makeQuestion(question: ''),
        makeQuestion(options: const []),
        makeQuestion(
          options: const [
            'Same',
            'Same',
            'Third',
            'Fourth',
          ],
        ),
        makeQuestion(explanation: ''),
        makeQuestion(reference: ''),
        makeQuestion(tags: const []),
      ];

      for (final question in questions) {
        final result = report(question);

        for (final issue in result.issues) {
          expect(allowedCodes, contains(issue.code));
        }
      }
    });

    test('issue field mapping and severity are correct for every frozen code', () {
      final result = report(
        makeQuestion(
          questionType: 'wrong',
          cognitiveLevel: 'wrong',
          difficulty: 'wrong',
          question: '',
          options: const [
            'Same answer',
            'Same answer',
            '',
            'Final answer',
          ],
          correctAnswer: 99,
          explanation: '',
          reference: '',
          tags: const [],
        ),
      );

      final expectedErrors = {
        'invalid_question_type': ['questionType', QuestionIssueSeverity.error],
        'invalid_cognitive_level': [
          'cognitiveLevel',
          QuestionIssueSeverity.error,
        ],
        'invalid_difficulty': ['difficulty', QuestionIssueSeverity.error],
        'missing_question_stem': ['question', QuestionIssueSeverity.error],
        'empty_answer_option': ['options', QuestionIssueSeverity.error],
        'duplicate_answer_option': [
          'options',
          QuestionIssueSeverity.error,
        ],
        'invalid_correct_answer': [
          'correctAnswer',
          QuestionIssueSeverity.error,
        ],
        'missing_explanation': [
          'explanation',
          QuestionIssueSeverity.error,
        ],
        'missing_reference': [
          'reference',
          QuestionIssueSeverity.error,
        ],
        'insufficient_tags': [
          'tags',
          QuestionIssueSeverity.warning,
        ],
      };

      for (final entry in expectedErrors.entries) {
        final issue = issueFor(result, entry.key);

        expect(issue.field, entry.value[0]);
        expect(issue.severity, entry.value[1]);
      }
    });
  });
}
