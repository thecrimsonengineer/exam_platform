import 'dart:convert';

import 'package:exam_platform/features/exam_readiness/models/competency_evidence_snapshot.dart';
import 'package:exam_platform/features/exam_readiness/models/learner_assessment_attempt.dart';
import 'package:exam_platform/features/exam_readiness/repositories/evidence_snapshot_repository.dart';
import 'package:exam_platform/features/exam_readiness/repositories/learner_assessment_attempt_repository.dart';
import 'package:exam_platform/features/exam_readiness/services/learner_evidence_aggregation_service.dart';
import 'package:exam_platform/services/auth/learner_local_identity.dart';
import 'package:exam_platform/services/student_question_progress_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '_support/m7b_fixture.dart';

class _FakeSnapshotRemote implements EvidenceSnapshotRemoteStore {
  List<CompetencyEvidenceSnapshot> values = [];
  int loadCalls = 0;
  int saveCalls = 0;
  String? lastUserId;

  @override
  Future<List<CompetencyEvidenceSnapshot>> loadAll(String userId) async {
    loadCalls++;
    lastUserId = userId;
    return List<CompetencyEvidenceSnapshot>.from(values);
  }

  @override
  Future<void> save({
    required String userId,
    required CompetencyEvidenceSnapshot snapshot,
  }) async {
    saveCalls++;
    lastUserId = userId;
    values.removeWhere((item) => item.competencyId == snapshot.competencyId);
    values.add(snapshot);
  }
}

CompetencyEvidenceSnapshot _snapshot({
  String competencyId = 'd03_c02',
  DateTime? generatedAt,
}) {
  return const LearnerEvidenceAggregationService().buildSnapshot(
    competencyId: competencyId,
    attempts: [m7bAttempt()],
    scope: m7bScope(competencyId: competencyId),
    now: generatedAt ?? DateTime(2026, 9, 18, 12),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LearnerLocalIdentity.activate('u1');
  });

  tearDown(LearnerLocalIdentity.clear);

  group('M7B LearnerAssessmentAttemptRepository', () {
    test('storage key is UID scoped', () {
      expect(
        LearnerAssessmentAttemptRepository.storageKeyForUser('u1'),
        'csp11.student.u1.exam_readiness.assessment_attempts.v1',
      );
    });

    test('empty ledger returns empty immutable view', () async {
      final repo = const LearnerAssessmentAttemptRepository(
        userIdOverride: 'u1',
      );

      expect(await repo.loadAll(), isEmpty);
    });

    test('append stores an attempt', () async {
      final repo = const LearnerAssessmentAttemptRepository(
        userIdOverride: 'u1',
      );

      expect(await repo.append(m7bAttempt()), isTrue);
      expect(await repo.loadAll(), hasLength(1));
    });

    test('duplicate attempt ID is ignored', () async {
      final repo = const LearnerAssessmentAttemptRepository(
        userIdOverride: 'u1',
      );

      expect(await repo.append(m7bAttempt(attemptId: 'same')), isTrue);
      expect(await repo.append(m7bAttempt(attemptId: 'same')), isFalse);
      expect(await repo.loadAll(), hasLength(1));
    });

    test('blank attempt ID is rejected', () async {
      final repo = const LearnerAssessmentAttemptRepository(
        userIdOverride: 'u1',
      );

      expect(await repo.append(m7bAttempt(attemptId: ' ')), isFalse);
    });

    test('non-positive question ID is rejected', () async {
      final repo = const LearnerAssessmentAttemptRepository(
        userIdOverride: 'u1',
      );

      expect(await repo.append(m7bAttempt(questionId: 0)), isFalse);
    });

    test('attempts load in chronological order', () async {
      final repo = const LearnerAssessmentAttemptRepository(
        userIdOverride: 'u1',
      );
      await repo.append(
        m7bAttempt(
          attemptId: 'later',
          answeredAt: DateTime(2026, 9, 18, 12),
        ),
      );
      await repo.append(
        m7bAttempt(
          attemptId: 'earlier',
          questionId: 2,
          answeredAt: DateTime(2026, 9, 18, 8),
        ),
      );

      final items = await repo.loadAll();

      expect(items.first.attemptId, 'earlier');
      expect(items.last.attemptId, 'later');
    });

    test('clear removes active learner ledger', () async {
      final repo = const LearnerAssessmentAttemptRepository(
        userIdOverride: 'u1',
      );
      await repo.append(m7bAttempt());

      await repo.clear();

      expect(await repo.loadAll(), isEmpty);
    });

    test('clearing one learner does not clear another learner', () async {
      final u1 = const LearnerAssessmentAttemptRepository(
        userIdOverride: 'u1',
      );
      final u2 = const LearnerAssessmentAttemptRepository(
        userIdOverride: 'u2',
      );
      await u1.append(m7bAttempt(attemptId: 'u1'));
      await u2.append(m7bAttempt(attemptId: 'u2'));

      await u1.clear();

      expect(await u1.loadAll(), isEmpty);
      expect(await u2.loadAll(), hasLength(1));
    });

    test('malformed root JSON fails soft', () async {
      SharedPreferences.setMockInitialValues({
        LearnerAssessmentAttemptRepository.storageKeyForUser('u1'): '{bad',
      });
      final repo = const LearnerAssessmentAttemptRepository(
        userIdOverride: 'u1',
      );

      expect(await repo.loadAll(), isEmpty);
    });

    test('malformed item is skipped without losing valid attempts', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        LearnerAssessmentAttemptRepository.storageKeyForUser('u1'),
        jsonEncode([
          {'broken': true},
          m7bAttempt(attemptId: 'good').toJson(),
        ]),
      );
      final repo = const LearnerAssessmentAttemptRepository(
        userIdOverride: 'u1',
      );

      final items = await repo.loadAll();

      expect(items, hasLength(1));
      expect(items.single.attemptId, 'good');
    });

    test('confidence and Ultra Hard lane survive local persistence', () async {
      final repo = const LearnerAssessmentAttemptRepository(
        userIdOverride: 'u1',
      );
      await repo.append(
        m7bAttempt(
          confidence: LearnerConfidenceLevel.high,
          difficultyLane: AttemptDifficultyLane.ultraHard,
        ),
      );

      final stored = (await repo.loadAll()).single;

      expect(stored.confidence, LearnerConfidenceLevel.high);
      expect(stored.difficultyLane, AttemptDifficultyLane.ultraHard);
    });
  });

  group('M7B EvidenceSnapshotRepository', () {
    test('storage key is UID scoped', () {
      expect(
        EvidenceSnapshotRepository.storageKeyForUser('u1'),
        'csp11.student.u1.exam_readiness.evidence_snapshots.v1',
      );
    });

    test('empty local snapshot store returns empty map', () async {
      final repo = EvidenceSnapshotRepository(userIdOverride: 'u1');

      expect(await repo.loadLocal(), isEmpty);
    });

    test('save persists canonical competency snapshot', () async {
      final repo = EvidenceSnapshotRepository(userIdOverride: 'u1');

      await repo.save(_snapshot(), syncRemote: false);

      expect((await repo.load('d03_c02'))?.competencyId, 'd03_c02');
    });

    test('save rejects non-canonical competency snapshot', () async {
      final repo = EvidenceSnapshotRepository(userIdOverride: 'u1');

      expect(
        () => repo.save(
          _snapshot(competencyId: 'bad'),
          syncRemote: false,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('save syncs remote when enabled', () async {
      final remote = _FakeSnapshotRemote();
      final repo = EvidenceSnapshotRepository(
        userIdOverride: 'u1',
        remoteStore: remote,
      );

      await repo.save(_snapshot());

      expect(remote.saveCalls, 1);
      expect(remote.lastUserId, 'u1');
    });

    test('save can remain local-only', () async {
      final remote = _FakeSnapshotRemote();
      final repo = EvidenceSnapshotRepository(
        userIdOverride: 'u1',
        remoteStore: remote,
      );

      await repo.save(_snapshot(), syncRemote: false);

      expect(remote.saveCalls, 0);
      expect(await repo.loadLocal(), hasLength(1));
    });

    test('refreshFromRemote replaces local snapshot view', () async {
      final remote = _FakeSnapshotRemote()
        ..values = [_snapshot(competencyId: 'd03_c02')];
      final repo = EvidenceSnapshotRepository(
        userIdOverride: 'u1',
        remoteStore: remote,
      );

      final values = await repo.refreshFromRemote();

      expect(values, hasLength(1));
      expect(remote.loadCalls, 1);
      expect(await repo.loadLocal(), hasLength(1));
    });

    test('refresh without remote store returns local snapshots', () async {
      final repo = EvidenceSnapshotRepository(userIdOverride: 'u1');
      await repo.save(_snapshot(), syncRemote: false);

      final values = await repo.refreshFromRemote();

      expect(values, hasLength(1));
    });

    test('load does not hit remote by default', () async {
      final remote = _FakeSnapshotRemote()
        ..values = [_snapshot(competencyId: 'd03_c02')];
      final repo = EvidenceSnapshotRepository(
        userIdOverride: 'u1',
        remoteStore: remote,
      );

      expect(await repo.load('d03_c02'), isNull);
      expect(remote.loadCalls, 0);
    });

    test('load refresh flag explicitly hits remote', () async {
      final remote = _FakeSnapshotRemote()
        ..values = [_snapshot(competencyId: 'd03_c02')];
      final repo = EvidenceSnapshotRepository(
        userIdOverride: 'u1',
        remoteStore: remote,
      );

      expect(
        (await repo.load('d03_c02', refreshRemote: true))?.competencyId,
        'd03_c02',
      );
      expect(remote.loadCalls, 1);
    });

    test('saveMany persists multiple competency snapshots', () async {
      final repo = EvidenceSnapshotRepository(userIdOverride: 'u1');

      await repo.saveMany(
        [
          _snapshot(competencyId: 'd03_c02'),
          _snapshot(competencyId: 'd01_c01'),
        ],
        syncRemote: false,
      );

      expect(await repo.loadLocal(), hasLength(2));
    });

    test('clearLocal clears only evidence snapshots', () async {
      final repo = EvidenceSnapshotRepository(userIdOverride: 'u1');
      await repo.save(_snapshot(), syncRemote: false);

      await repo.clearLocal();

      expect(await repo.loadLocal(), isEmpty);
    });

    test('malformed local snapshot root fails soft', () async {
      SharedPreferences.setMockInitialValues({
        EvidenceSnapshotRepository.storageKeyForUser('u1'): '[]',
      });
      final repo = EvidenceSnapshotRepository(userIdOverride: 'u1');

      expect(await repo.loadLocal(), isEmpty);
    });
  });

  group('M7B existing quiz persistence integration', () {
    test('recordAnswer also appends immutable assessment attempt', () async {
      final progress = const StudentQuestionProgressService(
        userIdOverride: 'u1',
      );
      final attempts = const LearnerAssessmentAttemptRepository(
        userIdOverride: 'u1',
      );

      await progress.recordAnswer(
        question: m7bQuestion(),
        correct: true,
      );

      final stored = await attempts.loadAll();

      expect(stored, hasLength(1));
      expect(stored.single.questionId, 1);
      expect(stored.single.correct, isTrue);
    });

    test('recordAnswer carries confidence into M7B ledger', () async {
      final progress = const StudentQuestionProgressService(
        userIdOverride: 'u1',
      );
      final attempts = const LearnerAssessmentAttemptRepository(
        userIdOverride: 'u1',
      );

      await progress.recordAnswer(
        question: m7bQuestion(),
        correct: false,
        confidence: LearnerConfidenceLevel.high,
        sessionKind: 'diagnostic',
      );

      final stored = (await attempts.loadAll()).single;

      expect(stored.confidence, LearnerConfidenceLevel.high);
      expect(stored.sessionKind, 'diagnostic');
    });

    test('recordAnswer marks draft evidence as unpublished', () async {
      final progress = const StudentQuestionProgressService(
        userIdOverride: 'u1',
      );
      final attempts = const LearnerAssessmentAttemptRepository(
        userIdOverride: 'u1',
      );

      await progress.recordAnswer(
        question: m7bQuestion(status: 'draft'),
        correct: true,
      );

      expect((await attempts.loadAll()).single.publishedAtAttempt, isFalse);
    });
  });
}
