import 'dart:convert';

import 'package:exam_platform/features/exam_readiness/models/learner_assessment_attempt.dart';
import 'package:exam_platform/features/exam_readiness/repositories/evidence_snapshot_repository.dart';
import 'package:exam_platform/features/exam_readiness/repositories/learner_assessment_attempt_repository.dart';
import 'package:exam_platform/features/exam_readiness/services/readiness_evidence_bootstrap_service.dart';
import 'package:exam_platform/models/student_question_progress.dart';
import 'package:exam_platform/services/student_question_progress_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

StudentQuestionProgress _legacyProgress({
  required int questionId,
  required bool correct,
  DateTime? answeredAt,
}) {
  final at = answeredAt ?? DateTime(2026, 9, 10, 12);
  return StudentQuestionProgress(
    questionId: questionId,
    domainNumber: 3,
    competencyId: 'd03_c02',
    topicId: 'topic-1',
    subtopicId: 'subtopic-$questionId',
    attemptCount: 4,
    lastCorrect: correct,
    everCorrect: true,
    firstAnsweredAt: at.subtract(const Duration(days: 20)),
    lastAnsweredAt: at,
  );
}

Future<void> _seedLegacyProgress(
  List<StudentQuestionProgress> records,
) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    StudentQuestionProgressService.storageKeyForUser('u1'),
    jsonEncode({
      for (final record in records)
        record.questionId.toString(): record.toJson(),
    }),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('legacy question progress is bridged into readiness evidence once', () async {
    await _seedLegacyProgress([
      _legacyProgress(questionId: 101, correct: true),
      _legacyProgress(questionId: 102, correct: false),
      _legacyProgress(questionId: 103, correct: true),
    ]);

    const service = ReadinessEvidenceBootstrapService();
    final evidenceRepository = EvidenceSnapshotRepository(
      userIdOverride: 'u1',
    );
    const attemptRepository = LearnerAssessmentAttemptRepository(
      userIdOverride: 'u1',
    );
    const progressService = StudentQuestionProgressService(
      userIdOverride: 'u1',
    );

    final first = await service.rebuildLocal(
      evidenceRepository: evidenceRepository,
      attemptRepository: attemptRepository,
      questionProgressService: progressService,
      now: DateTime(2026, 9, 18, 12),
    );

    expect(first.importedLegacyQuestionCount, 3);
    expect(first.attempts, hasLength(3));
    expect(first.evidenceByCompetency['d03_c02']?.sourceAttemptCount, 3);
    expect(
      first.attempts.every(
        (attempt) => attempt.sessionKind == 'legacy_progress_bridge',
      ),
      isTrue,
    );

    final second = await service.rebuildLocal(
      evidenceRepository: evidenceRepository,
      attemptRepository: attemptRepository,
      questionProgressService: progressService,
      now: DateTime(2026, 9, 18, 12, 5),
    );

    expect(second.importedLegacyQuestionCount, 0);
    expect(second.attempts, hasLength(3));
    expect(second.evidenceByCompetency['d03_c02']?.sourceAttemptCount, 3);
  });

  test('real M7 attempt prevents duplicate legacy bridge for same question', () async {
    await _seedLegacyProgress([
      _legacyProgress(questionId: 101, correct: true),
    ]);

    const attemptRepository = LearnerAssessmentAttemptRepository(
      userIdOverride: 'u1',
    );
    await attemptRepository.append(
      LearnerAssessmentAttempt(
        attemptId: 'real-101',
        questionId: 101,
        domainNumber: 3,
        competencyId: 'd03_c02',
        topicId: 'topic-1',
        subtopicId: 'subtopic-101',
        correct: true,
        answeredAt: DateTime(2026, 9, 12, 12),
        cognitiveLevel: 'application',
        questionType: 'scenario_mcq',
        difficultyLane: AttemptDifficultyLane.hard,
        publishedAtAttempt: true,
        questionVersion: 1,
        sessionKind: 'practice',
      ),
    );

    const service = ReadinessEvidenceBootstrapService();
    final result = await service.rebuildLocal(
      evidenceRepository: EvidenceSnapshotRepository(userIdOverride: 'u1'),
      attemptRepository: attemptRepository,
      questionProgressService:
          const StudentQuestionProgressService(userIdOverride: 'u1'),
      now: DateTime(2026, 9, 18, 12),
    );

    expect(result.importedLegacyQuestionCount, 0);
    expect(result.attempts, hasLength(1));
    expect(result.attempts.single.attemptId, 'real-101');
  });
}
