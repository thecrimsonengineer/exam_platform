import 'package:exam_platform/features/exam_readiness/models/learner_assessment_attempt.dart';
import 'package:exam_platform/services/ultra_hard_question_contract.dart';
import 'package:flutter_test/flutter_test.dart';

import '_support/m7b_fixture.dart';

void main() {
  group('M7B LearnerAssessmentAttempt', () {
    test('creates canonical attempt from published question', () {
      final attempt = LearnerAssessmentAttempt.fromQuestion(
        question: m7bQuestion(),
        correct: true,
        answeredAt: DateTime(2026, 9, 18, 10),
        attemptId: 'a1',
      );

      expect(attempt.attemptId, 'a1');
      expect(attempt.questionId, 1);
      expect(attempt.competencyId, 'd03_c02');
      expect(attempt.publishedAtAttempt, isTrue);
    });

    test('normalizes competency ID to lowercase', () {
      final attempt = LearnerAssessmentAttempt.fromQuestion(
        question: m7bQuestion(competencyId: 'D03_C02'),
        correct: true,
        answeredAt: DateTime(2026, 9, 18),
        attemptId: 'a1',
      );

      expect(attempt.competencyId, 'd03_c02');
    });

    test('marks draft question as unpublished evidence', () {
      final attempt = LearnerAssessmentAttempt.fromQuestion(
        question: m7bQuestion(status: 'draft'),
        correct: true,
        answeredAt: DateTime(2026, 9, 18),
        attemptId: 'a1',
      );

      expect(attempt.publishedAtAttempt, isFalse);
    });

    test('classifies ordinary Hard as hard lane', () {
      final attempt = LearnerAssessmentAttempt.fromQuestion(
        question: m7bQuestion(difficulty: 'Hard'),
        correct: true,
        answeredAt: DateTime(2026, 9, 18),
        attemptId: 'a1',
      );

      expect(attempt.difficultyLane, AttemptDifficultyLane.hard);
    });

    test('classifies standard difficulty as standard lane', () {
      final attempt = LearnerAssessmentAttempt.fromQuestion(
        question: m7bQuestion(difficulty: 'Standard'),
        correct: true,
        answeredAt: DateTime(2026, 9, 18),
        attemptId: 'a1',
      );

      expect(attempt.difficultyLane, AttemptDifficultyLane.standard);
    });

    test('Ultra Hard tag overrides ordinary difficulty text', () {
      final attempt = LearnerAssessmentAttempt.fromQuestion(
        question: m7bQuestion(
          difficulty: 'Hard',
          tags: const [UltraHardQuestionContract.classificationTag],
        ),
        correct: true,
        answeredAt: DateTime(2026, 9, 18),
        attemptId: 'a1',
      );

      expect(attempt.difficultyLane, AttemptDifficultyLane.ultraHard);
    });

    test('Ultra Hard classification is case-insensitive', () {
      final attempt = LearnerAssessmentAttempt.fromQuestion(
        question: m7bQuestion(
          tags: const ['ULTRA-HARD-DQG300'],
        ),
        correct: true,
        answeredAt: DateTime(2026, 9, 18),
        attemptId: 'a1',
      );

      expect(attempt.difficultyLane, AttemptDifficultyLane.ultraHard);
    });

    test('does not infer Ultra Hard from Hard wording alone', () {
      final attempt = LearnerAssessmentAttempt.fromQuestion(
        question: m7bQuestion(tags: const ['expert']),
        correct: true,
        answeredAt: DateTime(2026, 9, 18),
        attemptId: 'a1',
      );

      expect(attempt.difficultyLane, isNot(AttemptDifficultyLane.ultraHard));
    });

    test('preserves learner confidence sample', () {
      final attempt = LearnerAssessmentAttempt.fromQuestion(
        question: m7bQuestion(),
        correct: false,
        answeredAt: DateTime(2026, 9, 18),
        attemptId: 'a1',
        confidence: LearnerConfidenceLevel.high,
      );

      expect(attempt.confidence, LearnerConfidenceLevel.high);
    });

    test('confidence is optional', () {
      final attempt = LearnerAssessmentAttempt.fromQuestion(
        question: m7bQuestion(),
        correct: true,
        answeredAt: DateTime(2026, 9, 18),
        attemptId: 'a1',
      );

      expect(attempt.confidence, isNull);
    });

    test('preserves session kind', () {
      final attempt = LearnerAssessmentAttempt.fromQuestion(
        question: m7bQuestion(),
        correct: true,
        answeredAt: DateTime(2026, 9, 18),
        attemptId: 'a1',
        sessionKind: 'diagnostic',
      );

      expect(attempt.sessionKind, 'diagnostic');
    });

    test('blank session kind falls back to practice', () {
      final attempt = LearnerAssessmentAttempt.fromQuestion(
        question: m7bQuestion(),
        correct: true,
        answeredAt: DateTime(2026, 9, 18),
        attemptId: 'a1',
        sessionKind: '   ',
      );

      expect(attempt.sessionKind, 'practice');
    });

    test('preserves question version at attempt time', () {
      final attempt = LearnerAssessmentAttempt.fromQuestion(
        question: m7bQuestion(),
        correct: true,
        answeredAt: DateTime(2026, 9, 18),
        attemptId: 'a1',
      );

      expect(attempt.questionVersion, 2);
    });

    test('preserves question hierarchy snapshot', () {
      final attempt = LearnerAssessmentAttempt.fromQuestion(
        question: m7bQuestion(topicId: 't4', subtopicId: 's8'),
        correct: true,
        answeredAt: DateTime(2026, 9, 18),
        attemptId: 'a1',
      );

      expect(attempt.topicId, 't4');
      expect(attempt.subtopicId, 's8');
    });

    test('preserves correctness true', () {
      final attempt = LearnerAssessmentAttempt.fromQuestion(
        question: m7bQuestion(),
        correct: true,
        answeredAt: DateTime(2026, 9, 18),
        attemptId: 'a1',
      );

      expect(attempt.correct, isTrue);
    });

    test('preserves correctness false', () {
      final attempt = LearnerAssessmentAttempt.fromQuestion(
        question: m7bQuestion(),
        correct: false,
        answeredAt: DateTime(2026, 9, 18),
        attemptId: 'a1',
      );

      expect(attempt.correct, isFalse);
    });

    test('recognizes canonical competency identifier', () {
      expect(m7bAttempt().hasCanonicalCompetencyId, isTrue);
    });

    test('rejects malformed competency identifier shape', () {
      expect(
        m7bAttempt(competencyId: 'domain3-competency2')
            .hasCanonicalCompetencyId,
        isFalse,
      );
    });

    test('round trips through JSON', () {
      final original = m7bAttempt(
        attemptId: 'round-trip',
        confidence: LearnerConfidenceLevel.medium,
        difficultyLane: AttemptDifficultyLane.ultraHard,
      );

      final decoded = LearnerAssessmentAttempt.fromJson(original.toJson());

      expect(decoded.attemptId, original.attemptId);
      expect(decoded.questionId, original.questionId);
      expect(decoded.difficultyLane, original.difficultyLane);
      expect(decoded.confidence, original.confidence);
      expect(decoded.answeredAt, original.answeredAt);
    });

    test('fromJson rejects invalid timestamp', () {
      final json = m7bAttempt().toJson()..['answeredAt'] = 'broken';

      expect(
        () => LearnerAssessmentAttempt.fromJson(json),
        throwsFormatException,
      );
    });

    test('fromJson unknown difficulty defaults to standard', () {
      final json = m7bAttempt().toJson()..['difficultyLane'] = 'mystery';

      final decoded = LearnerAssessmentAttempt.fromJson(json);

      expect(decoded.difficultyLane, AttemptDifficultyLane.standard);
    });

    test('fromJson unknown confidence becomes null', () {
      final json = m7bAttempt().toJson()..['confidence'] = 'absolute';

      final decoded = LearnerAssessmentAttempt.fromJson(json);

      expect(decoded.confidence, isNull);
    });

    test('fromJson missing question version falls back to one', () {
      final json = m7bAttempt().toJson()..remove('questionVersion');

      final decoded = LearnerAssessmentAttempt.fromJson(json);

      expect(decoded.questionVersion, 1);
    });

    test('fromQuestion retains cognitive level', () {
      final attempt = LearnerAssessmentAttempt.fromQuestion(
        question: m7bQuestion(cognitiveLevel: 'analysis'),
        correct: true,
        answeredAt: DateTime(2026, 9, 18),
        attemptId: 'a1',
      );

      expect(attempt.cognitiveLevel, 'analysis');
    });

    test('fromQuestion preserves scenario question type', () {
      final attempt = LearnerAssessmentAttempt.fromQuestion(
        question: m7bQuestion(),
        correct: true,
        answeredAt: DateTime(2026, 9, 18),
        attemptId: 'a1',
      );

      expect(attempt.questionType, 'scenario_mcq');
    });
  });
}
