import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import '../../../features/exam_readiness/models/today_plan_summary.dart';
import '../../../features/exam_readiness/models/today_plan_task_category.dart';

class TodayPlanHomeSection extends StatelessWidget {
  const TodayPlanHomeSection({
    super.key,
    required this.snapshot,
    required this.onCategoryTap,
    required this.onViewFullPlan,
    required this.onRetry,
  });

  final AsyncSnapshot<TodayPlanSummary?> snapshot;
  final ValueChanged<TodayPlanTaskCategory> onCategoryTap;
  final VoidCallback onViewFullPlan;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      key: const ValueKey('home-today-plan-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TODAY'S PLAN",
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.05,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Learn, Practice & Remember',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your adaptive daily plan, grouped into three clear ways to act.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        _buildBody(context),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting &&
        !snapshot.hasData) {
      return const _TodayPlanStatusSurface(
        key: ValueKey('home-today-plan-loading'),
        icon: Icons.schedule_rounded,
        title: "Loading today's plan",
        message: 'Reading your current planner state.',
        showProgress: true,
      );
    }

    if (snapshot.hasError) {
      return _TodayPlanStatusSurface(
        key: const ValueKey('home-today-plan-error'),
        icon: Icons.cloud_off_rounded,
        title: "Today's plan is unavailable",
        message:
            'Search and Continue CSP still work. Retry this section when ready.',
        actionLabel: 'Retry',
        onAction: onRetry,
      );
    }

    final summary = snapshot.data;
    if (summary == null) {
      return _TodayPlanStatusSurface(
        key: const ValueKey('home-today-plan-empty'),
        icon: Icons.event_note_rounded,
        title: 'No daily plan is available yet',
        message:
            "Open Today's Plan to create or restore the authoritative plan for today.",
        actionLabel: "Open Today's Plan",
        onAction: onViewFullPlan,
      );
    }

    return _TodayPlanSummaryView(
      summary: summary,
      onCategoryTap: onCategoryTap,
      onViewFullPlan: onViewFullPlan,
    );
  }
}

class _TodayPlanSummaryView extends StatelessWidget {
  const _TodayPlanSummaryView({
    required this.summary,
    required this.onCategoryTap,
    required this.onViewFullPlan,
  });

  final TodayPlanSummary summary;
  final ValueChanged<TodayPlanTaskCategory> onCategoryTap;
  final VoidCallback onViewFullPlan;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _TodayPlanCategoryCard(
        key: const ValueKey('home-today-learn'),
        title: 'Learn',
        icon: Icons.menu_book_rounded,
        summary: summary.category(TodayPlanTaskCategory.learn),
        onTap: () => onCategoryTap(TodayPlanTaskCategory.learn),
      ),
      _TodayPlanCategoryCard(
        key: const ValueKey('home-today-practice'),
        title: 'Practice',
        icon: Icons.quiz_rounded,
        summary: summary.category(TodayPlanTaskCategory.practice),
        onTap: () => onCategoryTap(TodayPlanTaskCategory.practice),
      ),
      _TodayPlanCategoryCard(
        key: const ValueKey('home-today-remember'),
        title: 'Remember',
        icon: Icons.psychology_alt_rounded,
        summary: summary.category(TodayPlanTaskCategory.remember),
        onTap: () => onCategoryTap(TodayPlanTaskCategory.remember),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 760) {
              return Column(
                children: [
                  for (var index = 0; index < cards.length; index++) ...[
                    cards[index],
                    if (index < cards.length - 1) const SizedBox(height: 12),
                  ],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < cards.length; index++) ...[
                  Expanded(child: cards[index]),
                  if (index < cards.length - 1) const SizedBox(width: 12),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        _TodayPlanAggregateBar(
          summary: summary,
          onViewFullPlan: onViewFullPlan,
        ),
      ],
    );
  }
}

class _TodayPlanCategoryCard extends StatelessWidget {
  const _TodayPlanCategoryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.summary,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final TodayPlanCategorySummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final primaryLine = summary.isEmpty
        ? 'Nothing scheduled today'
        : summary.isComplete
        ? 'All ${summary.taskCount} complete'
        : '${summary.remainingTaskCount} ${summary.remainingTaskCount == 1 ? 'task' : 'tasks'} · '
              '${summary.remainingMinutes} min';

    final detailLine = summary.isEmpty
        ? 'Your planner has no work in this category.'
        : summary.isComplete
        ? '${summary.completedMinutes} min completed'
        : summary.questionCount > 0
        ? '${summary.remainingQuestionCount} questions remaining'
        : summary.nextCompetencyId == null
        ? 'Open the plan for details'
        : 'Next: ${summary.nextCompetencyId!.toUpperCase()}';

    final nextLine =
        !summary.isEmpty &&
            !summary.isComplete &&
            summary.questionCount > 0 &&
            summary.nextCompetencyId != null
        ? 'Next: ${summary.nextCompetencyId!.toUpperCase()}'
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: StudentGlassSurface(
          constraints: const BoxConstraints(minHeight: 168),
          padding: const EdgeInsets.all(18),
          borderRadius: BorderRadius.circular(20),
          tint: scheme.surfaceContainerLow.withValues(alpha: 0.56),
          borderColor: scheme.outlineVariant.withValues(alpha: 0.56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: scheme.primary, size: 21),
                  ),
                  const Spacer(),
                  Icon(
                    summary.isComplete
                        ? Icons.check_circle_rounded
                        : Icons.arrow_outward_rounded,
                    color: summary.isComplete
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                    size: 19,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                primaryLine,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                detailLine,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              if (nextLine != null) ...[
                const SizedBox(height: 4),
                Text(
                  nextLine,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayPlanAggregateBar extends StatelessWidget {
  const _TodayPlanAggregateBar({
    required this.summary,
    required this.onViewFullPlan,
  });

  final TodayPlanSummary summary;
  final VoidCallback onViewFullPlan;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final taskWord = summary.taskCount == 1 ? 'task' : 'tasks';

    final progressText = summary.isEmpty
        ? 'No tasks allocated today'
        : '${summary.completedTaskCount} of ${summary.taskCount} $taskWord complete · '
              '${summary.completedMinutes} of ${summary.allocatedMinutes} min';

    return StudentGlassSurface(
      key: const ValueKey('home-today-plan-aggregate'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      borderRadius: BorderRadius.circular(18),
      tint: scheme.surfaceContainerLow.withValues(alpha: 0.46),
      borderColor: scheme.outlineVariant.withValues(alpha: 0.50),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final action = TextButton.icon(
            key: const ValueKey('home-view-full-plan'),
            onPressed: onViewFullPlan,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('View full plan'),
          );

          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progressText,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Align(alignment: Alignment.centerRight, child: action),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: Text(
                  progressText,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _TodayPlanStatusSurface extends StatelessWidget {
  const _TodayPlanStatusSurface({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.showProgress = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool showProgress;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final leading = showProgress
        ? const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          )
        : Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: scheme.primary, size: 21),
          );

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );

    final action = actionLabel != null && onAction != null
        ? TextButton(onPressed: onAction, child: Text(actionLabel!))
        : null;

    return StudentGlassSurface(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(20),
      tint: scheme.surfaceContainerLow.withValues(alpha: 0.54),
      borderColor: scheme.outlineVariant.withValues(alpha: 0.58),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    leading,
                    const SizedBox(width: 14),
                    Expanded(child: copy),
                  ],
                ),
                if (action != null) ...[
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: action),
                ],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(child: copy),
              if (action != null) ...[const SizedBox(width: 12), action],
            ],
          );
        },
      ),
    );
  }
}
