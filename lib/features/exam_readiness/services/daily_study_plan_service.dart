import '../../../data/csp11_blueprint.dart';
import '../models/competency_readiness_profile.dart';
import '../models/daily_study_plan.dart';
import '../models/evidence_confidence.dart';
import '../models/learning_priority_score.dart';
import '../models/readiness_gap.dart';
import '../models/study_plan_block.dart';
import 'learning_priority_engine.dart';
import 'planner_constraints.dart';

class DailyStudyPlanService {
  const DailyStudyPlanService({
    this.priorityEngine = const LearningPriorityEngine(),
    this.constraints = const DailyPlannerConstraints(),
  });

  final LearningPriorityEngine priorityEngine;
  final DailyPlannerConstraints constraints;

  DailyStudyPlan generate({
    required String userId,
    required DateTime date,
    required DateTime generatedAt,
    required DateTime examDate,
    required int availableMinutes,
    required Map<String, CompetencyReadinessProfile> readinessProfiles,
    Set<String> ultraHardAvailableCompetencyIds = const <String>{},
    Set<String> recentlyStudiedCompetencyIds = const <String>{},
    DailyStudyPlan? existingPlan,
    DailyStudyPlanGenerationReason generationReason =
        DailyStudyPlanGenerationReason.initial,
  }) {
    constraints.validate();

    final day = DateTime(date.year, date.month, date.day);
    final exam = DateTime(examDate.year, examDate.month, examDate.day);
    final daysUntilExam = exam.difference(day).inDays;
    final normalizedAvailable = availableMinutes.clamp(0, 1440).toInt();
    final planId =
        'm7d-${_safe(userId)}-${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}';
    final nextVersion = (existingPlan?.planVersion ?? 0) + 1;

    final locked = existingPlan == null
        ? <StudyPlanBlock>[]
        : existingPlan.blocks.where((block) => block.isLocked).toList();
    final lockedMinutes = locked.fold<int>(
      0,
      (sum, block) => sum + block.plannedMinutes,
    );

    if (lockedMinutes > normalizedAvailable) {
      throw StateError(
        'Started/completed blocks exceed today\'s available capacity.',
      );
    }

    final candidates = <_Candidate>[];
    for (final domain in csp11Domains) {
      for (final competency in domain.competencies) {
        final profile = readinessProfiles[competency.id];
        final ultraAvailable = ultraHardAvailableCompetencyIds.contains(
          competency.id,
        );
        final score = priorityEngine.score(
          competencyId: competency.id,
          domainWeightPercent: domain.weightPercent,
          daysUntilExam: daysUntilExam,
          profile: profile,
          ultraHardAvailable: ultraAvailable,
          recentlyStudied: recentlyStudiedCompetencyIds.contains(competency.id),
        );

        candidates.add(
          _Candidate(
            domainId: domain.id,
            competencyId: competency.id,
            profile: profile,
            priority: score,
            ultraHardAvailable: ultraAvailable,
          ),
        );
      }
    }

    candidates.sort((left, right) {
      final scoreOrder = right.priority.totalScore.compareTo(
        left.priority.totalScore,
      );
      if (scoreOrder != 0) return scoreOrder;
      return left.competencyId.compareTo(right.competencyId);
    });

    final selected = <_Candidate>[];
    for (final candidate in candidates) {
      if (selected.length >= constraints.maxCompetenciesPerDay) break;
      if (locked.any((block) => block.competencyId == candidate.competencyId)) {
        continue;
      }
      selected.add(candidate);
    }

    var remaining = normalizedAvailable - lockedMinutes;
    var slot = locked.length;
    final blocks = <StudyPlanBlock>[...locked];

    for (final candidate in selected) {
      if (remaining < constraints.practiceMinMinutes ||
          blocks.length >= constraints.maxBlocksPerDay) {
        break;
      }

      final type = _primaryType(candidate.profile);
      final minutes = _minutesForType(type, remaining, normalizedAvailable);
      if (minutes < _minimumForType(type)) continue;

      blocks.add(
        _buildBlock(
          planId: planId,
          version: nextVersion,
          slot: slot++,
          candidate: candidate,
          type: type,
          minutes: minutes,
          generatedAt: generatedAt,
        ),
      );
      remaining -= minutes;
    }

    if (remaining >= constraints.reviewMinMinutes &&
        blocks.length < constraints.maxBlocksPerDay &&
        selected.isNotEmpty) {
      final retentionCandidate = selected.firstWhere(
        (candidate) => _needsRetention(candidate.profile),
        orElse: () => selected.first,
      );
      final minutes = remaining
          .clamp(constraints.reviewMinMinutes, constraints.reviewMaxMinutes)
          .toInt();
      blocks.add(
        _buildBlock(
          planId: planId,
          version: nextVersion,
          slot: slot++,
          candidate: retentionCandidate,
          type: StudyPlanBlockType.spacedReview,
          minutes: minutes,
          generatedAt: generatedAt,
          extraReason: 'RETENTION_DUE',
        ),
      );
      remaining -= minutes;
    }

    if (remaining >= constraints.practiceMinMinutes &&
        blocks.length < constraints.maxBlocksPerDay &&
        selected.isNotEmpty) {
      _Candidate? ultraCandidate;
      for (final candidate in selected) {
        if (candidate.ultraHardAvailable &&
            _ultraHardJustified(candidate.profile)) {
          ultraCandidate = candidate;
          break;
        }
      }

      final candidate = ultraCandidate ?? selected.first;
      final type = ultraCandidate == null
          ? StudyPlanBlockType.standardPractice
          : StudyPlanBlockType.ultraHardPractice;
      final minutes = remaining
          .clamp(constraints.practiceMinMinutes, constraints.practiceMaxMinutes)
          .toInt();

      blocks.add(
        _buildBlock(
          planId: planId,
          version: nextVersion,
          slot: slot++,
          candidate: candidate,
          type: type,
          minutes: minutes,
          generatedAt: generatedAt,
          extraReason: ultraCandidate == null
              ? 'ASSESSMENT_BALANCE'
              : 'ULTRA_HARD_GAP',
        ),
      );
      remaining -= minutes;
    }

    while (remaining >= constraints.practiceMinMinutes &&
        blocks.length < constraints.maxBlocksPerDay &&
        selected.isNotEmpty) {
      final candidate = selected[slot % selected.length];
      final minutes = remaining
          .clamp(constraints.practiceMinMinutes, constraints.practiceMaxMinutes)
          .toInt();
      blocks.add(
        _buildBlock(
          planId: planId,
          version: nextVersion,
          slot: slot++,
          candidate: candidate,
          type: StudyPlanBlockType.mixedRetrieval,
          minutes: minutes,
          generatedAt: generatedAt,
          extraReason: 'DAILY_BALANCE',
        ),
      );
      remaining -= minutes;
    }

    final plan = DailyStudyPlan(
      planId: planId,
      userId: userId,
      date: day,
      generatedAt: generatedAt,
      planVersion: nextVersion,
      plannerAlgorithmVersion: DailyStudyPlan.currentAlgorithmVersion,
      availableMinutes: normalizedAvailable,
      allocatedMinutes: blocks.fold<int>(
        0,
        (sum, block) => sum + block.plannedMinutes,
      ),
      generationReason: generationReason,
      sourceEvidenceVersion: _sourceEvidenceVersion(readinessProfiles),
      sourceReadinessVersion: _sourceReadinessVersion(readinessProfiles),
      inputSnapshotVersion:
          'e:${_sourceEvidenceVersion(readinessProfiles)}|'
          'r:${_sourceReadinessVersion(readinessProfiles)}',
      previousPlanId: existingPlan == null
          ? null
          : '${existingPlan.planId}:v${existingPlan.planVersion}',
      blocks: List<StudyPlanBlock>.unmodifiable(blocks),
      status: DailyStudyPlanStatus.active,
      schemaVersion: DailyStudyPlan.currentSchemaVersion,
    );

    plan.validate();
    _assertLockedBlocksPreserved(existingPlan, plan);
    return plan;
  }

  DailyStudyPlan startBlock(
    DailyStudyPlan plan,
    String blockId, {
    required DateTime at,
  }) {
    return _manualChange(
      plan,
      blockId,
      at: at,
      status: StudyPlanBlockStatus.started,
      action: StudyPlanManualAction.start,
      note: 'Learner started block.',
      startedAt: at,
    );
  }

  DailyStudyPlan skipBlock(
    DailyStudyPlan plan,
    String blockId, {
    required DateTime at,
  }) {
    return _manualChange(
      plan,
      blockId,
      at: at,
      status: StudyPlanBlockStatus.skipped,
      action: StudyPlanManualAction.skip,
      note: 'Learner skipped block.',
    );
  }

  DailyStudyPlan moveToTomorrow(
    DailyStudyPlan plan,
    String blockId, {
    required DateTime at,
  }) {
    return _manualChange(
      plan,
      blockId,
      at: at,
      status: StudyPlanBlockStatus.movedToTomorrow,
      action: StudyPlanManualAction.moveToTomorrow,
      note: 'Learner moved block to tomorrow.',
    );
  }

  DailyStudyPlan markUnavailable(
    DailyStudyPlan plan,
    String blockId, {
    required DateTime at,
  }) {
    return _manualChange(
      plan,
      blockId,
      at: at,
      status: StudyPlanBlockStatus.unavailable,
      action: StudyPlanManualAction.markUnavailable,
      note: 'Learner marked block unavailable.',
    );
  }

  DailyStudyPlan shortenBlock(
    DailyStudyPlan plan,
    String blockId, {
    required int newMinutes,
    required DateTime at,
  }) {
    if (newMinutes < constraints.practiceMinMinutes) {
      throw ArgumentError('Shortened block must retain at least 5 minutes.');
    }

    return _manualChange(
      plan,
      blockId,
      at: at,
      status: StudyPlanBlockStatus.shortened,
      action: StudyPlanManualAction.shorten,
      note: 'Learner shortened block.',
      newMinutes: newMinutes,
    );
  }

  DailyStudyPlan replaceWithAlternative(
    DailyStudyPlan plan,
    String blockId, {
    required DateTime at,
  }) {
    final target = _findBlock(plan, blockId);
    if (target.isLocked) {
      throw StateError('Started/completed blocks cannot be replaced.');
    }

    final alternativeType = target.type == StudyPlanBlockType.standardPractice
        ? StudyPlanBlockType.mixedRetrieval
        : StudyPlanBlockType.standardPractice;

    final replacement = target.copyWith(
      blockId: '${target.blockId}-replacement-v${plan.planVersion + 1}',
      type: alternativeType,
      status: StudyPlanBlockStatus.planned,
      createdAt: at,
      reasonCodes: <String>{
        ...target.reasonCodes,
        'LEARNER_REPLACED',
      }.toList(growable: false),
      reasonText:
          '${target.reasonText} Learner requested an alternative block.',
      manualChanges: [
        ...target.manualChanges,
        StudyPlanManualChange(
          action: StudyPlanManualAction.replace,
          changedAt: at,
          note: 'Learner replaced block.',
          previousMinutes: target.plannedMinutes,
          newMinutes: target.plannedMinutes,
        ),
      ],
    );

    final blocks = [
      for (final block in plan.blocks)
        if (block.blockId == blockId) replacement else block,
    ];

    return _nextManualVersion(plan, blocks, at);
  }

  DailyStudyPlan _manualChange(
    DailyStudyPlan plan,
    String blockId, {
    required DateTime at,
    required StudyPlanBlockStatus status,
    required StudyPlanManualAction action,
    required String note,
    DateTime? startedAt,
    int? newMinutes,
  }) {
    final target = _findBlock(plan, blockId);

    if (target.isLocked && action != StudyPlanManualAction.start) {
      throw StateError('Started/completed blocks are locked.');
    }
    if (action == StudyPlanManualAction.start && target.isLocked) {
      return plan;
    }
    if (newMinutes != null && newMinutes > target.plannedMinutes) {
      throw StateError('Shorten cannot increase block minutes.');
    }

    final changed = target.copyWith(
      plannedMinutes: newMinutes ?? target.plannedMinutes,
      status: status,
      startedAt: startedAt,
      manualChanges: [
        ...target.manualChanges,
        StudyPlanManualChange(
          action: action,
          changedAt: at,
          note: note,
          previousMinutes: target.plannedMinutes,
          newMinutes: newMinutes ?? target.plannedMinutes,
        ),
      ],
    );

    final blocks = [
      for (final block in plan.blocks)
        if (block.blockId == blockId) changed else block,
    ];
    return _nextManualVersion(plan, blocks, at);
  }

  DailyStudyPlan _nextManualVersion(
    DailyStudyPlan plan,
    List<StudyPlanBlock> blocks,
    DateTime at,
  ) {
    final next = plan.nextVersion(
      generatedAt: at,
      blocks: blocks,
      availableMinutes: plan.availableMinutes,
      generationReason: DailyStudyPlanGenerationReason.manualRequest,
      sourceEvidenceVersion: plan.sourceEvidenceVersion,
      sourceReadinessVersion: plan.sourceReadinessVersion,
    );
    next.validate();
    return next;
  }

  StudyPlanBlock _findBlock(DailyStudyPlan plan, String blockId) {
    for (final block in plan.blocks) {
      if (block.blockId == blockId) return block;
    }
    throw StateError('Study-plan block not found.');
  }

  StudyPlanBlockType _primaryType(CompetencyReadinessProfile? profile) {
    if (profile == null ||
        profile.readinessState == ReadinessState.unknown ||
        profile.readinessState == ReadinessState.insufficientEvidence ||
        profile.evidenceConfidence.rank <= EvidenceConfidence.low.rank) {
      return StudyPlanBlockType.diagnostic;
    }
    if (profile.readinessState == ReadinessState.stale) {
      return StudyPlanBlockType.competencyRecheck;
    }
    if (_hasPerformanceGap(profile)) {
      return StudyPlanBlockType.repair;
    }
    if (profile.blueprintCoverage.value == null ||
        profile.blueprintCoverage.value! < 0.70) {
      return StudyPlanBlockType.learn;
    }
    if (profile.readinessState == ReadinessState.strong ||
        profile.readinessState == ReadinessState.stable) {
      return StudyPlanBlockType.continueLearning;
    }
    return StudyPlanBlockType.standardPractice;
  }

  bool _hasPerformanceGap(CompetencyReadinessProfile profile) {
    return profile.gaps.any(
      (gap) =>
          !gap.evidenceLimited &&
          (gap.type == ReadinessGapType.masteryGap ||
              gap.type == ReadinessGapType.applicationGap ||
              gap.type == ReadinessGapType.difficultyGap),
    );
  }

  bool _needsRetention(CompetencyReadinessProfile? profile) {
    if (profile == null) return false;
    return profile.gaps.any(
      (gap) =>
          gap.type == ReadinessGapType.retentionGap ||
          gap.type == ReadinessGapType.stalenessGap,
    );
  }

  bool _ultraHardJustified(CompetencyReadinessProfile? profile) {
    if (profile == null ||
        profile.evidenceConfidence.rank < EvidenceConfidence.moderate.rank) {
      return false;
    }

    final ultra = profile.difficultyPerformance.ultraHardAccuracy;
    final application = profile.applicationAbility.value;

    return ultra == null ||
        ultra < 0.70 ||
        (application != null && application < 0.70);
  }

  int _minimumForType(StudyPlanBlockType type) {
    switch (type) {
      case StudyPlanBlockType.learn:
      case StudyPlanBlockType.continueLearning:
      case StudyPlanBlockType.repair:
      case StudyPlanBlockType.diagnostic:
        return constraints.learnMinMinutes;
      case StudyPlanBlockType.spacedReview:
        return constraints.reviewMinMinutes;
      default:
        return constraints.practiceMinMinutes;
    }
  }

  int _minutesForType(StudyPlanBlockType type, int remaining, int available) {
    switch (type) {
      case StudyPlanBlockType.learn:
      case StudyPlanBlockType.continueLearning:
        return _fit(
          (available * constraints.forwardLearningShare).round(),
          constraints.learnMinMinutes,
          constraints.learnMaxMinutes,
          remaining,
        );
      case StudyPlanBlockType.repair:
        return _fit(
          (available * constraints.repairShare).round(),
          constraints.learnMinMinutes,
          constraints.practiceMaxMinutes,
          remaining,
        );
      case StudyPlanBlockType.diagnostic:
        return _fit(
          15,
          constraints.learnMinMinutes,
          constraints.practiceMaxMinutes,
          remaining,
        );
      case StudyPlanBlockType.spacedReview:
        return _fit(
          (available * constraints.retentionShare).round(),
          constraints.reviewMinMinutes,
          constraints.reviewMaxMinutes,
          remaining,
        );
      default:
        return _fit(
          (available * constraints.assessmentShare).round(),
          constraints.practiceMinMinutes,
          constraints.practiceMaxMinutes,
          remaining,
        );
    }
  }

  int _fit(int target, int min, int max, int remaining) {
    if (remaining < min) return 0;
    return target.clamp(min, max).clamp(min, remaining).toInt();
  }

  StudyPlanBlock _buildBlock({
    required String planId,
    required int version,
    required int slot,
    required _Candidate candidate,
    required StudyPlanBlockType type,
    required int minutes,
    required DateTime generatedAt,
    String? extraReason,
  }) {
    if (type == StudyPlanBlockType.repair &&
        (candidate.profile == null ||
            candidate.profile!.evidenceConfidence.rank <=
                EvidenceConfidence.low.rank)) {
      throw StateError('Repair cannot be scheduled for unknown evidence.');
    }
    if (type == StudyPlanBlockType.ultraHardPractice &&
        !candidate.ultraHardAvailable) {
      throw StateError(
        'Ultra Hard block requires a published DQG300 Ultra Hard bank.',
      );
    }

    final reasonCodes = <String>{
      ...candidate.priority.reasonCodes,
      if (extraReason != null) extraReason,
      _typeReason(type),
    }.toList(growable: false);

    return StudyPlanBlock(
      blockId:
          '$planId-v$version-b${slot.toString().padLeft(2, '0')}-${candidate.competencyId}-${type.name}',
      type: type,
      domainId: candidate.domainId,
      competencyId: candidate.competencyId,
      subtopicId: '',
      topicId: '',
      plannedMinutes: minutes,
      questionCount: _questionCount(type, minutes),
      priorityScore: candidate.priority.totalScore,
      priorityBreakdown: candidate.priority,
      reasonCodes: reasonCodes,
      reasonText: _reasonText(candidate, reasonCodes),
      status: StudyPlanBlockStatus.planned,
      createdAt: generatedAt,
      manualChanges: const <StudyPlanManualChange>[],
    );
  }

  int _questionCount(StudyPlanBlockType type, int minutes) {
    switch (type) {
      case StudyPlanBlockType.diagnostic:
      case StudyPlanBlockType.standardPractice:
      case StudyPlanBlockType.ultraHardPractice:
      case StudyPlanBlockType.mixedRetrieval:
      case StudyPlanBlockType.competencyRecheck:
      case StudyPlanBlockType.confidenceCalibration:
      case StudyPlanBlockType.examSimulation:
        return (minutes ~/ 2).clamp(3, 10).toInt();
      default:
        return 0;
    }
  }

  String _typeReason(StudyPlanBlockType type) {
    switch (type) {
      case StudyPlanBlockType.diagnostic:
        return 'DIAGNOSTIC_NEEDED';
      case StudyPlanBlockType.repair:
        return 'TARGETED_REPAIR';
      case StudyPlanBlockType.spacedReview:
        return 'RETENTION_DUE';
      case StudyPlanBlockType.ultraHardPractice:
        return 'ULTRA_HARD_GAP';
      case StudyPlanBlockType.learn:
      case StudyPlanBlockType.continueLearning:
        return 'FORWARD_LEARNING';
      default:
        return 'ASSESSMENT_BALANCE';
    }
  }

  String _reasonText(_Candidate candidate, List<String> reasonCodes) {
    final parts = <String>[];
    if (reasonCodes.contains('HIGH_BLUEPRINT_PRIORITY')) {
      parts.add('high blueprint importance');
    }
    if (reasonCodes.contains('APPLICATION_GAP')) {
      parts.add('weaker application evidence');
    }
    if (reasonCodes.contains('RETENTION_DUE')) {
      parts.add('retention review is due');
    }
    if (reasonCodes.contains('EVIDENCE_DEBT')) {
      parts.add('more assessment evidence is needed');
    }
    if (reasonCodes.contains('STALE_EVIDENCE')) {
      parts.add('recent evidence is stale');
    }
    if (reasonCodes.contains('ULTRA_HARD_GAP')) {
      parts.add('Ultra Hard readiness evidence is limited');
    }
    if (parts.isEmpty) {
      parts.add('this is the highest current learning priority');
    }

    return '${candidate.competencyId.toUpperCase()} is scheduled because ${parts.join(', ')}.';
  }

  String _sourceEvidenceVersion(
    Map<String, CompetencyReadinessProfile> profiles,
  ) {
    if (profiles.isEmpty) return 'no-readiness-evidence';
    final latest = profiles.values
        .map((profile) => profile.generatedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    return latest.toUtc().toIso8601String();
  }

  String _sourceReadinessVersion(
    Map<String, CompetencyReadinessProfile> profiles,
  ) {
    final versions =
        profiles.values
            .map((profile) => profile.readinessAlgorithmVersion)
            .toSet()
            .toList()
          ..sort();
    return versions.isEmpty ? 'none' : versions.join('+');
  }

  void _assertLockedBlocksPreserved(
    DailyStudyPlan? previous,
    DailyStudyPlan next,
  ) {
    if (previous == null) return;
    final nextById = {for (final block in next.blocks) block.blockId: block};

    for (final block in previous.blocks.where((item) => item.isLocked)) {
      final retained = nextById[block.blockId];
      if (retained == null ||
          retained.toJson().toString() != block.toJson().toString()) {
        throw StateError('Started/completed block was silently replaced.');
      }
    }
  }

  String _safe(String value) =>
      value.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
}

class _Candidate {
  const _Candidate({
    required this.domainId,
    required this.competencyId,
    required this.profile,
    required this.priority,
    required this.ultraHardAvailable,
  });

  final String domainId;
  final String competencyId;
  final CompetencyReadinessProfile? profile;
  final LearningPriorityScore priority;
  final bool ultraHardAvailable;
}
