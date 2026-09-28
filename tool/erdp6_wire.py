from pathlib import Path


def patch(path, old, new, count=1):
    p = Path(path)
    s = p.read_text()
    if old not in s:
        raise SystemExit(f"Expected patch anchor missing in {path}: {old[:100]!r}")
    p.write_text(s.replace(old, new, count))


path = "lib/features/exam_readiness/models/competency_evidence_snapshot.dart"
patch(path, "import 'evidence_confidence.dart';\n", "import 'activity_evidence_stats.dart';\nimport 'evidence_confidence.dart';\n")
patch(path, "    required this.sourceAttemptCount,\n    required this.coverage,", "    required this.sourceAttemptCount,\n    this.activity = const ActivityEvidenceStats(),\n    required this.coverage,")
patch(path, "  final int sourceAttemptCount;\n  final EvidenceCoverage coverage;", "  final int sourceAttemptCount;\n  final ActivityEvidenceStats activity;\n  final EvidenceCoverage coverage;")
patch(path, "    'sourceAttemptCount': sourceAttemptCount,\n    'coverage': coverage.toJson(),", "    'sourceAttemptCount': sourceAttemptCount,\n    'activity': activity.toJson(),\n    'coverage': coverage.toJson(),")
patch(path, "      sourceAttemptCount: _int(json['sourceAttemptCount']),\n      coverage: EvidenceCoverage.fromJson(_map(json['coverage'])),", "      sourceAttemptCount: _int(json['sourceAttemptCount']),\n      activity: ActivityEvidenceStats.fromJson(_map(json['activity'])),\n      coverage: EvidenceCoverage.fromJson(_map(json['coverage'])),")

path = "lib/features/exam_readiness/services/learner_evidence_aggregation_service.dart"
patch(path, "import '../models/competency_evidence_snapshot.dart';\n", "import '../models/activity_evidence_stats.dart';\nimport '../models/competency_evidence_snapshot.dart';\n")
patch(path, "import '../models/learner_assessment_attempt.dart';\n", "import '../models/learner_assessment_attempt.dart';\nimport '../models/learning_evidence_event.dart';\n")
patch(path, "    required CompetencyEvidenceScope scope,\n    required DateTime now,\n  }) {", "    required CompetencyEvidenceScope scope,\n    required DateTime now,\n    Iterable<LearningEvidenceEvent> activityEvents =\n        const <LearningEvidenceEvent>[],\n  }) {", 1)
patch(path, "    final normalizedCompetency = competencyId.trim().toLowerCase();\n\n    final deduplicated", "    final normalizedCompetency = competencyId.trim().toLowerCase();\n    final activity = ActivityEvidenceStats.aggregate(\n      activityEvents.where(\n        (event) =>\n            event.competencyId.trim().toLowerCase() == normalizedCompetency,\n      ),\n    );\n\n    final deduplicated", 1)
patch(path, "      sourceAttemptCount: evidence.length,\n      coverage: coverage,", "      sourceAttemptCount: evidence.length,\n      activity: activity,\n      coverage: coverage,", 1)
patch(path, "      traceability: _traceability(\n        attempts: attemptStats,\n        coverage: coverage,\n        cognition: cognition,\n        difficulty: difficulty,\n        retention: retention,\n        recency: recency,\n        confidence: confidence,\n      ),", "      traceability: <String>[\n        ..._traceability(\n          attempts: attemptStats,\n          coverage: coverage,\n          cognition: cognition,\n          difficulty: difficulty,\n          retention: retention,\n          recency: recency,\n          confidence: confidence,\n        ),\n        'ACTIVITY_EVENTS:${activity.totalEvents}',\n        'ACTIVITY_STRONG:${activity.strongEvents}',\n        'ACTIVITY_SUPPORTING:${activity.supportingEvents}',\n        'ACTIVITY_CONTEXT:${activity.contextEvents}',\n        'ACTIVITY_ZERO_CREDIT:${activity.zeroCreditEvents}',\n      ],", 1)
patch(path, "    required Iterable<CompetencyEvidenceScope> scopes,\n    required DateTime now,\n  }) {", "    required Iterable<CompetencyEvidenceScope> scopes,\n    required DateTime now,\n    Iterable<LearningEvidenceEvent> activityEvents =\n        const <LearningEvidenceEvent>[],\n  }) {", 1)
patch(path, "        scope: scope,\n        now: now,\n      );\n    }\n\n    return Map<String, CompetencyEvidenceSnapshot>.unmodifiable(result);", "        scope: scope,\n        now: now,\n        activityEvents: activityEvents,\n      );\n    }\n\n    return Map<String, CompetencyEvidenceSnapshot>.unmodifiable(result);", 1)
patch(path, "    required CompetencyEvidenceScope scope,\n    required DateTime now,\n  }) {\n    return buildSnapshot(\n      competencyId: competencyId,\n      attempts: attemptsForCompetency,\n      scope: scope,\n      now: now,\n    );", "    required CompetencyEvidenceScope scope,\n    required DateTime now,\n    Iterable<LearningEvidenceEvent> activityEvents =\n        const <LearningEvidenceEvent>[],\n  }) {\n    return buildSnapshot(\n      competencyId: competencyId,\n      attempts: attemptsForCompetency,\n      scope: scope,\n      now: now,\n      activityEvents: activityEvents,\n    );", 1)
patch(path, "    DateTime? now,\n    bool syncRemote = true,\n  }) async {", "    DateTime? now,\n    bool syncRemote = true,\n    Iterable<LearningEvidenceEvent> activityEvents =\n        const <LearningEvidenceEvent>[],\n  }) async {", 1)
patch(path, "      scope: scope,\n      now: now ?? DateTime.now(),\n    );", "      scope: scope,\n      now: now ?? DateTime.now(),\n      activityEvents: activityEvents,\n    );", 1)
p = Path(path)
s = p.read_text()
start = s.index("  Future<Map<String, CompetencyEvidenceSnapshot>> rebuildAll({")
tail = s[start:]
old = "    DateTime? now,\n    bool syncRemote = true,\n  }) async {"
if old not in tail:
    raise SystemExit("rebuildAll signature anchor missing")
tail = tail.replace(old, "    DateTime? now,\n    bool syncRemote = true,\n    Iterable<LearningEvidenceEvent> activityEvents =\n        const <LearningEvidenceEvent>[],\n  }) async {", 1)
old = "      scopes: scopes,\n      now: now ?? DateTime.now(),\n    );"
if old not in tail:
    raise SystemExit("rebuildAll call anchor missing")
tail = tail.replace(old, "      scopes: scopes,\n      now: now ?? DateTime.now(),\n      activityEvents: activityEvents,\n    );", 1)
p.write_text(s[:start] + tail)

path = "lib/features/exam_readiness/services/readiness_profile_service.dart"
old = """  ReadinessDimension _applicationAbility(CompetencyEvidenceSnapshot evidence) {
    final attempts =
        evidence.cognition.applicationAttempts +
        evidence.cognition.analysisAttempts;

    if (attempts < 3 ||
        evidence.evidenceQuality.confidenceLevel.rank <
            EvidenceConfidence.low.rank) {
      return ReadinessDimension(
        code: 'APPLICATION_ABILITY',
        value: null,
        evidenceConfidence: evidence.evidenceQuality.confidenceLevel,
        reasonCodes: const ['INSUFFICIENT_APPLICATION_EVIDENCE'],
      );
    }

    final correct =
        evidence.cognition.applicationCorrect +
        evidence.cognition.analysisCorrect;
    final baseAccuracy = correct / attempts;

    final components = <(double, double)>[
      (baseAccuracy, 0.75),
      (evidence.coverage.coverageRatio, 0.15),
    ];

    if (evidence.difficulty.ultraHardAttempts >= 2 &&
        evidence.difficulty.ultraHardAccuracy != null) {
      components.add((evidence.difficulty.ultraHardAccuracy!, 0.10));
    } else if (evidence.difficulty.hardAttempts >= 2 &&
        evidence.difficulty.hardAccuracy != null) {
      components.add((evidence.difficulty.hardAccuracy!, 0.10));
    } else {
      components.add((_recencyFactor(evidence.recency.band), 0.10));
    }

    return ReadinessDimension(
      code: 'APPLICATION_ABILITY',
      value: _weighted(components),
      evidenceConfidence: evidence.evidenceQuality.confidenceLevel,
      reasonCodes: const ['APPLICATION_EVIDENCE_AVAILABLE'],
    );
  }
"""
new = """  ReadinessDimension _applicationAbility(CompetencyEvidenceSnapshot evidence) {
    final assessmentAttempts =
        evidence.cognition.applicationAttempts +
        evidence.cognition.analysisAttempts;
    final activitySamples = evidence.activity.strongApplicationSamples;

    if (assessmentAttempts < 3 && activitySamples == 0) {
      return ReadinessDimension(
        code: 'APPLICATION_ABILITY',
        value: null,
        evidenceConfidence: evidence.evidenceQuality.confidenceLevel,
        reasonCodes: const ['INSUFFICIENT_APPLICATION_EVIDENCE'],
      );
    }

    final components = <(double, double)>[];
    if (assessmentAttempts > 0) {
      final correct =
          evidence.cognition.applicationCorrect +
          evidence.cognition.analysisCorrect;
      components.add((correct / assessmentAttempts, 0.75));
    }
    if (activitySamples > 0 &&
        evidence.activity.strongApplicationAccuracy != null) {
      components.add((evidence.activity.strongApplicationAccuracy!, 0.55));
    }
    components.add((evidence.coverage.coverageRatio, 0.15));

    if (evidence.difficulty.ultraHardAttempts >= 2 &&
        evidence.difficulty.ultraHardAccuracy != null) {
      components.add((evidence.difficulty.ultraHardAccuracy!, 0.10));
    } else if (evidence.difficulty.hardAttempts >= 2 &&
        evidence.difficulty.hardAccuracy != null) {
      components.add((evidence.difficulty.hardAccuracy!, 0.10));
    } else {
      components.add((_recencyFactor(evidence.recency.band), 0.10));
    }

    return ReadinessDimension(
      code: 'APPLICATION_ABILITY',
      value: _weighted(components),
      evidenceConfidence: _strongestConfidence(
        evidence.evidenceQuality.confidenceLevel,
        _sampleConfidence(assessmentAttempts + activitySamples),
      ),
      reasonCodes: <String>[
        'APPLICATION_EVIDENCE_AVAILABLE',
        if (activitySamples > 0) 'STRONG_APPLIED_ACTIVITY_EVIDENCE',
      ],
    );
  }
"""
patch(path, old, new)
old = """  ReadinessDimension _retention(CompetencyEvidenceSnapshot evidence) {
    if (evidence.retention.delayedAttempts == 0 ||
        evidence.retention.delayedAccuracy == null) {
      return ReadinessDimension(
        code: 'RETENTION',
        value: null,
        evidenceConfidence: evidence.evidenceQuality.breakdown.retention,
        reasonCodes: const ['RETENTION_EVIDENCE_MISSING'],
      );
    }

    final volumeFactor = (evidence.retention.delayedAttempts / 8).clamp(
      0.25,
      1.0,
    );
    final score =
        evidence.retention.delayedAccuracy! * 0.85 + volumeFactor * 0.15;

    return ReadinessDimension(
      code: 'RETENTION',
      value: score.clamp(0, 1),
      evidenceConfidence: evidence.evidenceQuality.breakdown.retention,
      reasonCodes: const ['DELAYED_RETENTION_EVIDENCE_AVAILABLE'],
    );
  }
"""
new = """  ReadinessDimension _retention(CompetencyEvidenceSnapshot evidence) {
    if (evidence.retention.delayedAttempts == 0 ||
        evidence.retention.delayedAccuracy == null) {
      if (evidence.activity.supportingRetentionSamples > 0 &&
          evidence.activity.supportingRetentionAccuracy != null) {
        return ReadinessDimension(
          code: 'RETENTION',
          value: evidence.activity.supportingRetentionAccuracy,
          evidenceConfidence: _sampleConfidence(
            evidence.activity.supportingRetentionSamples,
          ),
          reasonCodes: const ['SPACED_FLASHCARD_RECALL_EVIDENCE'],
        );
      }
      return ReadinessDimension(
        code: 'RETENTION',
        value: null,
        evidenceConfidence: evidence.evidenceQuality.breakdown.retention,
        reasonCodes: evidence.activity.flashcardEvents > 0
            ? const ['FLASHCARD_SUPPORTING_EVIDENCE_REQUIRES_RECALL_QUALITY']
            : const ['RETENTION_EVIDENCE_MISSING'],
      );
    }

    final volumeFactor = (evidence.retention.delayedAttempts / 8).clamp(
      0.25,
      1.0,
    );
    final score =
        evidence.retention.delayedAccuracy! * 0.85 + volumeFactor * 0.15;

    return ReadinessDimension(
      code: 'RETENTION',
      value: score.clamp(0, 1),
      evidenceConfidence: evidence.evidenceQuality.breakdown.retention,
      reasonCodes: const ['DELAYED_RETENTION_EVIDENCE_AVAILABLE'],
    );
  }
"""
patch(path, old, new)
patch(path, "    if (evidence.sourceAttemptCount == 0) {\n      return ReadinessState.unknown;\n    }", "    if (evidence.sourceAttemptCount == 0 &&\n        evidence.activity.performanceBearingEvents == 0) {\n      return evidence.activity.creditableEvents > 0\n          ? ReadinessState.insufficientEvidence\n          : ReadinessState.unknown;\n    }")
patch(path, "  EvidenceConfidence _sampleConfidence(int samples) {", "  EvidenceConfidence _strongestConfidence(\n    EvidenceConfidence left,\n    EvidenceConfidence right,\n  ) => left.rank >= right.rank ? left : right;\n\n  EvidenceConfidence _sampleConfidence(int samples) {")
patch(path, "        if (evidence.sourceAttemptCount > 0) {\n          competenciesAssessed++;\n        }", "        if (evidence.sourceAttemptCount > 0 ||\n            evidence.activity.performanceBearingEvents > 0) {\n          competenciesAssessed++;\n        }", 2)

path = "lib/features/exam_readiness/services/learning_state_update_coordinator.dart"
patch(path, "import '../repositories/learner_assessment_attempt_repository.dart';\n", "import '../repositories/learner_assessment_attempt_repository.dart';\nimport '../repositories/learning_evidence_event_repository.dart';\n")
patch(path, "    LearningStateAuditRepository? auditRepository,\n  }) async {", "    LearningStateAuditRepository? auditRepository,\n    LearningEvidenceEventRepository? evidenceEventRepository,\n  }) async {")
patch(path, "    final audit = auditRepository ?? const LearningStateAuditRepository();\n\n    final recorded", "    final audit = auditRepository ?? const LearningStateAuditRepository();\n    final evidenceEvents =\n        evidenceEventRepository ?? const LearningEvidenceEventRepository();\n\n    final recorded")
patch(path, "    final attempts = await attemptsRepo.loadAll();\n    final scope = await scopeService.resolve(", "    final attempts = await attemptsRepo.loadAll();\n    final activityEvents = await evidenceEvents.loadAll(\n      competencyId: outcome.competencyId,\n    );\n    final scope = await scopeService.resolve(")
patch(path, "      scope: scope,\n      now: at,\n    );\n    await evidenceRepo.save(evidence, syncRemote: false);", "      scope: scope,\n      now: at,\n      activityEvents: activityEvents,\n    );\n    await evidenceRepo.save(evidence, syncRemote: false);", 1)

path = "lib/features/exam_readiness/models/daily_study_plan.dart"
patch(path, "    this.inputSnapshotVersion = '',\n  });", "    this.inputSnapshotVersion = '',\n    this.adaptationEvidenceEventId,\n  });")
patch(path, "  final String inputSnapshotVersion;\n", "  final String inputSnapshotVersion;\n  final String? adaptationEvidenceEventId;\n")
patch(path, "    String? inputSnapshotVersion,\n  }) {", "    String? inputSnapshotVersion,\n    String? adaptationEvidenceEventId,\n    bool clearAdaptationEvidenceEventId = false,\n  }) {")
patch(path, "      inputSnapshotVersion: inputSnapshotVersion ?? this.inputSnapshotVersion,\n    );", "      inputSnapshotVersion: inputSnapshotVersion ?? this.inputSnapshotVersion,\n      adaptationEvidenceEventId: clearAdaptationEvidenceEventId\n          ? null\n          : (adaptationEvidenceEventId ?? this.adaptationEvidenceEventId),\n    );")
patch(path, "    'inputSnapshotVersion': inputSnapshotVersion,\n  };", "    'inputSnapshotVersion': inputSnapshotVersion,\n    'adaptationEvidenceEventId': adaptationEvidenceEventId,\n  };")
patch(path, "      inputSnapshotVersion: json['inputSnapshotVersion']?.toString() ?? '',\n    );", "      inputSnapshotVersion: json['inputSnapshotVersion']?.toString() ?? '',\n      adaptationEvidenceEventId:\n          json['adaptationEvidenceEventId']?.toString(),\n    );")

path = "lib/features/exam_readiness/services/daily_study_plan_service.dart"
patch(path, "    DailyStudyPlanGenerationReason generationReason =\n        DailyStudyPlanGenerationReason.initial,\n  }) {", "    DailyStudyPlanGenerationReason generationReason =\n        DailyStudyPlanGenerationReason.initial,\n    String? adaptationEvidenceEventId,\n  }) {")
patch(path, "      inputSnapshotVersion:\n          'e:${_sourceEvidenceVersion(readinessProfiles)}|'\n          'r:${_sourceReadinessVersion(readinessProfiles)}',\n      previousPlanId:", "      inputSnapshotVersion:\n          'e:${_sourceEvidenceVersion(readinessProfiles)}|'\n          'r:${_sourceReadinessVersion(readinessProfiles)}',\n      adaptationEvidenceEventId: adaptationEvidenceEventId,\n      previousPlanId:")

path = "lib/features/exam_readiness/services/plan_replanning_service.dart"
patch(path, "    Set<String> recentlyStudiedCompetencyIds = const <String>{},\n", "    Set<String> recentlyStudiedCompetencyIds = const <String>{},\n    String? triggerEvidenceEventId,\n")
patch(path, "    final existing = await dailyRepo.loadLatestForDate(date);\n\n    var ultraAvailable", "    final existing = await dailyRepo.loadLatestForDate(date);\n    final triggerId = triggerEvidenceEventId?.trim();\n    if (existing != null &&\n        triggerId != null &&\n        triggerId.isNotEmpty &&\n        existing.adaptationEvidenceEventId == triggerId) {\n      return existing;\n    }\n\n    var ultraAvailable")
patch(path, "      generationReason: reason.dailyPlanReason,\n    );", "      generationReason: reason.dailyPlanReason,\n      adaptationEvidenceEventId: triggerId,\n    );")

path = "lib/features/exam_readiness/services/readiness_evidence_bootstrap_service.dart"
patch(path, "import '../models/learner_assessment_attempt.dart';\n", "import '../models/learner_assessment_attempt.dart';\nimport '../models/learning_evidence_event.dart';\n")
patch(path, "import '../repositories/learner_assessment_attempt_repository.dart';\n", "import '../repositories/learner_assessment_attempt_repository.dart';\nimport '../repositories/learning_evidence_event_repository.dart';\n")
patch(path, "    StudentQuestionProgressService? questionProgressService,\n    DateTime? now,\n  }) async {", "    StudentQuestionProgressService? questionProgressService,\n    LearningEvidenceEventRepository? learningEvidenceRepository,\n    DateTime? now,\n  }) async {")
patch(path, "    final attempts = await attemptRepository.loadAll();\n    final effectiveNow", "    final attempts = await attemptRepository.loadAll();\n    final activityEvents = await (\n      learningEvidenceRepository ?? const LearningEvidenceEventRepository()\n    ).loadAll();\n    final effectiveNow")
patch(path, "      attempts: attempts,\n      evidenceByCompetency: existingEvidence,\n      now: effectiveNow,", "      attempts: attempts,\n      activityEvents: activityEvents,\n      evidenceByCompetency: existingEvidence,\n      now: effectiveNow,")
patch(path, "    final scopes = await _buildScopes(attempts);\n    final snapshots = aggregationService.buildAllSnapshots(\n      attempts: attempts,\n      scopes: scopes,\n      now: effectiveNow,\n    );", "    final scopes = await _buildScopes(attempts, activityEvents);\n    final snapshots = aggregationService.buildAllSnapshots(\n      attempts: attempts,\n      scopes: scopes,\n      now: effectiveNow,\n      activityEvents: activityEvents,\n    );")
patch(path, "    required List<LearnerAssessmentAttempt> attempts,\n    required Map<String, CompetencyEvidenceSnapshot> evidenceByCompetency,", "    required List<LearnerAssessmentAttempt> attempts,\n    required List<LearningEvidenceEvent> activityEvents,\n    required Map<String, CompetencyEvidenceSnapshot> evidenceByCompetency,")
old = """    final represented = <String, List<LearnerAssessmentAttempt>>{};
    for (final attempt in attempts) {
      if (!attempt.publishedAtAttempt || !attempt.hasCanonicalCompetencyId) {
        continue;
      }

      final competencyId = attempt.competencyId.trim().toLowerCase();
      if (competencyForId(competencyId) == null) {
        continue;
      }

      represented
          .putIfAbsent(competencyId, () => <LearnerAssessmentAttempt>[])
          .add(attempt);
    }

    if (represented.isEmpty) {
      return false;
    }

    for (final entry in represented.entries) {
      final snapshot = evidenceByCompetency[entry.key];
      if (snapshot == null) {
        return true;
      }

      final latestAttempt = entry.value
          .map((attempt) => attempt.answeredAt)
          .reduce((left, right) => left.isAfter(right) ? left : right);

      if (latestAttempt.isAfter(snapshot.generatedAt)) {
        return true;
      }

      if (now.difference(snapshot.generatedAt).inHours >= 24) {
        return true;
      }
    }
"""
new = """    final represented = <String, List<DateTime>>{};
    for (final attempt in attempts) {
      if (!attempt.publishedAtAttempt || !attempt.hasCanonicalCompetencyId) {
        continue;
      }
      final competencyId = attempt.competencyId.trim().toLowerCase();
      if (competencyForId(competencyId) == null) continue;
      represented
          .putIfAbsent(competencyId, () => <DateTime>[])
          .add(attempt.answeredAt);
    }
    for (final event in activityEvents) {
      final competencyId = event.competencyId.trim().toLowerCase();
      if (competencyForId(competencyId) == null) continue;
      represented
          .putIfAbsent(competencyId, () => <DateTime>[])
          .add(event.occurredAt);
    }

    if (represented.isEmpty) return false;

    for (final entry in represented.entries) {
      final snapshot = evidenceByCompetency[entry.key];
      if (snapshot == null) return true;

      final latestEvidence = entry.value.reduce(
        (left, right) => left.isAfter(right) ? left : right,
      );
      if (latestEvidence.isAfter(snapshot.generatedAt)) return true;

      if (now.difference(snapshot.generatedAt).inHours >= 24) return true;
    }
"""
patch(path, old, new)
patch(path, "  Future<List<CompetencyEvidenceScope>> _buildScopes(\n    List<LearnerAssessmentAttempt> attempts,\n  ) async {\n    final representedCompetencies = attempts", "  Future<List<CompetencyEvidenceScope>> _buildScopes(\n    List<LearnerAssessmentAttempt> attempts,\n    List<LearningEvidenceEvent> activityEvents,\n  ) async {\n    final representedCompetencies = <String>{\n      ...attempts")
patch(path, "        .where((id) => competencyForId(id) != null)\n        .toSet();", "        .where((id) => competencyForId(id) != null),\n      ...activityEvents\n          .map((event) => event.competencyId.trim().toLowerCase())\n          .where((id) => competencyForId(id) != null),\n    };")
patch(path, "    final sorted = representedCompetencies.toList()..sort();", "    for (final event in activityEvents) {\n      final competencyId = event.competencyId.trim().toLowerCase();\n      if (!representedCompetencies.contains(competencyId)) continue;\n      if (event.topicId.trim().isNotEmpty) {\n        topics[competencyId]!.add(event.topicId.trim());\n      }\n      if (event.subtopicId.trim().isNotEmpty) {\n        subtopics[competencyId]!.add(event.subtopicId.trim());\n      }\n    }\n\n    final sorted = representedCompetencies.toList()..sort();")

path = "lib/features/exam_readiness/screens/todays_plan_screen.dart"
patch(path, "import '../services/daily_study_plan_service.dart';\n", "import '../services/closed_evidence_loop_coordinator.dart';\nimport '../services/daily_study_plan_service.dart';\n")
patch(path, "    this.learningStateCoordinator = const LearningStateUpdateCoordinator(),\n    this.completionEvidenceService", "    this.learningStateCoordinator = const LearningStateUpdateCoordinator(),\n    this.closedEvidenceLoopCoordinator,\n    this.completionEvidenceService")
patch(path, "  final LearningStateUpdateCoordinator learningStateCoordinator;\n  final StudyPlanCompletionEvidenceService completionEvidenceService;", "  final LearningStateUpdateCoordinator learningStateCoordinator;\n  final ClosedEvidenceLoopCoordinator? closedEvidenceLoopCoordinator;\n  final StudyPlanCompletionEvidenceService completionEvidenceService;")
patch(path, "  DateTime get _now => widget.now?.call() ?? DateTime.now();\n", "  ClosedEvidenceLoopCoordinator get _closedEvidenceLoopCoordinator =>\n      widget.closedEvidenceLoopCoordinator ??\n      ClosedEvidenceLoopCoordinator(\n        stateCoordinator: widget.learningStateCoordinator,\n      );\n\n  DateTime get _now => widget.now?.call() ?? DateTime.now();\n")
old = """      if (block.status == StudyPlanBlockStatus.completed) {
        return true;
      }
      if (block.status != StudyPlanBlockStatus.started) {
        return false;
      }

      final at = _now;
      final attempts = await _attemptRepository.loadAll();
"""
new = """      final at = block.completedAt ?? _now;
      final attempts = await _attemptRepository.loadAll();

      if (block.status == StudyPlanBlockStatus.completed) {
        final outcome = widget.outcomeService.build(
          plan: plan,
          block: block,
          attempts: attempts,
          completedAt: at,
          assessmentSessionKind:
              source == StudyPlanCompletionEvidenceSource.plannedPracticeSession
              ? StudyPlanCompletionEvidenceService.sessionKindForBlock(blockId)
              : null,
        );
        final loop = await _closedEvidenceLoopCoordinator.processCompletion(
          completedPlan: plan,
          completedBlock: block,
          outcome: outcome,
          attemptRepository: _attemptRepository,
          readinessRepository: _readinessRepository,
          dailyPlanRepository: _dailyPlanRepository,
          examPlanRepository: _examPlanRepository,
        );
        final latest = loop.adaptedPlan ?? plan;
        if (mounted) {
          setState(
            () => _future = Future.value(
              _TodayPlanViewData(
                plan: latest,
                hasExamPlan: true,
                notice: 'Evidence loop verified and the plan is current.',
              ),
            ),
          );
        }
        return true;
      }
      if (block.status != StudyPlanBlockStatus.started) return false;

"""
patch(path, old, new)
old = """      final update = await widget.learningStateCoordinator.processOutcome(
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

      if (!mounted) return true;
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
"""
new = """      final changed = widget.planService.completeBlock(plan, blockId, at: at);
      await _dailyPlanRepository.savePlan(changed, syncRemote: false);
      final completedBlock = changed.blocks.firstWhere(
        (item) => item.blockId == blockId,
      );

      final loop = await _closedEvidenceLoopCoordinator.processCompletion(
        completedPlan: changed,
        completedBlock: completedBlock,
        outcome: outcome,
        attemptRepository: _attemptRepository,
        readinessRepository: _readinessRepository,
        dailyPlanRepository: _dailyPlanRepository,
        examPlanRepository: _examPlanRepository,
      );
      final update = loop.learningStateUpdate;
      final latest = loop.adaptedPlan ?? changed;

      final signalNotice = update.misconceptionSignals.isEmpty
          ? ''
          : ' A misconception or confidence pattern was detected.';
      final adaptationNotice = loop.replanned
          ? ' Today\'s remaining plan was recalibrated.'
          : ' Updated evidence will shape the next plan.';

      if (!mounted) return true;
      setState(
        () => _future = Future.value(
          _TodayPlanViewData(
            plan: latest,
            hasExamPlan: true,
            notice:
                'Readiness updated for ${block.competencyId.toUpperCase()}.$signalNotice$adaptationNotice',
          ),
        ),
      );
"""
patch(path, old, new)
