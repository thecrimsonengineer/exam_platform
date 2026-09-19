import 'dart:io';

import 'package:exam_platform/features/exam_readiness/repositories/daily_study_plan_repository.dart';
import 'package:exam_platform/features/exam_readiness/repositories/exam_study_plan_repository.dart';
import 'package:exam_platform/features/exam_readiness/repositories/readiness_snapshot_repository.dart';
import 'package:exam_platform/services/student_learning_progress_service.dart';
import 'package:exam_platform/services/student_question_progress_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const userId = 'fr-preservation-user';

  test('FR preserves the installed Android application identity', () {
    final source = File('android/app/build.gradle.kts').readAsStringSync();

    expect(source, contains('applicationId = "com.example.exam_platform"'));
  });

  test('FR preserves existing device-global content cache namespaces', () {
    final contentCache = File(
      'lib/services/study_content/student_content_cache_repository.dart',
    ).readAsStringSync();
    final questionBank = File(
      'lib/services/local_question_repository.dart',
    ).readAsStringSync();

    expect(contentCache, contains('csp11.student_content_cache.v1'));
    expect(questionBank, contains('csp11.question_bank.v1'));
  });

  test('FR preserves UID-scoped learner progress namespaces', () {
    expect(
      StudentLearningProgressService.storageKeyForUser(userId),
      'csp11.student.$userId.learning_progress.v2',
    );
    expect(
      StudentQuestionProgressService.storageKeyForUser(userId),
      'csp11.student.$userId.question_progress.v1',
    );
  });

  test('FR preserves UID-scoped Exam Readiness namespaces', () {
    expect(
      ReadinessSnapshotRepository.storageKeyForUser(userId),
      'csp11.student.$userId.exam_readiness.readiness_snapshots.v1',
    );
    expect(
      DailyStudyPlanRepository.storageKeyForUser(userId),
      'csp11.student.$userId.exam_readiness.daily_study_plans.v1',
    );
    expect(
      ExamStudyPlanRepository.storageKeyForUser(userId),
      'csp11.student.$userId.exam_readiness.exam_plans.v1',
    );
  });

  test('FR retains the legacy learner progress key for safe migration', () {
    expect(
      StudentLearningProgressService.legacyStorageKey,
      'csp11.student.learning_progress.v1',
    );
  });
}
