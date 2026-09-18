import 'package:exam_platform/features/exam_readiness/models/evidence_confidence.dart';
import 'package:exam_platform/features/exam_readiness/repositories/evidence_snapshot_repository.dart';
import 'package:exam_platform/features/exam_readiness/repositories/learner_assessment_attempt_repository.dart';
import 'package:exam_platform/features/exam_readiness/screens/readiness_profile_screen.dart';
import 'package:exam_platform/services/auth/learner_local_identity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '_support/m7c_fixture.dart';

Widget _app(Widget home, {bool dark = false}) {
  return MaterialApp(
    theme: dark ? ThemeData.dark() : ThemeData.light(),
    home: home,
  );
}

Future<ReadinessProfileScreen> _screenWithEvidence({
  bool sparse = false,
  bool stale = false,
}) async {
  final evidenceRepository = EvidenceSnapshotRepository(userIdOverride: 'u1');
  final attemptRepository = const LearnerAssessmentAttemptRepository(
    userIdOverride: 'u1',
  );

  await evidenceRepository.save(
    sparse
        ? m7cEvidence(
            totalAttempts: 1,
            correct: 1,
            uniqueQuestions: 1,
            applicationAttempts: 1,
            applicationCorrect: 1,
            analysisAttempts: 0,
            analysisCorrect: 0,
            overallConfidence: EvidenceConfidence.veryLow,
            evidenceState: EvidenceState.insufficient,
            delayedAttempts: 0,
            delayedCorrect: 0,
          )
        : m7cEvidence(
            evidenceState: stale ? EvidenceState.stale : EvidenceState.robust,
            recencyBand: stale
                ? EvidenceRecencyBand.stale
                : EvidenceRecencyBand.recent,
          ),
    syncRemote: false,
  );

  for (final attempt in m7cAttempts()) {
    await attemptRepository.append(attempt);
  }

  return ReadinessProfileScreen(
    evidenceRepository: evidenceRepository,
    attemptRepository: attemptRepository,
    now: () => DateTime(2026, 9, 18, 12),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LearnerLocalIdentity.activate('u1');
  });

  tearDown(LearnerLocalIdentity.clear);

  group('M7C readiness screen', () {
    testWidgets('renders readiness screen scaffold', (tester) async {
      await tester.pumpWidget(_app(await _screenWithEvidence()));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('m7c-readiness-screen')),
        findsOneWidget,
      );
    });

    testWidgets('renders evidence confidence hero', (tester) async {
      await tester.pumpWidget(_app(await _screenWithEvidence()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('m7c-evidence-hero')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('m7c-evidence-confidence')),
        findsOneWidget,
      );
    });

    testWidgets('renders separate readiness dimensions', (tester) async {
      await tester.pumpWidget(_app(await _screenWithEvidence()));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('m7c-readiness-dimensions')),
        findsOneWidget,
      );
    });

    testWidgets('renders blueprint coverage card', (tester) async {
      await tester.pumpWidget(_app(await _screenWithEvidence()));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('m7c-blueprint-coverage')),
        findsOneWidget,
      );
    });

    testWidgets('renders areas requiring attention', (tester) async {
      await tester.pumpWidget(_app(await _screenWithEvidence()));
      await tester.pumpAndSettle();
      final attention = find.byKey(const ValueKey('m7c-attention-card'));
      await tester.scrollUntilVisible(attention, 500);
      expect(attention, findsOneWidget);
    });

    testWidgets('never displays a composite readiness index statement', (
      tester,
    ) async {
      await tester.pumpWidget(_app(await _screenWithEvidence()));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('m7c-no-composite-index')),
        600,
      );
      expect(
        find.byKey(const ValueKey('m7c-no-composite-index')),
        findsOneWidget,
      );
      expect(
        find.textContaining('single exam-readiness percentage'),
        findsOneWidget,
      );
    });

    testWidgets('sparse evidence hides inappropriate dimension percentages', (
      tester,
    ) async {
      await tester.pumpWidget(_app(await _screenWithEvidence(sparse: true)));
      await tester.pumpAndSettle();
      expect(find.text('INSUFFICIENT EVIDENCE'), findsWidgets);
    });

    testWidgets('competency matrix is present', (tester) async {
      await tester.pumpWidget(_app(await _screenWithEvidence()));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('m7c-competency-matrix')),
        700,
      );
      expect(
        find.byKey(const ValueKey('m7c-competency-matrix')),
        findsOneWidget,
      );
    });

    testWidgets('assessed competency row is addressable', (tester) async {
      await tester.pumpWidget(_app(await _screenWithEvidence()));
      await tester.pumpAndSettle();
      final row = find.byKey(const ValueKey('m7c-competency-d03_c02'));
      await tester.scrollUntilVisible(row, 800);
      expect(row, findsOneWidget);
    });

    testWidgets('unassessed competencies remain labelled UNASSESSED', (
      tester,
    ) async {
      await tester.pumpWidget(_app(await _screenWithEvidence()));
      await tester.pumpAndSettle();
      final row = find.byKey(const ValueKey('m7c-competency-d01_c01'));
      await tester.scrollUntilVisible(row, 800);
      expect(row, findsOneWidget);
      expect(
        find.descendant(of: row, matching: find.text('UNASSESSED')),
        findsOneWidget,
      );
    });

    testWidgets('tapping assessed competency opens detail screen', (
      tester,
    ) async {
      await tester.pumpWidget(_app(await _screenWithEvidence()));
      await tester.pumpAndSettle();
      final row = find.byKey(const ValueKey('m7c-competency-d03_c02'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('m7c-competency-readiness-screen')),
        findsOneWidget,
      );
    });

    testWidgets('refresh action is present', (tester) async {
      await tester.pumpWidget(_app(await _screenWithEvidence()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('m7c-refresh')), findsOneWidget);
    });

    testWidgets('empty evidence displays NONE confidence safely', (
      tester,
    ) async {
      final screen = ReadinessProfileScreen(
        evidenceRepository: EvidenceSnapshotRepository(userIdOverride: 'u1'),
        attemptRepository: const LearnerAssessmentAttemptRepository(
          userIdOverride: 'u1',
        ),
        now: () => DateTime(2026, 9, 18, 12),
      );
      await tester.pumpWidget(_app(screen));
      await tester.pumpAndSettle();
      expect(find.text('NONE'), findsOneWidget);
    });

    testWidgets('dark mode remains dark', (tester) async {
      await tester.pumpWidget(_app(await _screenWithEvidence(), dark: true));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(Scaffold))).brightness,
        Brightness.dark,
      );
    });

    testWidgets('narrow Android width has no render exception', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app(await _screenWithEvidence()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('stale evidence exposes limitation content', (tester) async {
      await tester.pumpWidget(_app(await _screenWithEvidence(stale: true)));
      await tester.pumpAndSettle();
      final limitations = find.byKey(const ValueKey('m7c-limitations-card'));
      await tester.scrollUntilVisible(limitations, 600);
      expect(limitations, findsOneWidget);
    });
  });
}
