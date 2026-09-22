import 'package:exam_platform/features/exam_readiness/models/daily_study_plan.dart';
import 'package:exam_platform/features/exam_readiness/models/today_plan_summary.dart';
import 'package:exam_platform/features/exam_readiness/models/today_plan_task_category.dart';
import 'package:exam_platform/widgets/csp/home/today_plan_home_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HOME-R4 renders live category summaries and aggregate progress', (
    tester,
  ) async {
    TodayPlanTaskCategory? tapped;
    var fullPlanTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            child: TodayPlanHomeSection(
              snapshot: AsyncSnapshot<TodayPlanSummary?>.withData(
                ConnectionState.done,
                _summary(),
              ),
              onCategoryTap: (category) => tapped = category,
              onViewFullPlan: () => fullPlanTaps++,
              onRetry: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('home-today-learn')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-today-practice')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-today-remember')), findsOneWidget);
    expect(find.text('1 task · 15 min'), findsOneWidget);
    expect(find.text('4 questions remaining'), findsOneWidget);
    expect(find.text('Nothing scheduled today'), findsOneWidget);
    expect(find.text('2 of 4 tasks complete · 30 of 55 min'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-today-practice')));
    expect(tapped, TodayPlanTaskCategory.practice);

    await tester.tap(find.byKey(const ValueKey('home-view-full-plan')));
    expect(fullPlanTaps, 1);
  });

  testWidgets('HOME-R4 does not present loading as an empty plan', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodayPlanHomeSection(
            snapshot: const AsyncSnapshot<TodayPlanSummary?>.waiting(),
            onCategoryTap: (_) {},
            onViewFullPlan: () {},
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('home-today-plan-loading')),
      findsOneWidget,
    );
    expect(find.text('Nothing scheduled today'), findsNothing);
    expect(find.text('No daily plan is available yet'), findsNothing);
  });

  testWidgets('HOME-R4 isolates plan error and exposes retry', (tester) async {
    var retries = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodayPlanHomeSection(
            snapshot: AsyncSnapshot<TodayPlanSummary?>.withError(
              ConnectionState.done,
              StateError('plan unavailable'),
            ),
            onCategoryTap: (_) {},
            onViewFullPlan: () {},
            onRetry: () => retries++,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('home-today-plan-error')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Search and Continue CSP still work. Retry this section when ready.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  testWidgets('HOME-R4 null plan offers authoritative Today Plan entry', (
    tester,
  ) async {
    var opens = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodayPlanHomeSection(
            snapshot: const AsyncSnapshot<TodayPlanSummary?>.withData(
              ConnectionState.done,
              null,
            ),
            onCategoryTap: (_) {},
            onViewFullPlan: () => opens++,
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('home-today-plan-empty')),
      findsOneWidget,
    );
    await tester.tap(find.text("Open Today's Plan"));
    expect(opens, 1);
  });
}

TodayPlanSummary _summary() {
  return TodayPlanSummary(
    planId: 'home-r4',
    planVersion: 4,
    date: DateTime(2026, 9, 22),
    planStatus: DailyStudyPlanStatus.active,
    availableMinutes: 60,
    allocatedMinutes: 55,
    completedMinutes: 30,
    taskCount: 4,
    completedTaskCount: 2,
    questionCount: 8,
    completedQuestionCount: 4,
    categories: <TodayPlanTaskCategory, TodayPlanCategorySummary>{
      TodayPlanTaskCategory.learn: const TodayPlanCategorySummary(
        category: TodayPlanTaskCategory.learn,
        taskCount: 2,
        completedTaskCount: 1,
        plannedMinutes: 35,
        completedMinutes: 20,
        questionCount: 0,
        completedQuestionCount: 0,
        nextBlockId: 'learn-2',
        nextCompetencyId: 'd04_c01',
      ),
      TodayPlanTaskCategory.practice: const TodayPlanCategorySummary(
        category: TodayPlanTaskCategory.practice,
        taskCount: 2,
        completedTaskCount: 1,
        plannedMinutes: 20,
        completedMinutes: 10,
        questionCount: 8,
        completedQuestionCount: 4,
        nextBlockId: 'practice-2',
        nextCompetencyId: 'd02_c03',
      ),
      TodayPlanTaskCategory.remember: const TodayPlanCategorySummary(
        category: TodayPlanTaskCategory.remember,
        taskCount: 0,
        completedTaskCount: 0,
        plannedMinutes: 0,
        completedMinutes: 0,
        questionCount: 0,
        completedQuestionCount: 0,
        nextBlockId: null,
        nextCompetencyId: null,
      ),
    },
  );
}
