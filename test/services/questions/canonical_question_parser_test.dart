import 'package:flutter_test/flutter_test.dart';

import 'package:exam_platform/services/questions/canonical_question_parser.dart';

void main() {
  const parser = CanonicalQuestionParser();

  test('parses canonical fields without Study or LAB context', () {
    final questions = parser.fromJsonText('''{
      "questions": [
        {
          "stem": "A safety professional reviews a recurring control weakness and must choose the strongest system response before work continues.",
          "options": ["One", "Two", "Three", "Four"],
          "correct_answer": "C",
          "best_answer_rationale": "The selected response closes the material control gap.",
          "explanation": "The selected response addresses the underlying system weakness rather than only treating the immediate symptom.",
          "source": "CSP11 authoritative reference",
          "difficulty": "Hard",
          "cognitive_level": "Analysis",
          "question_type": "scenario_mcq",
          "version": 3,
          "tags": ["controls", "systems"]
        }
      ]
    }''');

    final question = questions.single;

    expect(question.question, startsWith('A safety professional'));
    expect(question.options, ['One', 'Two', 'Three', 'Four']);
    expect(question.correctAnswer, 2);
    expect(
      question.bestAnswerRationale,
      'The selected response closes the material control gap.',
    );
    expect(question.reference, 'CSP11 authoritative reference');
    expect(question.difficulty, 'Hard');
    expect(question.cognitiveLevel, 'Analysis');
    expect(question.questionType, 'scenario_mcq');
    expect(question.version, 3);
    expect(question.tags, ['controls', 'systems']);
  });

  test('accepts top-level arrays and string tags', () {
    final questions = parser.fromJsonText('''[
      {
        "question": "A manager must choose the most appropriate corrective action after identifying a persistent weakness in a critical control.",
        "options": ["One", "Two", "Three", "Four"],
        "bestAnswer": "A",
        "explanation": "The first action addresses the persistent weakness through a system-level correction and verification.",
        "reference": "Reference",
        "tags": "critical controls; corrective action"
      }
    ]''');

    expect(questions, hasLength(1));
    expect(questions.single.correctAnswer, 0);
    expect(questions.single.tags, ['critical controls', 'corrective action']);
  });

  test('preserves established defaults and integer answer semantics', () {
    final question = parser.fromDecoded({
      'question':
          'A supervisor must select the strongest action after a change creates uncertainty about an existing workplace control.',
      'options': ['One', 'Two', 'Three', 'Four'],
      'correctAnswer': 1,
      'explanation':
          'The selected action resolves the uncertainty before exposure is allowed to continue under the changed condition.',
      'reference': 'Reference',
      'tags': ['change', 'controls'],
    }).single;

    expect(question.correctAnswer, 1);
    expect(question.difficulty, 'Hard');
    expect(question.cognitiveLevel, 'analysis');
    expect(question.questionType, 'scenario_mcq');
    expect(question.version, 1);
  });

  test('accepts an exact option value as the BEST answer', () {
    final question = parser.fromDecoded({
      'question':
          'A competent person must choose the strongest response after field conditions no longer match the original work plan.',
      'options': ['Stop and verify', 'Continue', 'Observe', 'Escalate later'],
      'correctAnswer': 'Stop and verify',
      'explanation':
          'Stopping and verifying the changed condition restores a reliable basis before the work is allowed to continue.',
      'reference': 'Reference',
      'tags': ['field change', 'verification'],
    }).single;

    expect(question.correctAnswer, 0);
  });

  test('rejects an empty question collection', () {
    expect(
      () => parser.fromJsonText('{"questions": []}'),
      throwsFormatException,
    );
  });

  test('rejects unsupported JSON roots', () {
    expect(
      () => parser.fromJsonText('"not a question object"'),
      throwsFormatException,
    );
  });

  test('rejects duplicate normalized question stems', () {
    expect(
      () => parser.fromDecoded({
        'questions': [
          {
            'question': 'Which control BEST fits this scenario?',
            'options': ['One', 'Two', 'Three', 'Four'],
            'correctAnswer': 'A',
          },
          {
            'question': 'which control best fits this scenario',
            'options': ['One', 'Two', 'Three', 'Four'],
            'correctAnswer': 'A',
          },
        ],
      }),
      throwsFormatException,
    );
  });

  test('normalizes duplicate-stem punctuation consistently', () {
    expect(
      parser.normalizedQuestionStem(
        '  Which control BEST fits this scenario? ',
      ),
      'which control best fits this scenario',
    );
  });
}
