import 'package:flutter/material.dart';

import '../../../data/csp11_blueprint.dart';
import '../../../theme/glass/student_glass.dart';
import '../models/study_plan_block.dart';
import '../models/today_plan_task_category.dart';
import '../services/today_plan_task_category_policy.dart';

class DailyPlanTaskCard extends StatelessWidget {
  const DailyPlanTaskCard({
    super.key,
    required this.block,
    required this.index,
    required this.onLaunch,
    required this.allowManualFinish,
    required this.completionHint,
    required this.onComplete,
    required this.onSkip,
    required this.onMove,
    required this.onReplace,
    required this.onShorten,
    required this.onUnavailable,
    this.categoryPolicy = const TodayPlanTaskCategoryPolicy(),
  });

  final StudyPlanBlock block;
  final int index;
  final VoidCallback onLaunch;
  final bool allowManualFinish;
  final String completionHint;
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final VoidCallback onMove;
  final VoidCallback onReplace;
  final VoidCallback onShorten;
  final VoidCallback onUnavailable;
  final TodayPlanTaskCategoryPolicy categoryPolicy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final category = categoryPolicy.categoryFor(block);
    final state = _stateFor(block);
    final competency = competencyForId(block.competencyId);
    final competencyTitle = competency?.statement.trim().isNotEmpty == true
        ? competency!.statement.trim()
        : block.competencyId.toUpperCase();
    final applicationLab = _isApplicationLab(block);
    final subdued =
        block.status == StudyPlanBlockStatus.completed ||
        block.isTerminalChange;

    final card = StudentGlassSurface(
      key: ValueKey('m7d-block-$index'),
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(20),
      tint: subdued
          ? scheme.surfaceContainerLowest.withValues(alpha: 0.44)
          : scheme.surfaceContainerLow.withValues(alpha: 0.58),
      borderColor: subdued
          ? scheme.outlineVariant.withValues(alpha: 0.38)
          : scheme.outlineVariant.withValues(alpha: 0.66),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _TaskPill(
                key: ValueKey('erdp8-duration-$index'),
                label: '${block.plannedMinutes} MIN',
                foreground: scheme.primary,
                background: scheme.primaryContainer.withValues(alpha: 0.48),
              ),
              _TaskPill(
                key: ValueKey('erdp8-category-$index'),
                label: _categoryLabel(category),
                foreground: scheme.onSecondaryContainer,
                background: scheme.secondaryContainer.withValues(alpha: 0.54),
              ),
              _TaskPill(
                key: ValueKey('erdp8-status-$index'),
                label: state.label,
                foreground: state.foreground(scheme),
                background: state.background(scheme),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            block.competencyId.toUpperCase(),
            key: ValueKey('erdp8-competency-id-$index'),
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            competencyTitle,
            key: ValueKey('erdp8-competency-title-$index'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                _typeLabel(block.type),
                key: ValueKey('erdp8-type-$index'),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (applicationLab)
                Text(
                  'APPLIED LAB',
                  key: ValueKey('erdp8-lab-$index'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                )
              else if (block.questionCount > 0)
                Text(
                  '${block.questionCount} questions',
                  key: ValueKey('erdp8-question-count-$index'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'WHY THIS TASK',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            block.reasonText,
            key: ValueKey('m7d-reason-$index'),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.42),
          ),
          const SizedBox(height: 14),
          if (block.status == StudyPlanBlockStatus.completed)
            _TerminalMessage(
              key: ValueKey('m7e-completed-$index'),
              icon: Icons.check_circle_rounded,
              text: 'Completed. This task is locked as plan history.',
            )
          else if (block.isTerminalChange)
            _TerminalMessage(
              key: ValueKey('erdp5-terminal-$index'),
              icon: state.icon,
              text: _terminalStatusText(block),
            )
          else if (block.status == StudyPlanBlockStatus.started)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      key: ValueKey('home-r6-continue-$index'),
                      onPressed: onLaunch,
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Resume task'),
                    ),
                    if (allowManualFinish)
                      OutlinedButton.icon(
                        key: ValueKey('m7e-complete-$index'),
                        onPressed: onComplete,
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                        ),
                        label: const Text('Finish planned task'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  completionHint,
                  key: ValueKey('home-r7-completion-hint-$index'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  key: ValueKey('m7d-start-$index'),
                  onPressed:
                      block.status == StudyPlanBlockStatus.planned ||
                          block.status == StudyPlanBlockStatus.shortened
                      ? onLaunch
                      : null,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Start task'),
                ),
                OutlinedButton(
                  key: ValueKey('m7d-skip-$index'),
                  onPressed: onSkip,
                  child: const Text('Skip'),
                ),
                OutlinedButton(
                  key: ValueKey('m7d-move-$index'),
                  onPressed: onMove,
                  child: const Text('Tomorrow'),
                ),
                OutlinedButton(
                  key: ValueKey('m7d-replace-$index'),
                  onPressed: onReplace,
                  child: const Text('Replace'),
                ),
                OutlinedButton(
                  key: ValueKey('m7d-shorten-$index'),
                  onPressed: block.plannedMinutes > 5 ? onShorten : null,
                  child: const Text('Shorten'),
                ),
                OutlinedButton(
                  key: ValueKey('m7d-unavailable-$index'),
                  onPressed: onUnavailable,
                  child: const Text('Unavailable'),
                ),
              ],
            ),
        ],
      ),
    );

    return Semantics(
      key: ValueKey('erdp8-task-semantics-$index'),
      container: true,
      label:
          '${_categoryLabel(category)} task. ${block.competencyId.toUpperCase()}. '
          '$competencyTitle. ${state.label}. ${block.plannedMinutes} minutes.',
      child: Opacity(
        key: ValueKey('erdp8-card-opacity-$index'),
        opacity: subdued ? 0.72 : 1.0,
        child: card,
      ),
    );
  }

  bool _isApplicationLab(StudyPlanBlock block) =>
      block.type == StudyPlanBlockType.repair &&
      block.reasonCodes.any(
        (reason) => reason.trim().toUpperCase() == 'APPLICATION_GAP',
      );

  String _categoryLabel(TodayPlanTaskCategory category) => switch (category) {
    TodayPlanTaskCategory.learn => 'LEARN',
    TodayPlanTaskCategory.practice => 'PRACTICE',
    TodayPlanTaskCategory.remember => 'REMEMBER',
  };

  String _terminalStatusText(StudyPlanBlock block) {
    switch (block.status) {
      case StudyPlanBlockStatus.skipped:
        return 'Skipped. No readiness evidence was created.';
      case StudyPlanBlockStatus.movedToTomorrow:
        return 'Moved to tomorrow. This task remains visible as plan history.';
      case StudyPlanBlockStatus.replaced:
        return 'Replaced by ${block.replacedByBlockId ?? 'an alternative task'}.';
      case StudyPlanBlockStatus.unavailable:
        return 'Unavailable. No readiness evidence was created.';
      case StudyPlanBlockStatus.planned:
      case StudyPlanBlockStatus.started:
      case StudyPlanBlockStatus.completed:
      case StudyPlanBlockStatus.shortened:
        return block.status.name;
    }
  }

  String _typeLabel(StudyPlanBlockType type) => switch (type) {
    StudyPlanBlockType.learn => 'Forward learning',
    StudyPlanBlockType.continueLearning => 'Continue learning',
    StudyPlanBlockType.repair => 'Targeted repair',
    StudyPlanBlockType.diagnostic => 'Diagnostic',
    StudyPlanBlockType.spacedReview => 'Spaced review',
    StudyPlanBlockType.standardPractice => 'Targeted practice',
    StudyPlanBlockType.ultraHardPractice => 'Ultra Hard practice',
    StudyPlanBlockType.mixedRetrieval => 'Mixed retrieval',
    StudyPlanBlockType.competencyRecheck => 'Competency recheck',
    StudyPlanBlockType.confidenceCalibration => 'Confidence calibration',
    StudyPlanBlockType.examSimulation => 'Exam simulation',
    StudyPlanBlockType.recovery => 'Recovery review',
  };

  _TaskStatePresentation _stateFor(StudyPlanBlock block) =>
      switch (block.status) {
        StudyPlanBlockStatus.planned => const _TaskStatePresentation(
          label: 'PLANNED',
          icon: Icons.schedule_rounded,
          tone: _TaskStateTone.neutral,
        ),
        StudyPlanBlockStatus.shortened => const _TaskStatePresentation(
          label: 'PLANNED · SHORTENED',
          icon: Icons.compress_rounded,
          tone: _TaskStateTone.neutral,
        ),
        StudyPlanBlockStatus.started => const _TaskStatePresentation(
          label: 'IN PROGRESS',
          icon: Icons.play_circle_fill_rounded,
          tone: _TaskStateTone.active,
        ),
        StudyPlanBlockStatus.completed => const _TaskStatePresentation(
          label: 'COMPLETED',
          icon: Icons.check_circle_rounded,
          tone: _TaskStateTone.success,
        ),
        StudyPlanBlockStatus.skipped => const _TaskStatePresentation(
          label: 'SKIPPED',
          icon: Icons.skip_next_rounded,
          tone: _TaskStateTone.history,
        ),
        StudyPlanBlockStatus.movedToTomorrow => const _TaskStatePresentation(
          label: 'MOVED',
          icon: Icons.event_repeat_rounded,
          tone: _TaskStateTone.history,
        ),
        StudyPlanBlockStatus.replaced => const _TaskStatePresentation(
          label: 'REPLACED',
          icon: Icons.swap_horiz_rounded,
          tone: _TaskStateTone.history,
        ),
        StudyPlanBlockStatus.unavailable => const _TaskStatePresentation(
          label: 'UNAVAILABLE',
          icon: Icons.block_rounded,
          tone: _TaskStateTone.history,
        ),
      };
}

class _TaskPill extends StatelessWidget {
  const _TaskPill({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.45,
          ),
        ),
      ),
    );
  }
}

class _TerminalMessage extends StatelessWidget {
  const _TerminalMessage({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

enum _TaskStateTone { neutral, active, success, history }

class _TaskStatePresentation {
  const _TaskStatePresentation({
    required this.label,
    required this.icon,
    required this.tone,
  });

  final String label;
  final IconData icon;
  final _TaskStateTone tone;

  Color foreground(ColorScheme scheme) => switch (tone) {
    _TaskStateTone.neutral => scheme.onSurfaceVariant,
    _TaskStateTone.active => scheme.primary,
    _TaskStateTone.success => scheme.tertiary,
    _TaskStateTone.history => scheme.onSurfaceVariant,
  };

  Color background(ColorScheme scheme) => switch (tone) {
    _TaskStateTone.neutral => scheme.surfaceContainerHighest,
    _TaskStateTone.active => scheme.primaryContainer.withValues(alpha: 0.62),
    _TaskStateTone.success => scheme.tertiaryContainer.withValues(alpha: 0.62),
    _TaskStateTone.history => scheme.surfaceContainerHighest.withValues(
      alpha: 0.72,
    ),
  };
}
