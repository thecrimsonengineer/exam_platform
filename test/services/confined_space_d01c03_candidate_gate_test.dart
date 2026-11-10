import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:exam_platform/models/question.dart';
import 'package:exam_platform/services/question_quality_validator.dart';
import 'package:exam_platform/services/questions/canonical_question_parser.dart';

void main() {
  test('confined-space D01-C03 candidates pass every H0.3 check', () {
    final source = File(
      'content/question_candidates/confined_space_d01c03_10_studio_import.json',
    ).readAsStringSync();
    final drafts = const CanonicalQuestionParser().fromJsonText(source);

    expect(drafts, hasLength(10));
    final answerPositions = <int>{};

    for (var index = 0; index < drafts.length; index++) {
      final draft = drafts[index];
      final question = Question(
        id: 110100 + index,
        domain: 1,
        competencyId: 'd01_c03',
        topicId: '',
        subtopicId: 'confined_space',
        quizId: 'confined_space_candidate_review',
        contentPackageId: 'csp11-confined-space-d01c03-20261110-v1',
        question: draft.question,
        options: draft.options,
        correctAnswer: draft.correctAnswer,
        explanation: draft.explanation,
        bestAnswerRationale: draft.bestAnswerRationale,
        reference: draft.reference,
        difficulty: draft.difficulty,
        cognitiveLevel: draft.cognitiveLevel,
        questionType: draft.questionType,
        status: 'draft',
        version: draft.version,
        tags: draft.tags,
      );

      expect(
        draft.question.length,
        inInclusiveRange(90, 255),
        reason: 'Question ${index + 1}: enforce editorial stem bounds',
      );
      expect(
        draft.explanation.length,
        greaterThanOrEqualTo(80),
        reason: 'Question ${index + 1}: explanation depth',
      );

      final report = const QuestionQualityValidator().validateReport(question);
      expect(
        report.issues,
        isEmpty,
        reason: 'Question ${index + 1}: '
            '${report.issues.map((issue) => issue.code).join(', ')}',
      );

      answerPositions.add(draft.correctAnswer);
    }

    expect(
      answerPositions,
      equals(<int>{0, 1, 2, 3}),
      reason: 'Avoid answer-location cueing across this batch',
    );
  });
}
