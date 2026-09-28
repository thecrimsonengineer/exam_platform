import 'package:exam_platform/data/csp11_blueprint.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block.dart';
import 'package:exam_platform/features/exam_readiness/widgets/daily_plan_task_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../m7d/_support/m7d_fixture.dart';

StudyPlanBlock _block({
  StudyPlanBlockType type = StudyPlanBlockType.standardPractice,
  StudyPlanBlockStatus status = StudyPlanBlockStatus.planned,
  List<String> reasons = const <String>['ERDP8_TEST'],
  int questionCount = 5,
  String? replacedByBlockId,
}) {
  final started =
      status == StudyPlanBlockStatus.started ||
      status == StudyPlanBlockStatus.completed;
  return StudyPlanBlock(
    blockId: 'erdp8-${type.name}-${status.name}',
    type: type,
    domainId: 'd01',
    competencyId: 'd01_c01',
    subtopicId: '',
    topicId: '',
    plannedMinutes: 15,
    questionCount: questionCount,
    priorityScore: 0.9,
    priorityBreakdown: m7dPriority(competencyId: 'd01_c01'),
    reasonCodes: reasons,
    reasonText:
        'D01_C01 is scheduled because this competency needs focused work before the next readiness check.',
    status: status,
    createdAt: DateTime.utc(2026, 9, 28, 8),
    startedAt: started ? DateTime.utc(2026, 9, 28, 9) : null,
    completedAt: status == StudyPlanBlockStatus.completed
        ? DateTime.utc(2026, 9, 28, 9, 20)
        : null,
    manualChanges: const <StudyPlanManualChange>[],
    replacedByBlockId: replacedByBlockId,
  );
}

Future<void> _pumpCard(
  WidgetTester tester,
  StudyPlanBlock block, {
  Brightness brightness = Brightness.light,
  Size size = const Size(900, 700),
  double textScale = 1,
  bool disableAnimations = false,
  bool allowManualFinish = false,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final theme = brightness == Brightness.dark
      ? ThemeData.dark(useMaterial3: true)
      : ThemeData.light(useMaterial3: true);

  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: DailyPlanTaskCard(
                block: block,
                index: 0,
                onLaunch: () {},
                allowManualFinish: allowManualFinish,
                completionHint: 'Complete the planned activity to finish.',
                onComplete: () {},
                onSkip: () {},
                onMove: () {},
                onReplace: () {},
                onShorten: () {},
                onUnavailable: () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('ERDP-8 Daily Plan task card', () {
    testWidgets('planned task exposes category, competency title, why and controls', (
      tester,
    ) async {
      final block = _block();
      await _pumpCard(tester, block);

      expect(find.text('PRACTICE'), findsOneWidget);
      expect(find.text('PLANNED'), findsOneWidget);
      expect(find.text('WHY THIS TASK'), findsOneWidget);
      expect(find.text('Start task'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Tomorrow'), findsOneWidget);
      expect(find.text('Replace'), findsOneWidget);
      expect(
        find.text(competencyForId('d01_c01')!.statement),
        findsOneWidget,
      );
    });

    testWidgets('started task is clearly in progress and resumes', (tester) async {
      await _pumpCard(
        tester,
        _block(status: StudyPlanBlockStatus.started),
      );

      expect(find.text('IN PROGRESS'), findsOneWidget);
      expect(find.text('Resume task'), findsOneWidget);
      expect(find.text('Start task'), findsNothing);
      expect(find.text('Skip'), findsNothing);
    });

    testWidgets('application repair is presented as Practice LAB, not quiz', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        _block(
          type: StudyPlanBlockType.repair,
          reasons: const <String>['APPLICATION_GAP'],
          questionCount: 5,
        ),
      );

      expect(find.text('PRACTICE'), findsOneWidget);
      expect(find.text('APPLIED LAB'), findsOneWidget);
      expect(find.text('5 questions'), findsNothing);
    });

    testWidgets('completed and changed tasks remain visible but subdued', (
      tester,
    ) async {
      final cases = <StudyPlanBlockStatus, String>{
        StudyPlanBlockStatus.completed: 'COMPLETED',
        StudyPlanBlockStatus.skipped: 'SKIPPED',
        StudyPlanBlockStatus.movedToTomorrow: 'MOVED',
        StudyPlanBlockStatus.replaced: 'REPLACED',
        StudyPlanBlockStatus.unavailable: 'UNAVAILABLE',
      };

      for (final entry in cases.entries) {
        await _pumpCard(
          tester,
          _block(
            status: entry.key,
            replacedByBlockId: entry.key == StudyPlanBlockStatus.replaced
                ? 'replacement-block'
                : null,
          ),
        );

        expect(find.text(entry.value), findsOneWidget, reason: entry.key.name);
        expect(find.text('Start task'), findsNothing, reason: entry.key.name);
        final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
        expect(opacity.opacity, 0.72, reason: entry.key.name);
      }
    });

    testWidgets('small phone, large text and reduced motion remain overflow-safe', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        _block(),
        size: const Size(320, 640),
        textScale: 2,
        disableAnimations: true,
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('erdp8-task-semantics-0')), findsOneWidget);
      expect(find.text('Start task'), findsOneWidget);
    });

    testWidgets('dark mode preserves the same state information', (tester) async {
      await _pumpCard(
        tester,
        _block(status: StudyPlanBlockStatus.started),
        brightness: Brightness.dark,
      );

      expect(find.text('IN PROGRESS'), findsOneWidget);
      expect(find.text('Resume task'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
