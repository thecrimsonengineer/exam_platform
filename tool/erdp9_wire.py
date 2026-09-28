from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    p = Path(path)
    source = p.read_text()
    if old not in source:
        raise SystemExit(f'ERDP-9 anchor missing in {path}: {old[:120]!r}')
    p.write_text(source.replace(old, new, 1))


# Queue safety when every learned card is still ahead of its review interval.
replace_once(
    'lib/features/flashcards/learning/flashcard_review_queue_service.dart',
    "    final requested = targetCardCount <= 0\n        ? eligible.length\n        : targetCardCount.clamp(1, eligible.length).toInt();\n",
    "    if (eligible.isEmpty) return const <FlashcardCard>[];\n\n"
    "    final requested = targetCardCount <= 0\n        ? eligible.length\n        : targetCardCount.clamp(1, eligible.length).toInt();\n",
)

# LearningEvidenceEvent v2 carries optional card/session traceability and permits
# standalone Flashcard evidence without fabricating a DailyStudyPlan ID.
p = Path('lib/features/exam_readiness/models/learning_evidence_event.dart')
s = p.read_text()
s = s.replace(
    "    required this.signalCodes,\n    this.performanceScore,\n",
    "    required this.signalCodes,\n    this.evidenceUnitId,\n    this.sourceSessionId,\n    this.attemptSequence,\n    this.spacingIntervalDays,\n    this.sameSessionRepeat = false,\n    this.performanceScore,\n",
    1,
)
s = s.replace('  static const int currentSchemaVersion = 1;\n', '  static const int currentSchemaVersion = 2;\n', 1)
s = s.replace(
    "  final List<String> signalCodes;\n  final int schemaVersion;\n",
    "  final List<String> signalCodes;\n  final String? evidenceUnitId;\n  final String? sourceSessionId;\n  final int? attemptSequence;\n  final int? spacingIntervalDays;\n  final bool sameSessionRepeat;\n  final int schemaVersion;\n",
    1,
)
s = s.replace(
    "    if (evidenceEventId.trim().isEmpty ||\n        sourceOutcomeId.trim().isEmpty ||\n        planId.trim().isEmpty ||\n        blockId.trim().isEmpty) {\n      throw StateError('Learning evidence identifiers cannot be blank.');\n    }\n",
    "    if (evidenceEventId.trim().isEmpty ||\n        sourceOutcomeId.trim().isEmpty ||\n        blockId.trim().isEmpty) {\n      throw StateError('Learning evidence identifiers cannot be blank.');\n    }\n"
    "    if (sourceKind != LearningEvidenceSourceKind.flashcard &&\n        planId.trim().isEmpty) {\n      throw StateError('Planned learning evidence requires a plan ID.');\n    }\n",
    1,
)
s = s.replace(
    "    if (planVersion < 1 ||\n        questionsAttempted < 0 ||\n",
    "    if (planVersion < 0 ||\n        questionsAttempted < 0 ||\n",
    1,
)
s = s.replace(
    "    if (questionsCorrect > questionsAttempted) {\n      throw StateError('Correct questions cannot exceed attempted questions.');\n    }\n",
    "    if (sourceKind != LearningEvidenceSourceKind.flashcard &&\n        planVersion < 1) {\n      throw StateError('Planned learning evidence requires plan version one or higher.');\n    }\n"
    "    if (questionsCorrect > questionsAttempted) {\n      throw StateError('Correct questions cannot exceed attempted questions.');\n    }\n"
    "    if (attemptSequence != null && attemptSequence! < 1) {\n      throw StateError('Evidence attempt sequence must start at one.');\n    }\n"
    "    if (spacingIntervalDays != null && spacingIntervalDays! < 0) {\n      throw StateError('Evidence spacing interval cannot be negative.');\n    }\n"
    "    if (sameSessionRepeat &&\n        (sourceKind != LearningEvidenceSourceKind.flashcard ||\n            attemptSequence == null ||\n            attemptSequence! < 2 ||\n            spacingIntervalDays != null)) {\n      throw StateError('Same-session Flashcard repeats cannot claim spaced credit.');\n    }\n",
    1,
)
s = s.replace(
    "      'signalCodes': signalCodes,\n      'schemaVersion': schemaVersion,\n",
    "      'signalCodes': signalCodes,\n      'evidenceUnitId': evidenceUnitId,\n      'sourceSessionId': sourceSessionId,\n      'attemptSequence': attemptSequence,\n      'spacingIntervalDays': spacingIntervalDays,\n      'sameSessionRepeat': sameSessionRepeat,\n      'schemaVersion': schemaVersion,\n",
    1,
)
s = s.replace(
    "      signalCodes: _strings(json['signalCodes']),\n      schemaVersion: _int(json['schemaVersion'], currentSchemaVersion),\n",
    "      signalCodes: _strings(json['signalCodes']),\n      evidenceUnitId: _nullableString(json['evidenceUnitId']),\n      sourceSessionId: _nullableString(json['sourceSessionId']),\n      attemptSequence: _nullableInt(json['attemptSequence']),\n      spacingIntervalDays: _nullableInt(json['spacingIntervalDays']),\n      sameSessionRepeat: json['sameSessionRepeat'] == true,\n      schemaVersion: _int(json['schemaVersion'], currentSchemaVersion),\n",
    1,
)
s += "\nint? _nullableInt(dynamic value) {\n  if (value == null) return null;\n  if (value is num) return value.toInt();\n  return int.tryParse(value.toString());\n}\n\nString? _nullableString(dynamic value) {\n  final text = value?.toString().trim() ?? '';\n  return text.isEmpty ? null : text;\n}\n"
p.write_text(s)

# Activity statistics preserve breadth and true spacing for supporting recall.
p = Path('lib/features/exam_readiness/models/activity_evidence_stats.dart')
s = p.read_text()
s = s.replace(
    "    this.supportingRetentionSamples = 0,\n    this.supportingRetentionAccuracy,\n    this.lastEvidenceAt,\n",
    "    this.supportingRetentionSamples = 0,\n    this.supportingRetentionAccuracy,\n    this.supportingRetentionDistinctUnits = 0,\n    this.supportingRetentionSpacedSamples = 0,\n    this.lastEvidenceAt,\n",
    1,
)
s = s.replace(
    "  final int supportingRetentionSamples;\n  final double? supportingRetentionAccuracy;\n  final DateTime? lastEvidenceAt;\n",
    "  final int supportingRetentionSamples;\n  final double? supportingRetentionAccuracy;\n  final int supportingRetentionDistinctUnits;\n  final int supportingRetentionSpacedSamples;\n  final DateTime? lastEvidenceAt;\n",
    1,
)
s = s.replace(
    "    'supportingRetentionAccuracy': supportingRetentionAccuracy,\n    'lastEvidenceAt': lastEvidenceAt?.toIso8601String(),\n",
    "    'supportingRetentionAccuracy': supportingRetentionAccuracy,\n    'supportingRetentionDistinctUnits': supportingRetentionDistinctUnits,\n    'supportingRetentionSpacedSamples': supportingRetentionSpacedSamples,\n    'lastEvidenceAt': lastEvidenceAt?.toIso8601String(),\n",
    1,
)
s = s.replace(
    "      supportingRetentionAccuracy: _nullableDouble(\n        json['supportingRetentionAccuracy'],\n      ),\n      lastEvidenceAt: DateTime.tryParse(\n",
    "      supportingRetentionAccuracy: _nullableDouble(\n        json['supportingRetentionAccuracy'],\n      ),\n      supportingRetentionDistinctUnits: _int(\n        json['supportingRetentionDistinctUnits'],\n      ),\n      supportingRetentionSpacedSamples: _int(\n        json['supportingRetentionSpacedSamples'],\n      ),\n      lastEvidenceAt: DateTime.tryParse(\n",
    1,
)
s = s.replace(
    "    final retentionScores = <double>[];\n    DateTime? latest;\n",
    "    final retentionScores = <double>[];\n    final retentionUnitIds = <String>{};\n    var spacedRetentionSamples = 0;\n    DateTime? latest;\n",
    1,
)
s = s.replace(
    "      if (event.sourceKind == LearningEvidenceSourceKind.flashcard &&\n          event.retentionScore != null) {\n        retentionScores.add(event.retentionScore!);\n      }\n",
    "      if (event.sourceKind == LearningEvidenceSourceKind.flashcard &&\n          event.retentionScore != null) {\n        retentionScores.add(event.retentionScore!);\n        final unitId = event.evidenceUnitId?.trim() ?? '';\n        if (unitId.isNotEmpty) retentionUnitIds.add(unitId);\n        if ((event.spacingIntervalDays ?? 0) >= 1) spacedRetentionSamples++;\n      }\n",
    1,
)
s = s.replace(
    "      supportingRetentionSamples: retentionScores.length,\n      supportingRetentionAccuracy: average(retentionScores),\n      lastEvidenceAt: latest,\n",
    "      supportingRetentionSamples: retentionScores.length,\n      supportingRetentionAccuracy: average(retentionScores),\n      supportingRetentionDistinctUnits: retentionUnitIds.length,\n      supportingRetentionSpacedSamples: spacedRetentionSamples,\n      lastEvidenceAt: latest,\n",
    1,
)
p.write_text(s)

# Flashcard supporting evidence needs minimum breadth. Delayed question evidence
# remains authoritative whenever it exists.
p = Path('lib/features/exam_readiness/services/readiness_profile_service.dart')
s = p.read_text()
old = """      if (evidence.activity.supportingRetentionSamples > 0 &&
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
"""
new = """      final samples = evidence.activity.supportingRetentionSamples;
      final distinctUnits = evidence.activity.supportingRetentionDistinctUnits;
      final spacedSamples = evidence.activity.supportingRetentionSpacedSamples;
      final supportingAccuracy = evidence.activity.supportingRetentionAccuracy;
      if (samples >= 3 && distinctUnits >= 2 && supportingAccuracy != null) {
        final volumeFactor = (samples / 8).clamp(0.35, 1.0);
        final spacingFactor = (spacedSamples / 3).clamp(0.0, 1.0);
        final supportFactor = 0.75 + volumeFactor * 0.15 + spacingFactor * 0.10;
        return ReadinessDimension(
          code: 'RETENTION',
          value: (supportingAccuracy * supportFactor).clamp(0.0, 1.0),
          evidenceConfidence: _sampleConfidence(samples),
          reasonCodes: const <String>[
            'SPACED_FLASHCARD_RECALL_EVIDENCE',
            'FLASHCARD_SUPPORTING_ONLY',
          ],
        );
      }
      return ReadinessDimension(
        code: 'RETENTION',
        value: null,
        evidenceConfidence: evidence.evidenceQuality.breakdown.retention,
        reasonCodes: evidence.activity.flashcardEvents > 0
            ? const ['FLASHCARD_RETENTION_EVIDENCE_BUILDING']
            : const ['RETENTION_EVIDENCE_MISSING'],
      );
"""
if old not in s:
    raise SystemExit('ERDP-9 readiness retention anchor missing')
p.write_text(s.replace(old, new, 1))

# Allow card-level activity evidence to refresh learner state without inventing a
# StudyPlanBlockOutcome or triggering a replan per tap.
p = Path('lib/features/exam_readiness/services/learning_state_update_coordinator.dart')
s = p.read_text()
import_anchor = "import '../models/learning_state_update_event.dart';\n"
if "import '../models/learning_evidence_event.dart';\n" not in s:
    s = s.replace(import_anchor, "import '../models/learning_evidence_event.dart';\n" + import_anchor, 1)
method_anchor = '  PlanRegenerationReason _reason({\n'
method = """  Future<LearningStateUpdateResult> processEvidenceEvent({
    required LearningEvidenceEvent event,
    bool markFuturePlansStale = false,
    LearnerAssessmentAttemptRepository? attemptRepository,
    EvidenceSnapshotRepository? evidenceRepository,
    ReadinessSnapshotRepository? readinessRepository,
    DailyStudyPlanRepository? planRepository,
    LearningStateAuditRepository? auditRepository,
    LearningEvidenceEventRepository? evidenceEventRepository,
  }) async {
    event.validate();
    final attemptsRepo =
        attemptRepository ?? const LearnerAssessmentAttemptRepository();
    final evidenceRepo = evidenceRepository ?? EvidenceSnapshotRepository();
    final readinessRepo = readinessRepository ?? ReadinessSnapshotRepository();
    final plansRepo = planRepository ?? DailyStudyPlanRepository();
    final audit = auditRepository ?? const LearningStateAuditRepository();
    final evidenceEvents =
        evidenceEventRepository ?? const LearningEvidenceEventRepository();

    final recorded = await evidenceEvents.append(event);
    final previous = await readinessRepo.load(event.competencyId);
    final attempts = await attemptsRepo.loadAll();
    final activityEvents = await evidenceEvents.loadAll(
      competencyId: event.competencyId,
    );
    final scope = await scopeService.resolve(
      competencyId: event.competencyId,
      attempts: attempts,
    );
    final evidence = aggregationService.updateCompetencySnapshot(
      competencyId: event.competencyId,
      attemptsForCompetency: attempts,
      scope: scope,
      now: event.occurredAt,
      activityEvents: activityEvents,
    );
    await evidenceRepo.save(evidence, syncRemote: false);

    final profile = readinessService.buildCompetencyProfile(
      evidence: evidence,
      attempts: attempts,
      now: event.occurredAt,
    );
    await readinessRepo.save(profile, syncRemote: false);

    final reason = _reason(
      previous: previous,
      next: profile,
      signals: const <MisconceptionSignal>[],
    );
    final staleCount = markFuturePlansStale
        ? await stalenessService.markFuturePlansStale(
            afterDate: event.occurredAt,
            reason: reason,
            at: event.occurredAt,
            repository: plansRepo,
          )
        : 0;

    final auditEvent = LearningStateUpdateEvent(
      eventId: 'm7e-${event.evidenceEventId}',
      outcomeId: event.sourceOutcomeId,
      competencyId: profile.competencyId,
      occurredAt: event.occurredAt,
      regenerationReason: reason,
      previousReadinessState: previous?.readinessState.name,
      nextReadinessState: profile.readinessState.name,
      previousKnowledge: previous?.knowledgeMastery.value,
      nextKnowledge: profile.knowledgeMastery.value,
      previousApplication: previous?.applicationAbility.value,
      nextApplication: profile.applicationAbility.value,
      previousRetention: previous?.retention.value,
      nextRetention: profile.retention.value,
      stalePlanVersionsCreated: staleCount,
      misconceptionCodes: const <String>[],
      reasonCodes: <String>{
        ...profile.explanationCodes,
        'FLASHCARD_RETENTION_EVIDENCE_REFRESH',
        reason.name,
      }.toList(growable: false),
    );
    await audit.append(auditEvent);

    return LearningStateUpdateResult(
      outcomeRecorded: recorded,
      competencyId: profile.competencyId,
      profile: profile,
      regenerationReason: reason,
      misconceptionSignals: const <MisconceptionSignal>[],
      stalePlanVersionsCreated: staleCount,
      auditEvent: auditEvent,
    );
  }

"""
if method_anchor not in s:
    raise SystemExit('ERDP-9 state coordinator anchor missing')
s = s.replace(method_anchor, method + method_anchor, 1)
p.write_text(s)

# Let the Flashcard service delegate persistence + state refresh atomically to
# the evidence coordinator for score-bearing recall samples.
p = Path('lib/features/exam_readiness/services/flashcard_retention_evidence_service.dart')
s = p.read_text()
old = """    final recallRecorded = await _recallRepository.append(recall);
    final evidence = toLearningEvidence(recall);
    final evidenceRecorded = await _evidenceRepository.append(evidence);

    LearningStateUpdateResult? stateUpdate;
    if (evidence.retentionScore != null && evidenceRecorded) {
      stateUpdate = await _stateCoordinator.processEvidenceEvent(
        event: evidence,
        markFuturePlansStale: false,
        evidenceEventRepository: _evidenceRepository,
      );
    }
"""
new = """    final recallRecorded = await _recallRepository.append(recall);
    final evidence = toLearningEvidence(recall);

    LearningStateUpdateResult? stateUpdate;
    late final bool evidenceRecorded;
    if (evidence.retentionScore != null) {
      stateUpdate = await _stateCoordinator.processEvidenceEvent(
        event: evidence,
        markFuturePlansStale: false,
        evidenceEventRepository: _evidenceRepository,
      );
      evidenceRecorded = stateUpdate.outcomeRecorded;
    } else {
      evidenceRecorded = await _evidenceRepository.append(evidence);
    }
"""
if old not in s:
    raise SystemExit('ERDP-9 retention persistence anchor missing')
p.write_text(s.replace(old, new, 1))

# Daily Plan completion requires real first-attempt card ratings from the exact
# planned Remember block.
p = Path('lib/features/exam_readiness/services/study_plan_completion_evidence_service.dart')
s = p.read_text()
if "flashcard_recall_event.dart" not in s:
    s = s.replace(
        "import '../../../models/student_learning_progress.dart';\n",
        "import '../../../models/student_learning_progress.dart';\n"
        "import '../../flashcards/learning/flashcard_recall_event.dart';\n",
        1,
    )
s = s.replace(
    '  plannedPracticeSession,\n  labScenarioCompleted,\n',
    '  plannedPracticeSession,\n  flashcardReviewSession,\n  labScenarioCompleted,\n',
    1,
)
s = s.replace(
    "      case TodayPlanTaskCategory.remember:\n        return 'Complete a reviewed subtopic to finish this review task.';\n",
    "      case TodayPlanTaskCategory.remember:\n        return 'Rate the assigned Flashcards to finish this Remember task.';\n",
    1,
)
s = s.replace(
    "    required Iterable<StudentSubtopicProgress> studyProgress,\n    required DateTime completedAt,\n",
    "    required Iterable<StudentSubtopicProgress> studyProgress,\n    Iterable<FlashcardRecallEvent> flashcardRecallEvents =\n        const <FlashcardRecallEvent>[],\n    required DateTime completedAt,\n",
    1,
)
case_anchor = "      case StudyPlanCompletionEvidenceSource.labScenarioCompleted:\n"
flash_case = """      case StudyPlanCompletionEvidenceSource.flashcardReviewSession:
        if (category != TodayPlanTaskCategory.remember) {
          return const StudyPlanCompletionDecision.blocked(
            'Flashcard review evidence can complete only a Remember task.',
          );
        }
        return _flashcardDecision(
          block: block,
          recallEvents: flashcardRecallEvents,
          startedAt: startedAt,
          completedAt: completedAt,
        );

"""
if case_anchor not in s:
    raise SystemExit('ERDP-9 completion switch anchor missing')
s = s.replace(case_anchor, flash_case + case_anchor, 1)
method_anchor = '  StudyPlanCompletionDecision _practiceDecision({\n'
flash_method = """  StudyPlanCompletionDecision _flashcardDecision({
    required StudyPlanBlock block,
    required Iterable<FlashcardRecallEvent> recallEvents,
    required DateTime startedAt,
    required DateTime completedAt,
  }) {
    final competency = block.competencyId.trim().toLowerCase();
    final reviewedCards = <String>{};
    for (final event in recallEvents) {
      if (event.source != FlashcardReviewSource.dailyPlan ||
          event.blockId != block.blockId ||
          event.competencyId != competency ||
          event.sameSessionRepeat ||
          event.attemptSequence != 1 ||
          event.occurredAt.isBefore(startedAt) ||
          event.occurredAt.isAfter(completedAt)) {
        continue;
      }
      reviewedCards.add(event.cardId);
    }

    final requiredCards = (block.plannedMinutes ~/ 3).clamp(3, 8).toInt();
    if (reviewedCards.length < requiredCards) {
      return StudyPlanCompletionDecision.blocked(
        'Rate at least $requiredCards assigned Flashcards first. '
        '${reviewedCards.length} qualifying cards are recorded.',
      );
    }

    return StudyPlanCompletionDecision.allowed(
      message:
          '${reviewedCards.length} distinct Flashcard ratings provide completion evidence.',
    );
  }

"""
if method_anchor not in s:
    raise SystemExit('ERDP-9 completion method anchor missing')
s = s.replace(method_anchor, flash_method + method_anchor, 1)
p.write_text(s)

# StudyPlanBlockLauncher carries the existing Flashcard target policy into the
# production review screen and exposes a completion callback.
p = Path('lib/features/exam_readiness/navigation/study_plan_block_launcher.dart')
s = p.read_text()
s = s.replace(
    "      dueOnly: kind == StudyPlanExecutionTargetKind.flashcardReview,\n      reviewReason: kind == StudyPlanExecutionTargetKind.flashcardReview\n",
    "      dueOnly: kind == StudyPlanExecutionTargetKind.flashcardReview,\n"
    "      weakOnly: kind == StudyPlanExecutionTargetKind.flashcardReview &&\n"
    "          block.reasonCodes.any(\n"
    "            (reason) => reason.trim().toUpperCase().contains('RETENTION'),\n"
    "          ),\n"
    "      targetCardCount: kind == StudyPlanExecutionTargetKind.flashcardReview\n"
    "          ? (block.plannedMinutes ~/ 2).clamp(3, 10).toInt()\n"
    "          : null,\n"
    "      reviewReason: kind == StudyPlanExecutionTargetKind.flashcardReview\n",
    1,
)
s = s.replace(
    "    Future<void> Function()? onPracticeSessionCompleted,\n    Future<void> Function(double applicationAccuracy)? onLabCompleted,\n",
    "    Future<void> Function()? onPracticeSessionCompleted,\n"
    "    Future<void> Function()? onFlashcardReviewCompleted,\n"
    "    Future<void> Function(double applicationAccuracy)? onLabCompleted,\n",
    1,
)
s = s.replace(
    "      onPracticeSessionCompleted: onPracticeSessionCompleted,\n      onLabCompleted: onLabCompleted,\n",
    "      onPracticeSessionCompleted: onPracticeSessionCompleted,\n"
    "      onFlashcardReviewCompleted: onFlashcardReviewCompleted,\n"
    "      onLabCompleted: onLabCompleted,\n",
    1,
)
# second signature occurrence
signature = "    Future<void> Function()? onPracticeSessionCompleted,\n    Future<void> Function(double applicationAccuracy)? onLabCompleted,\n"
if signature in s:
    s = s.replace(
        signature,
        "    Future<void> Function()? onPracticeSessionCompleted,\n"
        "    Future<void> Function()? onFlashcardReviewCompleted,\n"
        "    Future<void> Function(double applicationAccuracy)? onLabCompleted,\n",
        1,
    )
s = s.replace(
    "        FlashcardCompetencyReviewScreen(\n          competencyId: target.competencyId,\n          isDarkMode: isDarkMode,\n        ),\n",
    "        FlashcardCompetencyReviewScreen(\n"
    "          competencyId: target.competencyId,\n"
    "          isDarkMode: isDarkMode,\n"
    "          plannedBlockId: target.blockId,\n"
    "          targetCardCount: target.targetCardCount,\n"
    "          dueOnly: target.dueOnly,\n"
    "          weakOnly: target.weakOnly,\n"
    "          onReviewSessionCompleted: onFlashcardReviewCompleted,\n"
    "        ),\n",
    1,
)
p.write_text(s)

# Flutter execution navigator forwards Flashcard completion through the same
# router surface used by practice and LAB.
p = Path('lib/features/exam_readiness/navigation/flutter_study_plan_execution_navigator.dart')
s = p.read_text()
s = s.replace(
    "typedef PracticeCompletionCallback =\n    Future<void> Function(StudyPlanExecutionTarget target);\n",
    "typedef PracticeCompletionCallback =\n    Future<void> Function(StudyPlanExecutionTarget target);\n"
    "typedef FlashcardCompletionCallback =\n    Future<void> Function(StudyPlanExecutionTarget target);\n",
    1,
)
s = s.replace(
    "    this.onPracticeSessionCompleted,\n    this.onLabCompleted,\n",
    "    this.onPracticeSessionCompleted,\n"
    "    this.onFlashcardReviewCompleted,\n"
    "    this.onLabCompleted,\n",
    1,
)
s = s.replace(
    "  final PracticeCompletionCallback? onPracticeSessionCompleted;\n  final LabCompletionCallback? onLabCompleted;\n",
    "  final PracticeCompletionCallback? onPracticeSessionCompleted;\n"
    "  final FlashcardCompletionCallback? onFlashcardReviewCompleted;\n"
    "  final LabCompletionCallback? onLabCompleted;\n",
    1,
)
s = s.replace(
    "      onLabCompleted:\n",
    "      onFlashcardReviewCompleted:\n"
    "          target.kind == StudyPlanExecutionTargetKind.flashcardReview &&\n"
    "              onFlashcardReviewCompleted != null\n"
    "          ? () => onFlashcardReviewCompleted!(target)\n"
    "          : null,\n"
    "      onLabCompleted:\n",
    1,
)
p.write_text(s)

# Direct planned Flashcard entry carries execution scope into the deck runtime.
p = Path('lib/screens/flashcards/flashcard_competency_review_screen.dart')
s = p.read_text()
if 'flashcard_retention_evidence_service.dart' not in s:
    s = s.replace(
        "import '../../features/flashcards/cloud/published_flashcard_package.dart';\n",
        "import '../../features/flashcards/cloud/published_flashcard_package.dart';\n"
        "import '../../features/exam_readiness/services/flashcard_retention_evidence_service.dart';\n",
        1,
    )
s = s.replace(
    "    required this.isDarkMode,\n    this.repository,\n",
    "    required this.isDarkMode,\n"
    "    this.repository,\n"
    "    this.plannedBlockId,\n"
    "    this.targetCardCount,\n"
    "    this.dueOnly = true,\n"
    "    this.weakOnly = false,\n"
    "    this.onReviewSessionCompleted,\n"
    "    this.recallRuntime,\n"
    "    this.now,\n",
    1,
)
s = s.replace(
    "  final FlashcardPackageRepository? repository;\n",
    "  final FlashcardPackageRepository? repository;\n"
    "  final String? plannedBlockId;\n"
    "  final int? targetCardCount;\n"
    "  final bool dueOnly;\n"
    "  final bool weakOnly;\n"
    "  final Future<void> Function()? onReviewSessionCompleted;\n"
    "  final FlashcardRecallRuntime? recallRuntime;\n"
    "  final DateTime Function()? now;\n",
    1,
)
s = s.replace(
    "        return FlashcardDeckScreen(\n          deck: snapshot.requireData,\n          isDarkMode: widget.isDarkMode,\n        );\n",
    "        return FlashcardDeckScreen(\n"
    "          deck: snapshot.requireData,\n"
    "          isDarkMode: widget.isDarkMode,\n"
    "          plannedBlockId: widget.plannedBlockId,\n"
    "          targetCardCount: widget.targetCardCount,\n"
    "          dueOnly: widget.dueOnly,\n"
    "          weakOnly: widget.weakOnly,\n"
    "          onReviewSessionCompleted: widget.onReviewSessionCompleted,\n"
    "          recallRuntime: widget.recallRuntime,\n"
    "          now: widget.now,\n"
    "        );\n",
    1,
)
p.write_text(s)

# Replace browse-only deck navigation with an evidence-bearing recall runtime.
p = Path('lib/screens/flashcards/flashcards_catalog_view.dart')
s = p.read_text()
if 'flashcard_retention_evidence_service.dart' not in s:
    s = s.replace(
        "import '../../features/flashcards/cloud/published_flashcard_package.dart';\n",
        "import '../../features/flashcards/cloud/published_flashcard_package.dart';\n"
        "import '../../features/flashcards/learning/flashcard_recall_event.dart';\n"
        "import '../../features/flashcards/learning/flashcard_review_queue_service.dart';\n"
        "import '../../features/exam_readiness/services/flashcard_retention_evidence_service.dart';\n",
        1,
    )
start = s.find('class FlashcardDeckScreen extends StatefulWidget {')
end = s.find('class _BackSection extends StatelessWidget {', start)
if start < 0 or end < 0:
    raise SystemExit('ERDP-9 Flashcard deck replacement anchors missing')
replacement = r'''class FlashcardDeckScreen extends StatefulWidget {
  const FlashcardDeckScreen({
    super.key,
    required this.deck,
    required this.isDarkMode,
    this.plannedBlockId,
    this.targetCardCount,
    this.dueOnly = false,
    this.weakOnly = false,
    this.onReviewSessionCompleted,
    this.recallRuntime,
    this.now,
  });

  final FlashcardDeckPackage deck;
  final bool isDarkMode;
  final String? plannedBlockId;
  final int? targetCardCount;
  final bool dueOnly;
  final bool weakOnly;
  final Future<void> Function()? onReviewSessionCompleted;
  final FlashcardRecallRuntime? recallRuntime;
  final DateTime Function()? now;

  @override
  State<FlashcardDeckScreen> createState() => _FlashcardDeckScreenState();
}

class _FlashcardDeckScreenState extends State<FlashcardDeckScreen> {
  late final FlashcardRecallRuntime _recallRuntime;
  late final String _sessionId;
  List<FlashcardCard> _queue = const <FlashcardCard>[];
  int _index = 0;
  int _initialTargetCount = 0;
  bool _showBack = false;
  bool _preparing = true;
  bool _rating = false;
  bool _finished = false;
  bool _completionNotified = false;
  final Set<String> _ratedInitialCards = <String>{};

  DateTime get _now => widget.now?.call() ?? DateTime.now();
  FlashcardCard get _card => _queue[_index];

  @override
  void initState() {
    super.initState();
    _recallRuntime =
        widget.recallRuntime ?? const FlashcardRetentionEvidenceService();
    _sessionId =
        'fc_${widget.deck.competencyId}_${DateTime.now().microsecondsSinceEpoch}';
    _prepareQueue();
  }

  Future<void> _prepareQueue() async {
    final target = widget.targetCardCount ?? widget.deck.cards.length;
    try {
      final history = await _recallRuntime.loadHistory(widget.deck.competencyId);
      final queue = const FlashcardReviewQueueService().build(
        cards: widget.deck.cards,
        history: history,
        now: _now,
        targetCardCount: target,
        dueOnly: widget.dueOnly,
        weakOnly: widget.weakOnly,
      );
      if (!mounted) return;
      setState(() {
        _queue = queue;
        _initialTargetCount = queue.length;
        _preparing = false;
      });
    } catch (_) {
      final cards = widget.deck.cards;
      final fallbackCount = cards.isEmpty
          ? 0
          : target.clamp(1, cards.length).toInt();
      if (!mounted) return;
      setState(() {
        _queue = List<FlashcardCard>.unmodifiable(cards.take(fallbackCount));
        _initialTargetCount = fallbackCount;
        _preparing = false;
      });
    }
  }

  Future<void> _rate(FlashcardRecallRating rating) async {
    if (_rating || !_showBack || _finished || _queue.isEmpty) return;
    final card = _card;
    setState(() => _rating = true);

    try {
      final result = await _recallRuntime.record(
        sessionId: _sessionId,
        competencyId: widget.deck.competencyId,
        card: card,
        rating: rating,
        occurredAt: _now,
        source: widget.plannedBlockId == null
            ? FlashcardReviewSource.catalog
            : FlashcardReviewSource.dailyPlan,
        blockId: widget.plannedBlockId,
      );

      if (result.recallEvent.isFirstAttemptInSession) {
        _ratedInitialCards.add(card.id);
      }
      if (rating == FlashcardRecallRating.again &&
          result.recallEvent.attemptSequence < 3) {
        _queue = <FlashcardCard>[..._queue, card];
      }

      if (!_completionNotified &&
          _initialTargetCount > 0 &&
          _ratedInitialCards.length >= _initialTargetCount) {
        _completionNotified = true;
        await widget.onReviewSessionCompleted?.call();
      }

      if (!mounted) return;
      setState(() {
        _rating = false;
        _showBack = false;
        if (_index + 1 < _queue.length) {
          _index++;
        } else {
          _finished = true;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _rating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save this recall rating. $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    final background = dark ? const Color(0xFF0A111D) : const Color(0xFFF4F7FB);
    final text = dark ? const Color(0xFFF4F7FB) : const Color(0xFF172033);
    final muted = dark ? const Color(0xFFA5B1C4) : const Color(0xFF667083);

    return StudentGlassScaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.deck.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: _preparing
            ? const Center(child: CircularProgressIndicator())
            : _queue.isEmpty
            ? _buildNoCards(context, text, muted)
            : _finished
            ? _buildComplete(context, text, muted)
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      Text(
                        'Card ${_index + 1} of ${_queue.length}',
                        style: TextStyle(
                          color: muted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        widget.deck.competencyId.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    key: const ValueKey('flashcard-study-card'),
                    onTap: _rating
                        ? null
                        : () => setState(() => _showBack = !_showBack),
                    child: StudentGlassSurface(
                      constraints: const BoxConstraints(minHeight: 350),
                      padding: const EdgeInsets.all(25),
                      borderRadius: BorderRadius.circular(24),
                      child: AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        child: _showBack
                            ? Column(
                                key: ValueKey('flashcard-back-${_card.id}'),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _card.frontLabel,
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    _card.backDefinition,
                                    style: TextStyle(
                                      color: text,
                                      fontSize: 19,
                                      height: 1.45,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  _BackSection(
                                    title: 'Why it matters',
                                    body: _card.whyItMatters,
                                    text: text,
                                    muted: muted,
                                  ),
                                  const SizedBox(height: 18),
                                  _BackSection(
                                    title: 'Key point',
                                    body: _card.keyPoint,
                                    text: text,
                                    muted: muted,
                                  ),
                                ],
                              )
                            : Center(
                                key: ValueKey('flashcard-front-${_card.id}'),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.style_rounded,
                                      color: AppColors.primary,
                                      size: 38,
                                    ),
                                    const SizedBox(height: 22),
                                    Text(
                                      _card.frontLabel,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: text,
                                        fontSize: 28,
                                        height: 1.2,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      'Recall the answer, then tap to reveal',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: muted,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_showBack) ...[
                    Text(
                      'How well did you recall it?',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton(
                          key: const ValueKey('flashcard-rating-again'),
                          onPressed: _rating
                              ? null
                              : () => _rate(FlashcardRecallRating.again),
                          child: const Text('Again'),
                        ),
                        OutlinedButton(
                          key: const ValueKey('flashcard-rating-hard'),
                          onPressed: _rating
                              ? null
                              : () => _rate(FlashcardRecallRating.hard),
                          child: const Text('Hard'),
                        ),
                        FilledButton(
                          key: const ValueKey('flashcard-rating-got-it'),
                          onPressed: _rating
                              ? null
                              : () => _rate(FlashcardRecallRating.gotIt),
                          child: const Text('Got It'),
                        ),
                      ],
                    ),
                  ] else
                    Text(
                      'A card is not evidence until you reveal it and rate your recall.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted, fontSize: 12.5),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildNoCards(BuildContext context, Color text, Color muted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_available_rounded, size: 42),
            const SizedBox(height: 12),
            Text(
              'No Flashcards are due in this review scope.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: text,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Returning without rating cards creates no readiness evidence.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, height: 1.4),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('BACK TO PLAN'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplete(BuildContext context, Color text, Color muted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: StudentGlassSurface(
          padding: const EdgeInsets.all(24),
          borderRadius: BorderRadius.circular(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, size: 42),
              const SizedBox(height: 12),
              Text(
                'Flashcard review complete',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: text,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_ratedInitialCards.length} distinct cards rated. '
                'Same-session repeats remain practice only and do not add extra retention credit.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, height: 1.45),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const ValueKey('flashcard-review-done'),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('DONE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

'''
s = s[:start] + replacement + s[end:]
p.write_text(s)

# Daily Plan receives Flashcard completion only after persisted card ratings, and
# independently verifies the events before completing the block.
p = Path('lib/features/exam_readiness/screens/todays_plan_screen.dart')
s = p.read_text()
if 'flashcard_recall_event_repository.dart' not in s:
    s = s.replace(
        "import 'package:exam_platform/theme/glass/student_glass.dart';\n",
        "import 'package:exam_platform/theme/glass/student_glass.dart';\n\n"
        "import '../../flashcards/learning/flashcard_recall_event.dart';\n"
        "import '../../flashcards/learning/flashcard_recall_event_repository.dart';\n",
        1,
    )
# Resume launch callback.
s = s.replace(
    "          onLabCompleted: target.kind == StudyPlanExecutionTargetKind.lab\n",
    "          onFlashcardReviewCompleted:\n"
    "              target.kind == StudyPlanExecutionTargetKind.flashcardReview\n"
    "              ? () async {\n"
    "                  await _complete(\n"
    "                    block.blockId,\n"
    "                    source: StudyPlanCompletionEvidenceSource.flashcardReviewSession,\n"
    "                    silentIfBlocked: true,\n"
    "                  );\n"
    "                }\n"
    "              : null,\n"
    "          onLabCompleted: target.kind == StudyPlanExecutionTargetKind.lab\n",
    1,
)
# Router navigator callback.
s = s.replace(
    "          onLabCompleted: (target, applicationAccuracy) async {\n",
    "          onFlashcardReviewCompleted: (target) async {\n"
    "            await _complete(\n"
    "              target.blockId,\n"
    "              source: StudyPlanCompletionEvidenceSource.flashcardReviewSession,\n"
    "              silentIfBlocked: true,\n"
    "            );\n"
    "          },\n"
    "          onLabCompleted: (target, applicationAccuracy) async {\n",
    1,
)
# Load Flashcard events before completion verification.
s = s.replace(
    "      final progress = await _studyProgressService.loadAllProgress();\n      final decision = widget.completionEvidenceService.evaluate(\n",
    "      final progress = await _studyProgressService.loadAllProgress();\n"
    "      final flashcardRecallEvents =\n"
    "          source == StudyPlanCompletionEvidenceSource.flashcardReviewSession\n"
    "          ? await const FlashcardRecallEventRepository().loadAll(\n"
    "              competencyId: block.competencyId,\n"
    "            )\n"
    "          : const <FlashcardRecallEvent>[];\n"
    "      final decision = widget.completionEvidenceService.evaluate(\n",
    1,
)
s = s.replace(
    "        studyProgress: progress.values,\n        completedAt: at,\n",
    "        studyProgress: progress.values,\n"
    "        flashcardRecallEvents: flashcardRecallEvents,\n"
    "        completedAt: at,\n",
    1,
)
p.write_text(s)

# ERDP-9 tests need the activity statistics type.
p = Path('test/features/exam_readiness/erdp/erdp9_retention_intelligence_test.dart')
s = p.read_text()
if 'activity_evidence_stats.dart' not in s:
    s = s.replace(
        "import 'package:exam_platform/features/exam_readiness/models/learner_assessment_attempt.dart';\n",
        "import 'package:exam_platform/features/exam_readiness/models/activity_evidence_stats.dart';\n"
        "import 'package:exam_platform/features/exam_readiness/models/learner_assessment_attempt.dart';\n",
        1,
    )
p.write_text(s)
