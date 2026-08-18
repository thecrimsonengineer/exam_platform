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
    subtopics: [
      StudySubtopic(
        id: 'd07_c03_01',
        title: 'Continuous Improvement',
        learningObjectives: [],
        mainContent: [],
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
      subtopic: content.subtopics.first,
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
      subtopic: content.subtopics.first,
      quizId: 'd07_c03-v1_d07_c03_01_quiz',
    );

    expect(questions.single.correctAnswer, 0);
    expect(questions.single.tags, contains('systems'));
  });
}
