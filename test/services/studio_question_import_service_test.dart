import 'package:flutter_test/flutter_test.dart';

import 'package:exam_platform/models/study_content.dart';
import 'package:exam_platform/services/studio/studio_question_import_service.dart';

void main() {
  const importer = StudioQuestionImportService();

  final content = StudyContent(
    id: 'd07_c03-v1',
    domainId: 'domain_07',
    competencyId: 'd07_c03',
    competencyNumber: 3,
    title: 'Continuous Improvement',
    status: 'draft',
    version: 1,
    topics: [
      StudyTopic(
        id: 'd07_c03_t01',
        title: 'Continuous Improvement',
        subtopics: [
          StudySubtopic(
            id: 'd07_c03_01',
            title: 'Continuous Improvement',
            learningObjectives: [],
            blocks: [],
            keyPoints: [],
            examples: [],
            caseStudies: [],
            formulas: [],
            references: [],
            examTips: [],
            commonMistakes: [],
            keyTakeaways: [],
            quizzes: [],
          ),
        ],
      ),
    ],
  );

  test('JSON import attaches Studio context and creates Draft questions', () {
    final questions = importer.fromJsonText(
      input: '''{
        "questions": [
          {
            "question": "A safety manager must choose the most appropriate action after identifying a recurring control failure during an audit.",
            "options": ["Option A", "Option B", "Option C", "Option D"],
            "correctAnswer": "C",
            "explanation": "The selected action addresses the underlying control failure and provides a sustainable improvement rather than only treating the immediate symptom.",
            "reference": "CSP11 study reference",
            "tags": ["audit", "continuous improvement"]
          }
        ]
      }''',
      nextId: () => 1001,
      content: content,
      topic: content.topics.first,
      subtopic: content.topics.first.subtopics.first,
      quizId: 'd07_c03-v1_d07_c03_01_quiz',
    );

    expect(questions, hasLength(1));
    expect(questions.first.id, 1001);
    expect(questions.first.competencyId, 'd07_c03');
    expect(questions.first.subtopicId, 'd07_c03_01');
    expect(questions.first.quizId, 'd07_c03-v1_d07_c03_01_quiz');
    expect(questions.first.contentPackageId, 'd07_c03-v1');
    expect(questions.first.correctAnswer, 2);
    expect(questions.first.status, 'draft');
  });

  test('JSON import accepts a top-level array', () {
    final questions = importer.fromJsonText(
      input: '''[
        {
          "question": "A manager reviews a recurring incident pattern and needs to select the strongest improvement action for the system.",
          "options": ["One", "Two", "Three", "Four"],
          "bestAnswer": "A",
          "explanation": "The first option addresses the system issue and supports a sustained improvement approach rather than a temporary correction.",
          "reference": "CSP11 reference",
          "tags": "systems, improvement"
        }
      ]''',
      nextId: () => 1002,
      content: content,
      topic: content.topics.first,
      subtopic: content.topics.first.subtopics.first,
      quizId: 'd07_c03-v1_d07_c03_01_quiz',
    );

    expect(questions.single.correctAnswer, 0);
    expect(questions.single.tags, contains('systems'));
  });

  test(
    'JSON import supports best_answer_rationale and snake_case metadata',
    () {
      final questions = importer.fromJsonText(
        input: '''{
        "questions": [
          {
            "stem": "A supervisor identifies a recurring weakness in a safety control and must select the strongest response.",
            "options": ["One", "Two", "Three", "Four"],
            "correct_answer": "1",
            "bestAnswerRationale": "The selected response addresses the underlying weakness.",
            "explanation": "The response targets the underlying control weakness rather than only the immediate symptom.",
            "source": "CSP11 reference",
            "cognitive_level": "analysis",
            "question_type": "scenario_mcq",
            "tags": ["control", "analysis"]
          }
        ]
      }''',
        nextId: () => 1003,
        content: content,
        topic: content.topics.first,
        subtopic: content.topics.first.subtopics.first,
        quizId: 'd07_c03-v1_d07_c03_01_quiz',
      );

      final question = questions.single;

      expect(question.id, 1003);
      expect(question.correctAnswer, 1);
      expect(
        question.bestAnswerRationale,
        'The selected response addresses the underlying weakness.',
      );
      expect(question.reference, 'CSP11 reference');
      expect(question.cognitiveLevel, 'analysis');
      expect(question.questionType, 'scenario_mcq');
      expect(question.status, 'draft');
    },
  );

  test('JSON metadata cannot override the active Studio context', () {
    expect(
      () => importer.fromJsonText(
        input: '''{
          "question": "A manager must choose the strongest action for a recurring safety-system weakness.",
          "domain": 1,
          "domainId": "domain_01",
          "competencyId": "wrong_competency",
          "subtopicId": "wrong_subtopic",
          "quizId": "wrong_quiz",
          "contentPackageId": "wrong_package",
          "options": ["One", "Two", "Three", "Four"],
          "correctAnswer": 1,
          "explanation": "The selected action addresses the underlying weakness.",
          "tags": ["safety", "controls"]
        }''',
        nextId: () => 1004,
        content: content,
        topic: content.topics.first,
        subtopic: content.topics.first.subtopics.first,
        quizId: 'd07_c03-v1_d07_c03_01_quiz',
      ),
      throwsFormatException,
    );
  });

  test('JSON import rejects an empty question collection', () {
    expect(
      () => importer.fromJsonText(
        input: '{"questions": []}',
        nextId: () => 1005,
        content: content,
        topic: content.topics.first,
        subtopic: content.topics.first.subtopics.first,
        quizId: 'd07_c03-v1_d07_c03_01_quiz',
      ),
      throwsFormatException,
    );
  });
  test('JSON nested context is accepted when it matches selected subtopic', () {
    var id = 2000;

    final questions = importer.fromJsonText(
      input: '''{
        "context": {
          "domainId": "d07",
          "competencyId": "d07_c03",
          "topicId": "d07_c03_t01",
          "subtopicId": "d07_c03_01",
          "quizId": "d07_c03-v1_d07_c03_01_quiz",
          "contentPackageId": "d07_c03-v1"
        },
        "questions": [
          {
            "question": "A trainer must select a delivery method that best matches a defined learning outcome and workplace transfer need.",
            "options": ["One", "Two", "Three", "Four"],
            "correctAnswer": "A",
            "explanation": "The selected method best aligns the objective with practice and transfer requirements.",
            "reference": "CSP11 training reference",
            "tags": ["training methods", "method selection"]
          }
        ]
      }''',
      nextId: () => ++id,
      content: content,
      topic: content.topics.first,
      subtopic: content.topics.first.subtopics.first,
      quizId: 'd07_c03-v1_d07_c03_01_quiz',
    );

    expect(questions, hasLength(1));
    expect(questions.single.subtopicId, 'd07_c03_01');
  });

  test('JSON context mismatch is rejected before questions are created', () {
    expect(
      () => importer.fromJsonText(
        input: '''{
          "context": {
            "competencyId": "d07_c03",
            "topicId": "d07_c03_t01",
            "subtopicId": "d07_c03_99"
          },
          "questions": [
            {
              "question": "A trainer selects a method for a practical task.",
              "options": ["One", "Two", "Three", "Four"],
              "correctAnswer": "A",
              "explanation": "Explanation.",
              "reference": "Reference.",
              "tags": ["training", "methods"]
            }
          ]
        }''',
        nextId: () => 3001,
        content: content,
        topic: content.topics.first,
        subtopic: content.topics.first.subtopics.first,
        quizId: 'd07_c03-v1_d07_c03_01_quiz',
      ),
      throwsFormatException,
    );
  });

  test('JSON import rejects duplicate normalized question stems', () {
    var id = 4000;

    expect(
      () => importer.fromJsonText(
        input: '''{
          "questions": [
            {
              "question": "Which training method BEST fits this scenario?",
              "options": ["One", "Two", "Three", "Four"],
              "correctAnswer": "A",
              "explanation": "Explanation.",
              "reference": "Reference.",
              "tags": ["training", "methods"]
            },
            {
              "question": "which training method best fits this scenario",
              "options": ["One", "Two", "Three", "Four"],
              "correctAnswer": "A",
              "explanation": "Explanation.",
              "reference": "Reference.",
              "tags": ["training", "methods"]
            }
          ]
        }''',
        nextId: () => ++id,
        content: content,
        topic: content.topics.first,
        subtopic: content.topics.first.subtopics.first,
        quizId: 'd07_c03-v1_d07_c03_01_quiz',
      ),
      throwsFormatException,
    );
  });
}
