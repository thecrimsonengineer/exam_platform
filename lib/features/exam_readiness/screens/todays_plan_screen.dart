import 'package:flutter/material.dart';

import 'package:exam_platform/theme/glass/student_glass.dart';

import '../models/daily_study_plan.dart';
import '../models/study_plan_block.dart';
import '../repositories/daily_study_plan_repository.dart';
import '../repositories/evidence_snapshot_repository.dart';
import '../repositories/exam_study_plan_repository.dart';
import '../repositories/learner_assessment_attempt_repository.dart';
import '../repositories/readiness_snapshot_repository.dart';
import '../services/daily_study_plan_service.dart';
import '../services/learning_state_update_coordinator.dart';
import '../services/phase_aware_daily_plan_service.dart';
import '../services/readiness_evidence_bootstrap_service.dart';
import '../services/study_plan_outcome_service.dart';
import '../services/readiness_profile_service.dart';
import '../services/exam_study_capacity_service.dart';
import '../services/ultra_hard_availability_service.dart';

class TodaysPlanScreen extends StatefulWidget {
  const TodaysPlanScreen({
    super.key,
    this.examPlanRepository,
    this.readinessRepository,
    this.dailyPlanRepository,
    this.planService = const DailyStudyPlanService(),
    this.phaseAwarePlanService = const PhaseAwareDailyPlanService(),
    this.capacityService = const ExamStudyCapacityService(),
    this.ultraHardAvailabilityService,
    this.attemptRepository,
    this.outcomeService = const StudyPlanOutcomeService(),
    this.learningStateCoordinator = const LearningStateUpdateCoordinator(),
    this.now,
  });

  final ExamStudyPlanRepository? examPlanRepository;
  final ReadinessSnapshotRepository? readinessRepository;
  final DailyStudyPlanRepository? dailyPlanRepository;
  final DailyStudyPlanService planService;
  final PhaseAwareDailyPlanService phaseAwarePlanService;
  final ExamStudyCapacityService capacityService;
  final UltraHardAvailabilityService? ultraHardAvailabilityService;
  final LearnerAssessmentAttemptRepository? attemptRepository;
  final StudyPlanOutcomeService outcomeService;
  final LearningStateUpdateCoordinator learningStateCoordinator;
  final DateTime Function()? now;

  @override
  State<TodaysPlanScreen> createState() => _TodaysPlanScreenState();
}

class _TodaysPlanScreenState extends State<TodaysPlanScreen> {
  late Future<_TodayPlanViewData> _future;

  ExamStudyPlanRepository get _examPlanRepository =>
      widget.examPlanRepository ?? ExamStudyPlanRepository();

  ReadinessSnapshotRepository get _readinessRepository =>
      widget.readinessRepository ?? ReadinessSnapshotRepository();

  DailyStudyPlanRepository get _dailyPlanRepository =>
      widget.dailyPlanRepository ?? DailyStudyPlanRepository();

  LearnerAssessmentAttemptRepository get _attemptRepository =>
      widget.attemptRepository ?? const LearnerAssessmentAttemptRepository();

  UltraHardAvailabilityService get _ultraHardAvailabilityService =>
      widget.ultraHardAvailabilityService ?? UltraHardAvailabilityService();

  DateTime get _now => widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_TodayPlanViewData> _load({bool regenerate = false}) async {
    if (widget.readinessRepository == null) {
      await _refreshLocalReadiness();
    }

    final examPlan = await _examPlanRepository.loadActivePlan();
    if (examPlan == null) {
      return const _TodayPlanViewData(
        plan: null,
        hasExamPlan: false,
        notice: null,
      );
    }

    final now = _now;
    final availableMinutes = widget.capacityService.minutesForDate(
      plan: examPlan,
      date: now,
    );
    final readiness = await _readinessRepository.loadLocal();
    final existing = await _dailyPlanRepository.loadLatestForDate(now);
    final capacityChanged =
        existing != null && existing.availableMinutes != availableMinutes;
    final stale = existing?.status == DailyStudyPlanStatus.stale;

    if (!regenerate && existing != null && !capacityChanged && !stale) {
      return _TodayPlanViewData(
        plan: existing,
        hasExamPlan: true,
        notice: null,
      );
    }

    final missedStudyDay =
        existing == null && await _hasMissedStudyDay(examPlan, now);

    Set<String> ultraHardAvailable = const <String>{};
    String? notice;

    try {
      ultraHardAvailable = await _ultraHardAvailabilityService
          .loadAvailableCompetencyIds();
    } catch (_) {
      notice =
          'Ultra Hard availability could not be refreshed. '
          'No new Ultra Hard block will be scheduled.';
    }

    final plan = widget.phaseAwarePlanService.generate(
      userId: examPlan.userId,
      date: now,
      generatedAt: now,
      examDate: examPlan.examDate,
      availableMinutes: availableMinutes,
      readinessProfiles: readiness,
      ultraHardAvailableCompetencyIds: ultraHardAvailable,
      existingPlan: existing,
      generationReason: regenerate
          ? DailyStudyPlanGenerationReason.manualRequest
          : stale
          ? existing!.generationReason
          : capacityChanged
          ? DailyStudyPlanGenerationReason.capacityChanged
          : missedStudyDay
          ? DailyStudyPlanGenerationReason.missedStudyDay
          : DailyStudyPlanGenerationReason.initial,
    );

    await _dailyPlanRepository.savePlan(plan, syncRemote: false);

    return _TodayPlanViewData(plan: plan, hasExamPlan: true, notice: notice);
  }

  Future<void> _refreshLocalReadiness() async {
    try {
      final evidenceRepository = EvidenceSnapshotRepository();
      final attemptRepository = _attemptRepository;
      const bootstrapService = ReadinessEvidenceBootstrapService();
      const profileService = ReadinessProfileService();

      final bootstrap = await bootstrapService.rebuildLocal(
        evidenceRepository: evidenceRepository,
        attemptRepository: attemptRepository,
        now: _now,
      );

      final dashboard = profileService.buildDashboard(
        evidenceByCompetency: bootstrap.evidenceByCompetency,
        attempts: bootstrap.attempts,
        now: _now,
      );

      await _readinessRepository.saveMany(
        dashboard.profiles.values,
        syncRemote: false,
      );
    } catch (_) {
      // A readiness refresh must never block opening the learner's daily plan.
    }
  }

  Future<void> _regenerate() async {
    final next = _load(regenerate: true);
    setState(() => _future = next);
    await next;
  }

  Future<bool> _hasMissedStudyDay(dynamic examPlan, DateTime now) async {
    final today = DateTime(now.year, now.month, now.day);
    final created = DateTime(
      examPlan.createdAt.year,
      examPlan.createdAt.month,
      examPlan.createdAt.day,
    );

    for (var offset = 1; offset <= 7; offset++) {
      final date = today.subtract(Duration(days: offset));
      if (date.isBefore(created)) break;

      final minutes = widget.capacityService.minutesForDate(
        plan: examPlan,
        date: date,
      );
      if (minutes <= 0) continue;

      final prior = await _dailyPlanRepository.loadLatestForDate(date);
      if (prior == null) return true;
      if (prior.blocks.isEmpty) return false;

      return !prior.blocks.any(
        (block) => block.status == StudyPlanBlockStatus.completed,
      );
    }

    return false;
  }

  Future<void> _complete(String blockId) async {
    final data = await _future;
    final plan = data.plan;
    if (plan == null) return;

    final block = plan.blocks.firstWhere(
      (item) => item.blockId == blockId,
      orElse: () => throw StateError('Study-plan block not found.'),
    );
    if (block.status != StudyPlanBlockStatus.started) {
      return;
    }

    final at = _now;
    final attempts = await _attemptRepository.loadAll();
    final outcome = widget.outcomeService.build(
      plan: plan,
      block: block,
      attempts: attempts,
      completedAt: at,
    );

    final update = await widget.learningStateCoordinator.processOutcome(
      outcome: outcome,
      now: at,
      attemptRepository: _attemptRepository,
      readinessRepository: _readinessRepository,
      planRepository: _dailyPlanRepository,
    );

    final changed = widget.planService.completeBlock(plan, blockId, at: at);
    await _dailyPlanRepository.savePlan(changed, syncRemote: false);

    final signalNotice = update.misconceptionSignals.isEmpty
        ? ''
        : ' A misconception or confidence pattern was detected.';
    final staleNotice = update.stalePlanVersionsCreated == 0
        ? ' Future planning will use the updated evidence.'
        : ' ${update.stalePlanVersionsCreated} future plan version(s) were marked for adaptation.';

    if (!mounted) return;
    setState(
      () => _future = Future.value(
        _TodayPlanViewData(
          plan: changed,
          hasExamPlan: true,
          notice:
              'Readiness updated for ${block.competencyId.toUpperCase()}.$signalNotice$staleNotice',
        ),
      ),
    );
  }

  Future<void> _apply(
    DailyStudyPlan Function(DailyStudyPlan plan, DateTime at) transform,
  ) async {
    final data = await _future;
    final plan = data.plan;
    if (plan == null) return;

    final changed = transform(plan, _now);
    if (identical(changed, plan)) return;

    await _dailyPlanRepository.savePlan(changed, syncRemote: false);
    setState(
      () => _future = Future.value(
        _TodayPlanViewData(
          plan: changed,
          hasExamPlan: true,
          notice: data.notice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StudentGlassScaffold(
      key: const ValueKey('m7d-todays-plan-screen'),
      appBar: AppBar(
        title: const Text("Today's Plan"),
        actions: [
          IconButton(
            key: const ValueKey('m7d-regenerate-plan'),
            onPressed: _regenerate,
            tooltip: 'Regenerate unstarted blocks',
            icon: const Icon(Icons.auto_awesome_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<_TodayPlanViewData>(
          future: _future,
          builder: (context, async) {
            if (async.connectionState == ConnectionState.waiting &&
                !async.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (async.hasError) {
              return _ErrorState(
                message: async.error.toString(),
                onRetry: _regenerate,
              );
            }

            final data = async.data;
            if (data == null || !data.hasExamPlan) {
              return const _NoExamPlanState();
            }

            final plan = data.plan;
            if (plan == null) {
              return _ErrorState(
                message: 'Today\'s plan is unavailable.',
                onRetry: _regenerate,
              );
            }

            return RefreshIndicator(
              onRefresh: _regenerate,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                children: [
                  if (data.notice != null) ...[
                    _Notice(text: data.notice!),
                    const SizedBox(height: 12),
                  ],
                  _TodayHero(plan: plan),
                  const SizedBox(height: 14),
                  if (plan.blocks.isEmpty)
                    _NoStudyToday(availableMinutes: plan.availableMinutes)
                  else
                    for (
                      var index = 0;
                      index < plan.blocks.length;
                      index++
                    ) ...[
                      _PlanBlockCard(
                        block: plan.blocks[index],
                        index: index,
                        onStart: () => _apply(
                          (current, at) => widget.planService.startBlock(
                            current,
                            plan.blocks[index].blockId,
                            at: at,
                          ),
                        ),
                        onComplete: () => _complete(plan.blocks[index].blockId),
                        onSkip: () => _apply(
                          (current, at) => widget.planService.skipBlock(
                            current,
                            plan.blocks[index].blockId,
                            at: at,
                          ),
                        ),
                        onMove: () => _apply(
                          (current, at) => widget.planService.moveToTomorrow(
                            current,
                            plan.blocks[index].blockId,
                            at: at,
                          ),
                        ),
                        onReplace: () => _apply(
                          (current, at) =>
                              widget.planService.replaceWithAlternative(
                                current,
                                plan.blocks[index].blockId,
                                at: at,
                              ),
                        ),
                        onShorten: () => _apply(
                          (current, at) => widget.planService.shortenBlock(
                            current,
                            plan.blocks[index].blockId,
                            newMinutes: (plan.blocks[index].plannedMinutes - 5)
                                .clamp(5, plan.blocks[index].plannedMinutes)
                                .toInt(),
                            at: at,
                          ),
                        ),
                        onUnavailable: () => _apply(
                          (current, at) => widget.planService.markUnavailable(
                            current,
                            plan.blocks[index].blockId,
                            at: at,
                          ),
                        ),
                      ),
                      if (index < plan.blocks.length - 1)
                        const SizedBox(height: 12),
                    ],
                  if (plan.blocks.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _WhyThisPlan(plan: plan),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TodayHero extends StatelessWidget {
  const _TodayHero({required this.plan});

  final DailyStudyPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return StudentGlassSurface(
      key: const ValueKey('m7d-today-hero'),
      padding: const EdgeInsets.all(22),
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(
        colors: [
          scheme.primaryContainer.withValues(alpha: 0.68),
          scheme.secondaryContainer.withValues(alpha: 0.58),
        ],
      ),
      borderColor: scheme.primary.withValues(alpha: 0.16),
      child: Wrap(
        spacing: 20,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TODAY',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${plan.availableMinutes} MIN',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Text(
            '${plan.allocatedMinutes} min allocated • '
            'plan v${plan.planVersion}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanBlockCard extends StatelessWidget {
  const _PlanBlockCard({
    required this.block,
    required this.index,
    required this.onStart,
    required this.onComplete,
    required this.onSkip,
    required this.onMove,
    required this.onReplace,
    required this.onShorten,
    required this.onUnavailable,
  });

  final StudyPlanBlock block;
  final int index;
  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final VoidCallback onMove;
  final VoidCallback onReplace;
  final VoidCallback onShorten;
  final VoidCallback onUnavailable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return StudentGlassSurface(
      key: ValueKey('m7d-block-$index'),
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(20),
      tint: scheme.surfaceContainerLow.withValues(alpha: 0.54),
      borderColor: scheme.outlineVariant.withValues(alpha: 0.62),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${block.plannedMinutes} MIN',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                _typeLabel(block.type),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                block.status.name.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            block.competencyId.toUpperCase(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          if (block.questionCount > 0) ...[
            const SizedBox(height: 4),
            Text('${block.questionCount} questions'),
          ],
          const SizedBox(height: 10),
          Text(
            block.reasonText,
            key: ValueKey('m7d-reason-$index'),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 12),
          if (block.status == StudyPlanBlockStatus.completed)
            Text(
              'Completed. This historical block is locked.',
              key: ValueKey('m7e-completed-$index'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            )
          else if (block.status == StudyPlanBlockStatus.started)
            FilledButton.icon(
              key: ValueKey('m7e-complete-$index'),
              onPressed: onComplete,
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('Complete'),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  key: ValueKey('m7d-start-$index'),
                  onPressed: onStart,
                  child: const Text('Start'),
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
  }

  String _typeLabel(StudyPlanBlockType type) {
    switch (type) {
      case StudyPlanBlockType.learn:
        return 'LEARN';
      case StudyPlanBlockType.continueLearning:
        return 'CONTINUE';
      case StudyPlanBlockType.repair:
        return 'REPAIR';
      case StudyPlanBlockType.diagnostic:
        return 'DIAGNOSTIC';
      case StudyPlanBlockType.spacedReview:
        return 'SPACED REVIEW';
      case StudyPlanBlockType.standardPractice:
        return 'PRACTICE';
      case StudyPlanBlockType.ultraHardPractice:
        return 'ULTRA HARD';
      case StudyPlanBlockType.mixedRetrieval:
        return 'MIXED RETRIEVAL';
      case StudyPlanBlockType.competencyRecheck:
        return 'RECHECK';
      case StudyPlanBlockType.confidenceCalibration:
        return 'CONFIDENCE CHECK';
      case StudyPlanBlockType.examSimulation:
        return 'EXAM SIMULATION';
      case StudyPlanBlockType.recovery:
        return 'RECOVERY';
    }
  }
}

class _WhyThisPlan extends StatelessWidget {
  const _WhyThisPlan({required this.plan});

  final DailyStudyPlan plan;

  @override
  Widget build(BuildContext context) {
    final reasons = <String>[];
    for (final block in plan.blocks) {
      if (!reasons.contains(block.reasonText)) {
        reasons.add(block.reasonText);
      }
      if (reasons.length >= 4) break;
    }

    final scheme = Theme.of(context).colorScheme;
    return StudentGlassSurface(
      key: const ValueKey('m7d-why-this-plan'),
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(20),
      tint: scheme.tertiaryContainer.withValues(alpha: 0.56),
      borderColor: scheme.tertiary.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHY THIS PLAN?',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < reasons.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${i + 1}. ${reasons[i]}'),
            ),
        ],
      ),
    );
  }
}

class _NoStudyToday extends StatelessWidget {
  const _NoStudyToday({required this.availableMinutes});

  final int availableMinutes;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StudentGlassSurface(
      key: const ValueKey('m7d-no-study-today'),
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      tint: scheme.surfaceContainerLow.withValues(alpha: 0.54),
      borderColor: scheme.outlineVariant.withValues(alpha: 0.60),
      child: Text(
        availableMinutes == 0
            ? 'No study minutes are scheduled for today.'
            : 'No blocks were generated for the available study time.',
      ),
    );
  }
}

class _NoExamPlanState extends StatelessWidget {
  const _NoExamPlanState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Create an exam plan before generating an adaptive daily plan.',
          key: ValueKey('m7d-no-exam-plan'),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StudentGlassSurface(
      key: const ValueKey('m7d-notice'),
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(16),
      tint: scheme.tertiaryContainer.withValues(alpha: 0.52),
      borderColor: scheme.tertiary.withValues(alpha: 0.16),
      child: Text(text),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 46),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _TodayPlanViewData {
  const _TodayPlanViewData({
    required this.plan,
    required this.hasExamPlan,
    required this.notice,
  });

  final DailyStudyPlan? plan;
  final bool hasExamPlan;
  final String? notice;
}
