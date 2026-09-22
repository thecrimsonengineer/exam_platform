import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HOME-R7 QuizScreen tags and awaits planned-session evidence', () {
    final source = File(
      'lib/screens/courses/csp/quiz/quiz_screen.dart',
    ).readAsStringSync();

    for (final required in <String>[
      "this.assessmentSessionKind = 'practice'",
      'this.onSessionCompleted',
      'sessionKind: widget.assessmentSessionKind',
      '_pendingQuestionWrites',
      'await Future.wait(',
      '_sessionCompletionNotified',
      'await callback();',
    ]) {
      expect(source, contains(required));
    }
  });

  test('HOME-R7 planned practice binds completion to the block ID', () {
    final source = File(
      'lib/features/exam_readiness/screens/study_plan_practice_session_screen.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('StudyPlanCompletionEvidenceService.sessionKindForBlock('),
    );
    expect(source, contains('widget.target.blockId'));
    expect(source, contains('onSessionCompleted: widget.onSessionCompleted'));
  });

  test('HOME-R7 Today Plan gates completion through evidence service', () {
    final source = File(
      'lib/features/exam_readiness/screens/todays_plan_screen.dart',
    ).readAsStringSync();

    for (final required in <String>[
      'StudyPlanCompletionEvidenceService completionEvidenceService',
      'widget.completionEvidenceService.evaluate(',
      'StudyPlanCompletionEvidenceSource.plannedPracticeSession',
      'StudyPlanCompletionEvidenceSource.studyContent',
      'explicitLearnerFinish',
      '_completionInFlight',
      'allowsExplicitLearnerFinish(block)',
      'home-r7-completion-hint',
    ]) {
      expect(source, contains(required));
    }

    expect(
      source,
      isNot(contains('onComplete: () => _complete(block.blockId)')),
      reason: 'Ungated generic completion must not return.',
    );
  });

  test('HOME-R7 route opening remains separate from planner completion', () {
    final source = File(
      'lib/features/exam_readiness/screens/todays_plan_screen.dart',
    ).readAsStringSync();

    final launchStart = source.indexOf(
      'Future<void> _launchBlock(StudyPlanBlock block)',
    );
    final completionStart = source.indexOf('Future<bool> _complete(');

    expect(launchStart, greaterThanOrEqualTo(0));
    expect(completionStart, greaterThan(launchStart));

    final preCompletion = source.substring(launchStart, completionStart);
    expect(preCompletion, isNot(contains('completeBlock(')));
  });
  test('HOME-R7 review evidence distinguishes re-completion from route-open', () {
    final model = File(
      'lib/models/student_learning_progress.dart',
    ).readAsStringSync();
    final service = File(
      'lib/services/student_learning_progress_service.dart',
    ).readAsStringSync();
    final evidence = File(
      'lib/features/exam_readiness/services/study_plan_completion_evidence_service.dart',
    ).readAsStringSync();

    expect(model, contains('final DateTime? lastCompletedAt;'));
    expect(model, contains("'lastCompletedAt': lastCompletedAt?.toIso8601String()"));
    expect(service, contains('lastCompletedAt: now'));
    expect(
      evidence,
      contains('progress.lastCompletedAt ?? progress.completedAt'),
    );
  });

}
