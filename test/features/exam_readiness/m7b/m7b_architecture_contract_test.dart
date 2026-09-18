import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('M7B architecture and anti-backdoor contract', () {
    late String aggregation;
    late String snapshotModel;
    late String attemptModel;
    late String rules;
    late String progressService;

    setUpAll(() {
      aggregation = File(
        'lib/features/exam_readiness/services/'
        'learner_evidence_aggregation_service.dart',
      ).readAsStringSync();
      snapshotModel = File(
        'lib/features/exam_readiness/models/'
        'competency_evidence_snapshot.dart',
      ).readAsStringSync();
      attemptModel = File(
        'lib/features/exam_readiness/models/'
        'learner_assessment_attempt.dart',
      ).readAsStringSync();
      rules = File('firestore.rules').readAsStringSync();
      progressService = File(
        'lib/services/student_question_progress_service.dart',
      ).readAsStringSync();
    });

    test('M7B aggregation contains no DailyStudyPlan recommendation layer', () {
      expect(aggregation, isNot(contains('DailyStudyPlan')));
    });

    test('M7B aggregation contains no LearningPriority planner layer', () {
      expect(aggregation, isNot(contains('LearningPriority')));
    });

    test('M7B aggregation contains no composite ReadinessIndex', () {
      expect(aggregation, isNot(contains('ReadinessIndex')));
    });

    test('M7B aggregation contains no pass probability language', () {
      expect(aggregation.toLowerCase(), isNot(contains('pass probability')));
    });

    test('snapshot model preserves Ultra Hard attempts as distinct field', () {
      expect(snapshotModel, contains('ultraHardAttempts'));
      expect(snapshotModel, contains('ultraHardAccuracy'));
    });

    test('snapshot model preserves Standard and Hard fields separately', () {
      expect(snapshotModel, contains('standardAttempts'));
      expect(snapshotModel, contains('hardAttempts'));
    });

    test('snapshot model keeps delayed accuracy nullable', () {
      expect(snapshotModel, contains('double? get delayedAccuracy'));
    });

    test('attempt classification depends on Ultra Hard classification tag', () {
      expect(
        attemptModel,
        contains('UltraHardQuestionContract.classificationTag'),
      );
    });

    test('quiz progress service writes immutable M7B attempt record', () {
      expect(
        progressService,
        contains('LearnerAssessmentAttempt.fromQuestion'),
      );
      expect(progressService, contains('LearnerAssessmentAttemptRepository'));
    });

    test('evidence snapshot Firestore path is UID nested', () {
      expect(rules, contains('match /evidenceSnapshots/{competencyId}'));
      expect(rules, contains('match /users/{uid}'));
    });

    test('evidence snapshots require self or admin reads', () {
      expect(rules, contains('allow get, list: if isSelf(uid) || isAdmin();'));
    });

    test('evidence snapshot write validates document competency ID', () {
      expect(
        rules,
        contains('request.resource.data.competencyId == competencyId'),
      );
    });

    test('evidence snapshot write uses field allowlist', () {
      expect(rules, contains('evidenceSnapshotAllowedKeys()'));
      expect(
        rules,
        contains(
          'request.resource.data.keys().hasOnly(evidenceSnapshotAllowedKeys())',
        ),
      );
    });

    test('global Firestore fallback remains fail closed', () {
      expect(rules, contains('allow read, write: if false;'));
    });

    test('M7B snapshot persists schema and algorithm versions', () {
      expect(snapshotModel, contains('schemaVersion'));
      expect(snapshotModel, contains('algorithmVersion'));
    });

    test('M7B supports incremental competency update', () {
      expect(aggregation, contains('updateCompetencySnapshot'));
      expect(aggregation, contains('refreshCompetency'));
    });

    test('M7B supports full rebuild for migration and debugging', () {
      expect(aggregation, contains('buildAllSnapshots'));
      expect(aggregation, contains('rebuildAll'));
    });
  });
}
