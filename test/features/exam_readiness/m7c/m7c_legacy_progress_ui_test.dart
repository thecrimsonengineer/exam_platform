import 'dart:convert';

import 'package:exam_platform/features/exam_readiness/repositories/evidence_snapshot_repository.dart';
import 'package:exam_platform/features/exam_readiness/repositories/learner_assessment_attempt_repository.dart';
import 'package:exam_platform/features/exam_readiness/screens/readiness_profile_screen.dart';
import 'package:exam_platform/models/student_question_progress.dart';
import 'package:exam_platform/services/auth/learner_local_identity.dart';
import 'package:exam_platform/services/student_question_progress_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

StudentQuestionProgress _legacyRecord(int questionId, bool correct) {
  final answeredAt = DateTime(2026, 9, 10, 12).add(
    Duration(minutes: questionId),
  );

  return StudentQuestionProgress(
    questionId: questionId,
    domainNumber: 3,
    competencyId: 'd03_c02',
    topicId: 'topic-1',
    subtopicId: 'subtopic-$questionId',
    attemptCount: 2,
    lastCorrect: correct,
    everCorrect: correct,
    firstAnsweredAt: answeredAt.subtract(const Duration(days: 10)),
    lastAnsweredAt: answeredAt,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    LearnerLocalIdentity.activate('u1');

    final prefs = await SharedPreferences.getInstance();
    final records = <StudentQuestionProgress>[
      _legacyRecord(101, true),
      _legacyRecord(102, false),
      _legacyRecord(103, true),
    ];

    await prefs.setString(
      StudentQuestionProgressService.storageKeyForUser('u1'),
      jsonEncode({
        for (final record in records)
          record.questionId.toString(): record.toJson(),
      }),
    );
  });

  tearDown(LearnerLocalIdentity.clear);

  testWidgets(
    'legacy learner question progress appears in readiness profile',
    (tester) async {
      final screen = ReadinessProfileScreen(
        evidenceRepository: EvidenceSnapshotRepository(userIdOverride: 'u1'),
        attemptRepository: const LearnerAssessmentAttemptRepository(
          userIdOverride: 'u1',
        ),
        now: () => DateTime(2026, 9, 18, 12),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: screen,
        ),
      );
      await tester.pumpAndSettle();

      final row = find.byKey(const ValueKey('m7c-competency-d03_c02'));
      await tester.scrollUntilVisible(row, 800);

      expect(row, findsOneWidget);
      expect(
        find.descendant(of: row, matching: find.text('UNASSESSED')),
        findsNothing,
      );
      expect(find.textContaining('1/47 competencies'), findsOneWidget);
    },
  );
}
