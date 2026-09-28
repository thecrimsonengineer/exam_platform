from pathlib import Path


def patch(path: str, old: str, new: str, count: int = 1) -> None:
    file = Path(path)
    source = file.read_text()
    if old not in source:
        raise SystemExit(f"ERDP-7 patch anchor missing in {path}: {old[:120]!r}")
    file.write_text(source.replace(old, new, count))


def write(path: str, content: str) -> None:
    Path(path).write_text(content)


# Shared execution target: LAB is a first-class target of the ERDP-4 router.
patch(
    "lib/features/exam_readiness/models/study_plan_execution_target.dart",
    "  flashcardReview,\n  examSimulation,\n",
    "  flashcardReview,\n  lab,\n  examSimulation,\n",
)

# Repair remains the persisted block type for backward compatibility, but it is
# a Practice task when it represents a real performance gap.
path = "lib/features/exam_readiness/services/today_plan_task_category_policy.dart"
patch(
    path,
    "  static const Set<String> _reviewRecoveryReasonCodes = <String>{\n    'RETENTION_DUE',\n  };\n",
    "  static const Set<String> _reviewRecoveryReasonCodes = <String>{\n    'RETENTION_DUE',\n  };\n\n  static const Set<String> _practiceRepairReasonCodes = <String>{\n    'APPLICATION_GAP',\n    'KNOWLEDGE_MASTERY_GAP',\n    'DIFFICULTY_PERFORMANCE_GAP',\n  };\n",
)
patch(
    path,
    "      case StudyPlanBlockType.learn:\n      case StudyPlanBlockType.continueLearning:\n      case StudyPlanBlockType.repair:\n        return TodayPlanTaskCategory.learn;\n",
    "      case StudyPlanBlockType.learn:\n      case StudyPlanBlockType.continueLearning:\n        return TodayPlanTaskCategory.learn;\n\n      case StudyPlanBlockType.repair:\n        return _isPracticeRepair(block)\n            ? TodayPlanTaskCategory.practice\n            : TodayPlanTaskCategory.learn;\n",
)
patch(
    path,
    "  TodayPlanTaskCategory _categoryForRecovery(StudyPlanBlock block) {\n",
    "  bool _isPracticeRepair(StudyPlanBlock block) {\n    final reasons = block.reasonCodes\n        .map((reason) => reason.trim().toUpperCase())\n        .toSet();\n    return reasons.any(_practiceRepairReasonCodes.contains);\n  }\n\n  TodayPlanTaskCategory _categoryForRecovery(StudyPlanBlock block) {\n",
)

# The planner's own type/category helper must agree with the presentation policy.
path = "lib/features/exam_readiness/services/daily_study_plan_service.dart"
patch(
    path,
    "      case StudyPlanBlockType.learn:\n      case StudyPlanBlockType.continueLearning:\n      case StudyPlanBlockType.repair:\n        return TodayPlanTaskCategory.learn;\n",
    "      case StudyPlanBlockType.learn:\n      case StudyPlanBlockType.continueLearning:\n        return TodayPlanTaskCategory.learn;\n      case StudyPlanBlockType.repair:\n        return TodayPlanTaskCategory.practice;\n",
)
patch(
    path,
    "      case StudyPlanBlockType.diagnostic:\n      case StudyPlanBlockType.standardPractice:\n",
    "      case StudyPlanBlockType.repair:\n      case StudyPlanBlockType.diagnostic:\n      case StudyPlanBlockType.standardPractice:\n",
    1,
)

# Phase-aware adaptation also preserves a usable question count for non-LAB
# repair tasks, and gives near-exam assessment-balance work the Simulation lane.
path = "lib/features/exam_readiness/services/phase_aware_daily_plan_service.dart"
patch(
    path,
    "    final phaseCode = 'EXAM_PHASE_${phase.name.toUpperCase()}';\n",
    "    if (!isPortfolioFloor &&\n        phase == ExamPreparationPhase.consolidation &&\n        block.reasonCodes.contains('ASSESSMENT_BALANCE') &&\n        (type == StudyPlanBlockType.standardPractice ||\n            type == StudyPlanBlockType.mixedRetrieval ||\n            type == StudyPlanBlockType.ultraHardPractice)) {\n      type = StudyPlanBlockType.examSimulation;\n    }\n\n    final phaseCode = 'EXAM_PHASE_${phase.name.toUpperCase()}';\n",
)
patch(
    path,
    "      case StudyPlanBlockType.diagnostic:\n      case StudyPlanBlockType.standardPractice:\n",
    "      case StudyPlanBlockType.repair:\n      case StudyPlanBlockType.diagnostic:\n      case StudyPlanBlockType.standardPractice:\n",
)

# LAB execution is resolved by the same launcher/router as every other plan task.
path = "lib/features/exam_readiness/navigation/study_plan_block_launcher.dart"
patch(
    path,
    "import '../../../screens/flashcards/flashcard_competency_review_screen.dart';\n",
    "import '../../../screens/flashcards/flashcard_competency_review_screen.dart';\nimport '../../../screens/lab/lab_library_screen.dart';\n",
)
patch(
    path,
    "    final category = categoryPolicy.categoryFor(block);\n    final kind = switch (category) {\n",
    "    final category = categoryPolicy.categoryFor(block);\n    final isApplicationLab =\n        block.type == StudyPlanBlockType.repair &&\n        block.reasonCodes.any(\n          (reason) => reason.trim().toUpperCase() == 'APPLICATION_GAP',\n        );\n    final kind = isApplicationLab\n        ? StudyPlanExecutionTargetKind.lab\n        : switch (category) {\n",
)
patch(
    path,
    "    Future<void> Function()? onPracticeSessionCompleted,\n  }) {\n",
    "    Future<void> Function()? onPracticeSessionCompleted,\n    Future<void> Function(double applicationAccuracy)? onLabCompleted,\n  }) {\n",
    1,
)
patch(
    path,
    "      onPracticeSessionCompleted: onPracticeSessionCompleted,\n    );\n  }\n\n  Future<void> launchTarget(\n",
    "      onPracticeSessionCompleted: onPracticeSessionCompleted,\n      onLabCompleted: onLabCompleted,\n    );\n  }\n\n  Future<void> launchTarget(\n",
)
patch(
    path,
    "    Future<void> Function()? onPracticeSessionCompleted,\n  }) async {\n",
    "    Future<void> Function()? onPracticeSessionCompleted,\n    Future<void> Function(double applicationAccuracy)? onLabCompleted,\n  }) async {\n",
    1,
)
patch(
    path,
    "      StudyPlanExecutionTargetKind.flashcardReview =>\n        FlashcardCompetencyReviewScreen(\n          competencyId: target.competencyId,\n          isDarkMode: isDarkMode,\n        ),\n",
    "      StudyPlanExecutionTargetKind.flashcardReview =>\n        FlashcardCompetencyReviewScreen(\n          competencyId: target.competencyId,\n          isDarkMode: isDarkMode,\n        ),\n      StudyPlanExecutionTargetKind.lab => LabLibraryScreen.persistent(\n        onScenarioCompleted: onLabCompleted,\n      ),\n",
)

# Navigator carries terminal LAB evidence back to the authoritative Daily Plan.
path = "lib/features/exam_readiness/navigation/flutter_study_plan_execution_navigator.dart"
patch(
    path,
    "typedef PracticeCompletionCallback =\n    Future<void> Function(StudyPlanExecutionTarget target);\n",
    "typedef PracticeCompletionCallback =\n    Future<void> Function(StudyPlanExecutionTarget target);\ntypedef LabCompletionCallback =\n    Future<void> Function(\n      StudyPlanExecutionTarget target,\n      double applicationAccuracy,\n    );\n",
)
patch(
    path,
    "    this.onPracticeSessionCompleted,\n  });\n",
    "    this.onPracticeSessionCompleted,\n    this.onLabCompleted,\n  });\n",
)
patch(
    path,
    "  final PracticeCompletionCallback? onPracticeSessionCompleted;\n",
    "  final PracticeCompletionCallback? onPracticeSessionCompleted;\n  final LabCompletionCallback? onLabCompleted;\n",
)
patch(
    path,
    "      onPracticeSessionCompleted:\n          isPractice && onPracticeSessionCompleted != null\n          ? () => onPracticeSessionCompleted!(target)\n          : null,\n",
    "      onPracticeSessionCompleted:\n          isPractice && onPracticeSessionCompleted != null\n          ? () => onPracticeSessionCompleted!(target)\n          : null,\n      onLabCompleted:\n          target.kind == StudyPlanExecutionTargetKind.lab &&\n              onLabCompleted != null\n          ? (applicationAccuracy) =>\n                onLabCompleted!(target, applicationAccuracy)\n          : null,\n",
)

# A terminal LAB callback is itself the completion proof. Opening/closing LAB is not.
path = "lib/features/exam_readiness/services/study_plan_completion_evidence_service.dart"
patch(
    path,
    "  plannedPracticeSession,\n  studyContent,\n  explicitLearnerFinish,\n",
    "  plannedPracticeSession,\n  labScenarioCompleted,\n  studyContent,\n  explicitLearnerFinish,\n",
)
patch(
    path,
    "      case StudyPlanCompletionEvidenceSource.plannedPracticeSession:\n",
    "      case StudyPlanCompletionEvidenceSource.labScenarioCompleted:\n        final applicationGap = block.reasonCodes.any(\n          (reason) => reason.trim().toUpperCase() == 'APPLICATION_GAP',\n        );\n        if (block.type != StudyPlanBlockType.repair || !applicationGap) {\n          return const StudyPlanCompletionDecision.blocked(\n            'LAB completion can complete only an application-gap repair task.',\n          );\n        }\n        return const StudyPlanCompletionDecision.allowed(\n          message: 'A terminal LAB scenario provides completion evidence.',\n        );\n\n      case StudyPlanCompletionEvidenceSource.plannedPracticeSession:\n",
)

# Outcome capture accepts a verified applied-performance score from the terminal LAB.
path = "lib/features/exam_readiness/services/study_plan_outcome_service.dart"
patch(
    path,
    "    String? assessmentSessionKind,\n    int? learnerRating,\n",
    "    String? assessmentSessionKind,\n    double? applicationAccuracyOverride,\n    int? learnerRating,\n",
)
patch(
    path,
    "      applicationAccuracy: _accuracy(application),\n",
    "      applicationAccuracy:\n          applicationAccuracyOverride ?? _accuracy(application),\n",
)

# ERDP-6 normalization recognizes completed application LAB work as strong applied evidence.
path = "lib/features/exam_readiness/services/learning_evidence_normalizer.dart"
patch(
    path,
    "    final applicationScore = sourceKind == LearningEvidenceSourceKind.simulation\n        ? outcome.applicationAccuracy ??\n              outcome.analysisAccuracy ??\n              overallAccuracy\n        : null;\n",
    "    final applicationScore =\n        sourceKind == LearningEvidenceSourceKind.simulation ||\n            sourceKind == LearningEvidenceSourceKind.lab\n        ? outcome.applicationAccuracy ??\n              outcome.analysisAccuracy ??\n              overallAccuracy\n        : null;\n",
)
patch(
    path,
    "    if (block.type == StudyPlanBlockType.spacedReview) {\n      return LearningEvidenceSourceKind.flashcard;\n    }\n",
    "    if (block.type == StudyPlanBlockType.spacedReview) {\n      return LearningEvidenceSourceKind.flashcard;\n    }\n    if (block.type == StudyPlanBlockType.repair &&\n        outcome.applicationAccuracy != null &&\n        block.reasonCodes.any(\n          (reason) => reason.trim().toUpperCase() == 'APPLICATION_GAP',\n        )) {\n      return LearningEvidenceSourceKind.lab;\n    }\n",
)

# LAB screens propagate a terminal completion callback without changing ordinary LAB entry.
path = "lib/screens/lab/lab_library_screen.dart"
patch(
    path,
    "  const LabLibraryScreen({super.key})\n    : persistent = false,\n      runtimeBinding = null;\n\n  const LabLibraryScreen.persistent({super.key})\n    : persistent = true,\n      runtimeBinding = null;\n\n  const LabLibraryScreen.withBinding({super.key, required this.runtimeBinding})\n    : persistent = true;\n\n  final bool persistent;\n  final LabLearnerRuntimeBinding? runtimeBinding;\n",
    "  const LabLibraryScreen({super.key, this.onScenarioCompleted})\n    : persistent = false,\n      runtimeBinding = null;\n\n  const LabLibraryScreen.persistent({super.key, this.onScenarioCompleted})\n    : persistent = true,\n      runtimeBinding = null;\n\n  const LabLibraryScreen.withBinding({\n    super.key,\n    required this.runtimeBinding,\n    this.onScenarioCompleted,\n  }) : persistent = true;\n\n  final bool persistent;\n  final LabLearnerRuntimeBinding? runtimeBinding;\n  final Future<void> Function(double applicationAccuracy)? onScenarioCompleted;\n",
)
patch(
    path,
    "          builder: (_) => LabScenarioBriefingScreen(scenario: scenario),\n",
    "          builder: (_) => LabScenarioBriefingScreen(\n            scenario: scenario,\n            onScenarioCompleted: widget.onScenarioCompleted,\n          ),\n",
)
patch(
    path,
    "            publishedPackage: delivery.package,\n          ),\n",
    "            publishedPackage: delivery.package,\n            onScenarioCompleted: widget.onScenarioCompleted,\n          ),\n",
)

path = "lib/screens/lab/lab_scenario_briefing_screen.dart"
patch(
    path,
    "    this.publishedPackage,\n  });\n\n  final LabScenarioDefinition scenario;\n  final LabPackage? publishedPackage;\n",
    "    this.publishedPackage,\n    this.onScenarioCompleted,\n  });\n\n  final LabScenarioDefinition scenario;\n  final LabPackage? publishedPackage;\n  final Future<void> Function(double applicationAccuracy)? onScenarioCompleted;\n",
)
patch(
    path,
    "                      publishedPackage: publishedPackage,\n                    ),\n",
    "                      publishedPackage: publishedPackage,\n                      onScenarioCompleted: onScenarioCompleted,\n                    ),\n",
)

path = "lib/screens/lab/lab_player_shell_screen.dart"
patch(
    path,
    "  const LabPlayerShellScreen({super.key, this.scenario, this.publishedPackage});\n\n  final LabScenarioDefinition? scenario;\n  final LabPackage? publishedPackage;\n",
    "  const LabPlayerShellScreen({\n    super.key,\n    this.scenario,\n    this.publishedPackage,\n    this.onScenarioCompleted,\n  });\n\n  final LabScenarioDefinition? scenario;\n  final LabPackage? publishedPackage;\n  final Future<void> Function(double applicationAccuracy)? onScenarioCompleted;\n",
)
patch(
    path,
    "          publishedPackage: publishedPackage,\n        ),\n",
    "          publishedPackage: publishedPackage,\n          onScenarioCompleted: onScenarioCompleted,\n        ),\n",
)

path = "lib/screens/lab/lab_reference_player_screen.dart"
patch(
    path,
    "    this.learningEvidenceSink,\n  });\n",
    "    this.learningEvidenceSink,\n    this.onScenarioCompleted,\n  });\n",
)
patch(
    path,
    "  final LabLearningEvidenceSink? learningEvidenceSink;\n",
    "  final LabLearningEvidenceSink? learningEvidenceSink;\n  final Future<void> Function(double applicationAccuracy)? onScenarioCompleted;\n",
)
patch(
    path,
    "  bool _statusExpanded = false;\n  DateTime _decisionStartedAt = DateTime.now();\n",
    "  bool _statusExpanded = false;\n  bool _completionReported = false;\n  DateTime _decisionStartedAt = DateTime.now();\n",
)
patch(
    path,
    "        _statusExpanded = false;\n        _error = null;\n",
    "        _statusExpanded = false;\n        _completionReported = false;\n        _error = null;\n",
    1,
)
patch(
    path,
    "      unawaited(\n        _learningEvidenceEmitter.emitNewlyPersisted(\n          package: package,\n          before: session,\n          after: updated,\n          sink: _learningEvidenceSink,\n        ),\n      );\n      if (!mounted) return;\n",
    "      unawaited(\n        _learningEvidenceEmitter.emitNewlyPersisted(\n          package: package,\n          before: session,\n          after: updated,\n          sink: _learningEvidenceSink,\n        ),\n      );\n      if (updated.status == LabSessionStatus.completed &&\n          !_completionReported &&\n          widget.onScenarioCompleted != null) {\n        _completionReported = true;\n        try {\n          await widget.onScenarioCompleted!(\n            _applicationAccuracy(package, updated),\n          );\n        } catch (_) {\n          _completionReported = false;\n          rethrow;\n        }\n      }\n      if (!mounted) return;\n",
)
patch(
    path,
    "  Future<void> _replay() async {\n",
    "  double _applicationAccuracy(LabPackage package, LabSession session) {\n    if (session.decisionHistory.isEmpty) return 0;\n    var total = 0.0;\n    var samples = 0;\n\n    for (final event in session.decisionHistory) {\n      for (final node in package.nodes) {\n        if (node.id != event.nodeId || node is! LabDecisionNode) continue;\n        final option = node.requireOption(event.selectedOptionId);\n        total += switch (option.quality) {\n          LabDecisionQuality.optimal => 1.0,\n          LabDecisionQuality.defensible => 0.75,\n          LabDecisionQuality.weak => 0.35,\n          LabDecisionQuality.critical => 0.0,\n        };\n        samples++;\n        break;\n      }\n    }\n\n    return samples == 0 ? 0 : (total / samples).clamp(0.0, 1.0);\n  }\n\n  Future<void> _replay() async {\n",
)
patch(
    path,
    "        _statusExpanded = false;\n        _decisionStartedAt = DateTime.now();\n",
    "        _statusExpanded = false;\n        _completionReported = false;\n        _decisionStartedAt = DateTime.now();\n",
    1,
)

# Today Plan completes the same started block only when LAB reports a terminal scenario.
path = "lib/features/exam_readiness/screens/todays_plan_screen.dart"
patch(
    path,
    "          onPracticeSessionCompleted:\n              target.kind == StudyPlanExecutionTargetKind.practiceSession ||\n                  target.kind == StudyPlanExecutionTargetKind.examSimulation\n              ? () async {\n                  await _complete(\n                    block.blockId,\n                    source: StudyPlanCompletionEvidenceSource\n                        .plannedPracticeSession,\n                    silentIfBlocked: true,\n                  );\n                }\n              : null,\n",
    "          onPracticeSessionCompleted:\n              target.kind == StudyPlanExecutionTargetKind.practiceSession ||\n                  target.kind == StudyPlanExecutionTargetKind.examSimulation\n              ? () async {\n                  await _complete(\n                    block.blockId,\n                    source: StudyPlanCompletionEvidenceSource\n                        .plannedPracticeSession,\n                    silentIfBlocked: true,\n                  );\n                }\n              : null,\n          onLabCompleted: target.kind == StudyPlanExecutionTargetKind.lab\n              ? (applicationAccuracy) async {\n                  await _complete(\n                    block.blockId,\n                    source: StudyPlanCompletionEvidenceSource\n                        .labScenarioCompleted,\n                    applicationAccuracyOverride: applicationAccuracy,\n                    silentIfBlocked: true,\n                  );\n                }\n              : null,\n",
)
patch(
    path,
    "          onPracticeSessionCompleted: (target) async {\n            await _complete(\n              target.blockId,\n              source: StudyPlanCompletionEvidenceSource.plannedPracticeSession,\n              silentIfBlocked: true,\n            );\n          },\n",
    "          onPracticeSessionCompleted: (target) async {\n            await _complete(\n              target.blockId,\n              source: StudyPlanCompletionEvidenceSource.plannedPracticeSession,\n              silentIfBlocked: true,\n            );\n          },\n          onLabCompleted: (target, applicationAccuracy) async {\n            await _complete(\n              target.blockId,\n              source: StudyPlanCompletionEvidenceSource.labScenarioCompleted,\n              applicationAccuracyOverride: applicationAccuracy,\n              silentIfBlocked: true,\n            );\n          },\n",
)
patch(
    path,
    "    required StudyPlanCompletionEvidenceSource source,\n    bool silentIfBlocked = false,\n  }) async {\n",
    "    required StudyPlanCompletionEvidenceSource source,\n    double? applicationAccuracyOverride,\n    bool silentIfBlocked = false,\n  }) async {\n",
)
patch(
    path,
    "          assessmentSessionKind:\n              source == StudyPlanCompletionEvidenceSource.plannedPracticeSession\n              ? StudyPlanCompletionEvidenceService.sessionKindForBlock(blockId)\n              : null,\n",
    "          assessmentSessionKind:\n              source == StudyPlanCompletionEvidenceSource.plannedPracticeSession\n              ? StudyPlanCompletionEvidenceService.sessionKindForBlock(blockId)\n              : null,\n          applicationAccuracyOverride: applicationAccuracyOverride,\n",
    1,
)
# The second outcome build in the normal started -> completed path.
start = Path(path).read_text()
anchor = "      assessmentSessionKind:\n            source == StudyPlanCompletionEvidenceSource.plannedPracticeSession\n            ? StudyPlanCompletionEvidenceService.sessionKindForBlock(blockId)\n            : null,\n"
if anchor not in start:
    raise SystemExit("ERDP-7 second outcome anchor missing in todays_plan_screen.dart")
Path(path).write_text(
    start.replace(
        anchor,
        anchor + "      applicationAccuracyOverride: applicationAccuracyOverride,\n",
        1,
    )
)

# Readiness now covers all seven intervention families while still producing only recommendations.
path = "lib/features/exam_readiness/services/readiness_intelligence_service.dart"
patch(
    path,
    "import '../models/readiness_intelligence_snapshot.dart';\n",
    "import '../models/readiness_gap.dart';\nimport '../models/readiness_intelligence_snapshot.dart';\n",
)
patch(
    path,
    "    int dueFlashcards = 0,\n    DateTime? generatedAt,\n",
    "    int dueFlashcards = 0,\n    int? daysUntilExam,\n    DateTime? generatedAt,\n",
)
patch(
    path,
    "      dueFlashcards: dueFlashcards,\n    );\n",
    "      dueFlashcards: dueFlashcards,\n      daysUntilExam: daysUntilExam,\n    );\n",
)
old = '''  ReadinessNextAction? _nextBestAction({
    required List<CompetencyReadinessProfile> profiles,
    required List<String> weakCompetencyIds,
    required List<String> evidenceGapCompetencyIds,
    required int dueFlashcards,
  }) {
    if (evidenceGapCompetencyIds.isNotEmpty) {
      final competencyId = evidenceGapCompetencyIds.first;
      return ReadinessNextAction(
        kind: ReadinessNextActionKind.diagnostic,
        competencyId: competencyId,
        minutes: 15,
        reasonCodes: const <String>['ERDP1_INSUFFICIENT_EVIDENCE_DIAGNOSTIC'],
        reasonText:
            'Build enough evidence to distinguish a true weakness from an evidence gap.',
      );
    }

    if (weakCompetencyIds.isNotEmpty) {
      final competencyId = weakCompetencyIds.first;
      final profile = profiles.firstWhere(
        (item) => item.competencyId == competencyId,
      );

      if (_isRetentionPrimary(profile) && dueFlashcards > 0) {
        return ReadinessNextAction(
          kind: ReadinessNextActionKind.flashcardReview,
          competencyId: competencyId,
          minutes: 10,
          reasonCodes: const <String>['ERDP1_RETENTION_GAP_FLASHCARD_REVIEW'],
          reasonText:
              'Retention is the limiting factor, so use a short spaced-recall intervention.',
        );
      }

      if (_isApplicationPrimary(profile)) {
        return ReadinessNextAction(
          kind: ReadinessNextActionKind.lab,
          competencyId: competencyId,
          minutes: 15,
          reasonCodes: const <String>['ERDP1_APPLICATION_GAP_APPLIED_PRACTICE'],
          reasonText:
              'Application evidence is weaker than knowledge evidence, so use an applied task.',
        );
      }

      return ReadinessNextAction(
        kind: ReadinessNextActionKind.targetedPractice,
        competencyId: competencyId,
        minutes: 15,
        reasonCodes: const <String>['ERDP1_WEAK_COMPETENCY_TARGETED_PRACTICE'],
        reasonText:
            'Current evidence supports a genuine weakness that needs targeted practice.',
      );
    }

    if (dueFlashcards > 0) {
      return ReadinessNextAction(
        kind: ReadinessNextActionKind.flashcardReview,
        competencyId: '',
        minutes: 10,
        reasonCodes: const <String>['ERDP1_RETENTION_MAINTENANCE_DUE'],
        reasonText:
            'No major weakness is leading, but spaced recall is due for retention maintenance.',
      );
    }

    return null;
  }

  bool _isRetentionPrimary(CompetencyReadinessProfile profile) {
    final retention = profile.retention.value;
    final knowledge = profile.knowledgeMastery.value;
    if (retention == null || knowledge == null) return false;
    return retention + 0.12 < knowledge;
  }

  bool _isApplicationPrimary(CompetencyReadinessProfile profile) {
    final application = profile.applicationAbility.value;
    final knowledge = profile.knowledgeMastery.value;
    if (application == null || knowledge == null) return false;
    return application + 0.12 < knowledge;
  }
'''
new = '''  ReadinessNextAction? _nextBestAction({
    required List<CompetencyReadinessProfile> profiles,
    required List<String> weakCompetencyIds,
    required List<String> evidenceGapCompetencyIds,
    required int dueFlashcards,
    required int? daysUntilExam,
  }) {
    if (evidenceGapCompetencyIds.isNotEmpty) {
      final competencyId = evidenceGapCompetencyIds.first;
      return ReadinessNextAction(
        kind: ReadinessNextActionKind.diagnostic,
        competencyId: competencyId,
        minutes: 15,
        reasonCodes: const <String>['ERDP1_INSUFFICIENT_EVIDENCE_DIAGNOSTIC'],
        reasonText:
            'Build enough evidence to distinguish a true weakness from an evidence gap.',
      );
    }

    final applicationGap = _firstWithGap(
      profiles,
      ReadinessGapType.applicationGap,
    );
    if (applicationGap != null) {
      return ReadinessNextAction(
        kind: ReadinessNextActionKind.lab,
        competencyId: applicationGap.competencyId,
        minutes: 15,
        reasonCodes: const <String>['ERDP1_APPLICATION_GAP_APPLIED_PRACTICE'],
        reasonText:
            'Application evidence is the limiting factor, so use an applied LAB task.',
      );
    }

    final retentionGap = _firstWithGap(
      profiles,
      ReadinessGapType.retentionGap,
    );
    if (retentionGap != null &&
        (retentionGap.retention.value != null || dueFlashcards > 0)) {
      return ReadinessNextAction(
        kind: ReadinessNextActionKind.flashcardReview,
        competencyId: retentionGap.competencyId,
        minutes: 10,
        reasonCodes: const <String>['ERDP1_RETENTION_GAP_FLASHCARD_REVIEW'],
        reasonText:
            'Retention is the limiting factor, so use a short spaced-recall intervention.',
      );
    }

    final confidenceGap = _firstWithGap(
      profiles,
      ReadinessGapType.confidenceGap,
    );
    if (confidenceGap != null) {
      return ReadinessNextAction(
        kind: ReadinessNextActionKind.confidenceCalibration,
        competencyId: confidenceGap.competencyId,
        minutes: 10,
        reasonCodes: const <String>['ERDP7_CONFIDENCE_CALIBRATION'],
        reasonText:
            'Confidence and demonstrated performance are misaligned, so recalibrate with targeted questions.',
      );
    }

    final coverageGap = _firstWithGap(
      profiles,
      ReadinessGapType.coverageGap,
    );
    if (coverageGap != null) {
      return ReadinessNextAction(
        kind: ReadinessNextActionKind.studyReview,
        competencyId: coverageGap.competencyId,
        minutes: 15,
        reasonCodes: const <String>['ERDP7_COVERAGE_GAP_STUDY'],
        reasonText:
            'Blueprint coverage is incomplete, so fill the missing learning coverage before adding more assessment.',
      );
    }

    if (weakCompetencyIds.isNotEmpty) {
      return ReadinessNextAction(
        kind: ReadinessNextActionKind.targetedPractice,
        competencyId: weakCompetencyIds.first,
        minutes: 15,
        reasonCodes: const <String>['ERDP1_WEAK_COMPETENCY_TARGETED_PRACTICE'],
        reasonText:
            'Current evidence supports a genuine weakness that needs targeted practice.',
      );
    }

    if (daysUntilExam != null && daysUntilExam >= 0 && daysUntilExam <= 14) {
      return ReadinessNextAction(
        kind: ReadinessNextActionKind.simulation,
        competencyId: '',
        minutes: 20,
        reasonCodes: const <String>['ERDP7_EXAM_PROXIMITY_SIMULATION'],
        reasonText:
            'The exam is close and no larger gap is leading, so rehearse integrated performance with a simulation.',
      );
    }

    if (dueFlashcards > 0) {
      return ReadinessNextAction(
        kind: ReadinessNextActionKind.flashcardReview,
        competencyId: '',
        minutes: 10,
        reasonCodes: const <String>['ERDP1_RETENTION_MAINTENANCE_DUE'],
        reasonText:
            'No major weakness is leading, but spaced recall is due for retention maintenance.',
      );
    }

    return null;
  }

  CompetencyReadinessProfile? _firstWithGap(
    Iterable<CompetencyReadinessProfile> profiles,
    ReadinessGapType type,
  ) {
    for (final profile in profiles) {
      if (profile.gaps.any(
        (gap) => !gap.evidenceLimited && gap.type == type,
      )) {
        return profile;
      }
    }
    return null;
  }
'''
patch(path, old, new)

# Authoritative readiness-to-plan binding. This service never creates a task,
# never navigates, and never computes a second plan.
write(
    "lib/features/exam_readiness/services/readiness_action_integration_service.dart",
    '''import '../models/daily_study_plan.dart';
import '../models/readiness_intelligence_snapshot.dart';
import '../models/study_plan_block.dart';

class ReadinessActionBinding {
  const ReadinessActionBinding({
    required this.action,
    required this.block,
    required this.requiresReplan,
    required this.reasonCode,
  });

  final ReadinessNextAction? action;
  final StudyPlanBlock? block;
  final bool requiresReplan;
  final String reasonCode;

  bool get isActionable => action != null && block != null && !requiresReplan;
}

class ReadinessActionIntegrationService {
  const ReadinessActionIntegrationService();

  ReadinessActionBinding bind({
    required ReadinessIntelligenceSnapshot readiness,
    required DailyStudyPlan plan,
  }) {
    final action = readiness.nextBestAction;
    if (action == null) {
      return const ReadinessActionBinding(
        action: null,
        block: null,
        requiresReplan: false,
        reasonCode: 'ERDP7_NO_ACTION_REQUIRED',
      );
    }

    final candidates = plan.blocks.where((block) {
      if (!_isExecutable(block.status)) return false;
      final targetCompetency = action.competencyId.trim().toLowerCase();
      if (targetCompetency.isNotEmpty &&
          block.competencyId.trim().toLowerCase() != targetCompetency) {
        return false;
      }
      return _matches(action.kind, block);
    }).toList(growable: false);

    if (candidates.isEmpty) {
      return ReadinessActionBinding(
        action: action,
        block: null,
        requiresReplan: true,
        reasonCode: 'ERDP7_AUTHORITATIVE_PLAN_REPLAN_REQUIRED',
      );
    }

    final started = candidates.where(
      (block) => block.status == StudyPlanBlockStatus.started,
    );
    final block = started.isNotEmpty ? started.first : candidates.first;

    return ReadinessActionBinding(
      action: action,
      block: block,
      requiresReplan: false,
      reasonCode: block.status == StudyPlanBlockStatus.started
          ? 'ERDP7_RESUME_AUTHORITATIVE_PLAN_BLOCK'
          : 'ERDP7_USE_AUTHORITATIVE_PLAN_BLOCK',
    );
  }

  bool _isExecutable(StudyPlanBlockStatus status) =>
      status == StudyPlanBlockStatus.planned ||
      status == StudyPlanBlockStatus.shortened ||
      status == StudyPlanBlockStatus.started;

  bool _matches(ReadinessNextActionKind kind, StudyPlanBlock block) {
    final reasons = block.reasonCodes
        .map((reason) => reason.trim().toUpperCase())
        .toSet();
    final applicationRepair =
        block.type == StudyPlanBlockType.repair &&
        reasons.contains('APPLICATION_GAP');

    return switch (kind) {
      ReadinessNextActionKind.diagnostic =>
        block.type == StudyPlanBlockType.diagnostic,
      ReadinessNextActionKind.targetedPractice =>
        block.type == StudyPlanBlockType.standardPractice ||
            block.type == StudyPlanBlockType.ultraHardPractice ||
            block.type == StudyPlanBlockType.mixedRetrieval ||
            block.type == StudyPlanBlockType.competencyRecheck ||
            (block.type == StudyPlanBlockType.repair && !applicationRepair),
      ReadinessNextActionKind.flashcardReview =>
        block.type == StudyPlanBlockType.spacedReview ||
            block.type == StudyPlanBlockType.recovery,
      ReadinessNextActionKind.studyReview =>
        block.type == StudyPlanBlockType.learn ||
            block.type == StudyPlanBlockType.continueLearning,
      ReadinessNextActionKind.lab => applicationRepair,
      ReadinessNextActionKind.confidenceCalibration =>
        block.type == StudyPlanBlockType.confidenceCalibration,
      ReadinessNextActionKind.simulation =>
        block.type == StudyPlanBlockType.examSimulation,
    };
  }
}
''',
)

# ERDP-7 focused contract tests.
write(
    "test/features/exam_readiness/erdp/erdp7_readiness_action_integration_test.dart",
    '''import 'package:exam_platform/features/exam_readiness/models/advanced_readiness_snapshot.dart';
import 'package:exam_platform/features/exam_readiness/models/capacity_pressure_snapshot.dart';
import 'package:exam_platform/features/exam_readiness/models/competency_readiness_profile.dart';
import 'package:exam_platform/features/exam_readiness/models/coverage_projection.dart';
import 'package:exam_platform/features/exam_readiness/models/daily_study_plan.dart';
import 'package:exam_platform/features/exam_readiness/models/evidence_confidence.dart';
import 'package:exam_platform/features/exam_readiness/models/exam_preparation_phase.dart';
import 'package:exam_platform/features/exam_readiness/models/readiness_index_snapshot.dart';
import 'package:exam_platform/features/exam_readiness/models/readiness_intelligence_snapshot.dart';
import 'package:exam_platform/features/exam_readiness/models/readiness_trajectory_point.dart';
import 'package:exam_platform/features/exam_readiness/models/recovery_protection_snapshot.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_block_outcome.dart';
import 'package:exam_platform/features/exam_readiness/models/study_plan_execution_target.dart';
import 'package:exam_platform/features/exam_readiness/navigation/study_plan_block_launcher.dart';
import 'package:exam_platform/features/exam_readiness/services/learning_evidence_normalizer.dart';
import 'package:exam_platform/features/exam_readiness/services/phase_aware_daily_plan_service.dart';
import 'package:exam_platform/features/exam_readiness/services/readiness_action_integration_service.dart';
import 'package:exam_platform/features/exam_readiness/services/readiness_intelligence_service.dart';
import 'package:exam_platform/features/exam_readiness/services/today_plan_task_category_policy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../m7d/_support/m7d_fixture.dart';

StudyPlanBlock _block({
  required String id,
  required StudyPlanBlockType type,
  String competencyId = 'd01_c01',
  List<String> reasons = const <String>['ERDP7_TEST'],
  StudyPlanBlockStatus status = StudyPlanBlockStatus.planned,
}) {
  final questionCount = switch (type) {
    StudyPlanBlockType.repair ||
    StudyPlanBlockType.diagnostic ||
    StudyPlanBlockType.standardPractice ||
    StudyPlanBlockType.ultraHardPractice ||
    StudyPlanBlockType.mixedRetrieval ||
    StudyPlanBlockType.competencyRecheck ||
    StudyPlanBlockType.confidenceCalibration ||
    StudyPlanBlockType.examSimulation => 5,
    _ => 0,
  };
  return StudyPlanBlock(
    blockId: id,
    type: type,
    domainId: 'd01',
    competencyId: competencyId,
    subtopicId: '',
    topicId: '',
    plannedMinutes: 15,
    questionCount: questionCount,
    priorityScore: 0.9,
    priorityBreakdown: m7dPriority(competencyId: competencyId),
    reasonCodes: reasons,
    reasonText: 'ERDP-7 test task.',
    status: status,
    createdAt: DateTime.utc(2026, 9, 28, 8),
    startedAt: status == StudyPlanBlockStatus.started
        ? DateTime.utc(2026, 9, 28, 9)
        : null,
    manualChanges: const <StudyPlanManualChange>[],
  );
}

DailyStudyPlan _plan(List<StudyPlanBlock> blocks) => DailyStudyPlan(
  planId: 'erdp7-plan',
  userId: 'learner-1',
  date: DateTime.utc(2026, 9, 28),
  generatedAt: DateTime.utc(2026, 9, 28, 8),
  planVersion: 1,
  plannerAlgorithmVersion: DailyStudyPlan.currentAlgorithmVersion,
  availableMinutes: 180,
  allocatedMinutes: blocks.fold(0, (sum, block) => sum + block.plannedMinutes),
  generationReason: DailyStudyPlanGenerationReason.initial,
  sourceEvidenceVersion: 'e1',
  sourceReadinessVersion: 'r1',
  blocks: blocks,
  status: DailyStudyPlanStatus.active,
  schemaVersion: DailyStudyPlan.currentSchemaVersion,
);

ReadinessIntelligenceSnapshot _readiness(ReadinessNextAction action) =>
    ReadinessIntelligenceSnapshot(
      generatedAt: DateTime.utc(2026, 9, 28),
      state: ReadinessIntelligenceState.progressing,
      overallScore: 70,
      evidenceConfidence: EvidenceConfidence.high,
      knowledge: m7dProfile().knowledgeMastery,
      application: m7dProfile().applicationAbility,
      retention: m7dProfile().retention,
      blueprintCoverage: 0.8,
      difficultyCoverage: m7dProfile().difficultyPerformance.dimension,
      recency: m7dProfile().recentPerformance,
      confidenceCalibration: m7dProfile().confidenceCalibration,
      evidenceSufficiency: 0.9,
      strongCompetencyIds: const <String>[],
      weakCompetencyIds: <String>[action.competencyId],
      evidenceGapCompetencyIds: const <String>[],
      dueFlashcards: 0,
      nextBestAction: action,
      reasonCodes: const <String>['ERDP7_TEST'],
      algorithmVersion: ReadinessIntelligenceService.currentAlgorithmVersion,
    );

ReadinessNextAction _action(
  ReadinessNextActionKind kind, {
  String competencyId = 'd01_c01',
}) => ReadinessNextAction(
  kind: kind,
  competencyId: competencyId,
  minutes: 15,
  reasonCodes: const <String>['ERDP7_TEST'],
  reasonText: 'ERDP-7 test action.',
);

void main() {
  group('ERDP-7 application LAB route', () {
    test('application-gap repair is Practice and resolves to LAB', () {
      final block = _block(
        id: 'lab-repair',
        type: StudyPlanBlockType.repair,
        reasons: const <String>['APPLICATION_GAP'],
      );

      expect(
        const TodayPlanTaskCategoryPolicy().categoryFor(block).name,
        'practice',
      );
      expect(
        const StudyPlanBlockLauncher().resolve(block).kind,
        StudyPlanExecutionTargetKind.lab,
      );
    });

    test('terminal LAB outcome normalizes to strong applied evidence', () {
      final block = _block(
        id: 'lab-evidence',
        type: StudyPlanBlockType.repair,
        reasons: const <String>['APPLICATION_GAP'],
        status: StudyPlanBlockStatus.started,
      );
      final outcome = StudyPlanBlockOutcome(
        outcomeId: 'lab-outcome',
        planId: 'erdp7-plan',
        planVersion: 1,
        blockId: block.blockId,
        competencyId: block.competencyId,
        completedAt: DateTime.utc(2026, 9, 28, 9, 20),
        minutesSpent: 20,
        questionsAttempted: 0,
        questionsCorrect: 0,
        applicationAccuracy: 0.75,
        confidenceSamples: 0,
        contentCompleted: true,
        abandoned: false,
      );

      final event = const LearningEvidenceNormalizer().fromStudyPlanOutcome(
        block: block,
        outcome: outcome,
      );

      expect(event.sourceKind.name, 'lab');
      expect(event.strength.name, 'strong');
      expect(event.applicationScore, 0.75);
    });
  });

  group('ERDP-7 one-plan action binding', () {
    test('all readiness action families bind only to compatible DailyPlan blocks', () {
      final blocks = <StudyPlanBlock>[
        _block(id: 'diagnostic', type: StudyPlanBlockType.diagnostic),
        _block(id: 'practice', type: StudyPlanBlockType.standardPractice),
        _block(id: 'flashcards', type: StudyPlanBlockType.spacedReview),
        _block(id: 'study', type: StudyPlanBlockType.learn),
        _block(
          id: 'lab',
          type: StudyPlanBlockType.repair,
          reasons: const <String>['APPLICATION_GAP'],
        ),
        _block(
          id: 'confidence',
          type: StudyPlanBlockType.confidenceCalibration,
        ),
        _block(id: 'simulation', type: StudyPlanBlockType.examSimulation),
      ];
      final plan = _plan(blocks);
      const service = ReadinessActionIntegrationService();
      final expected = <ReadinessNextActionKind, String>{
        ReadinessNextActionKind.diagnostic: 'diagnostic',
        ReadinessNextActionKind.targetedPractice: 'practice',
        ReadinessNextActionKind.flashcardReview: 'flashcards',
        ReadinessNextActionKind.studyReview: 'study',
        ReadinessNextActionKind.lab: 'lab',
        ReadinessNextActionKind.confidenceCalibration: 'confidence',
        ReadinessNextActionKind.simulation: 'simulation',
      };

      for (final entry in expected.entries) {
        final binding = service.bind(
          readiness: _readiness(_action(entry.key)),
          plan: plan,
        );
        expect(binding.requiresReplan, isFalse, reason: entry.key.name);
        expect(binding.block?.blockId, entry.value, reason: entry.key.name);
      }
    });

    test('missing action target requests authoritative replanning', () {
      const service = ReadinessActionIntegrationService();
      final binding = service.bind(
        readiness: _readiness(_action(ReadinessNextActionKind.lab)),
        plan: _plan(<StudyPlanBlock>[
          _block(id: 'study-only', type: StudyPlanBlockType.learn),
        ]),
      );

      expect(binding.block, isNull);
      expect(binding.requiresReplan, isTrue);
      expect(binding.reasonCode, 'ERDP7_AUTHORITATIVE_PLAN_REPLAN_REQUIRED');
    });

    test('started compatible block wins so readiness resumes rather than duplicates', () {
      const service = ReadinessActionIntegrationService();
      final binding = service.bind(
        readiness: _readiness(_action(ReadinessNextActionKind.targetedPractice)),
        plan: _plan(<StudyPlanBlock>[
          _block(id: 'planned', type: StudyPlanBlockType.standardPractice),
          _block(
            id: 'started',
            type: StudyPlanBlockType.mixedRetrieval,
            status: StudyPlanBlockStatus.started,
          ),
        ]),
      );

      expect(binding.block?.blockId, 'started');
      expect(binding.reasonCode, 'ERDP7_RESUME_AUTHORITATIVE_PLAN_BLOCK');
    });
  });

  test('near-exam phase turns assessment-balance practice into Simulation', () {
    final profiles = <String, CompetencyReadinessProfile>{};
    for (var domain = 1; domain <= 7; domain++) {
      for (var competency = 1; competency <= 20; competency++) {
        final id = 'd${domain.toString().padLeft(2, '0')}_c${competency.toString().padLeft(2, '0')}';
        profiles[id] = m7dProfile(
          competencyId: id,
          readinessState: ReadinessState.stable,
          evidenceConfidence: EvidenceConfidence.veryHigh,
          knowledge: 0.9,
          application: 0.9,
          retention: 0.9,
          coverage: 0.95,
          difficulty: 0.85,
          calibration: 0.9,
        );
      }
    }

    final date = DateTime(2026, 9, 28);
    final plan = const PhaseAwareDailyPlanService().generate(
      userId: 'erdp7-user',
      date: date,
      generatedAt: date,
      examDate: DateTime(2026, 10, 5),
      availableMinutes: 120,
      readinessProfiles: profiles,
    );

    expect(
      plan.blocks.any((block) => block.type == StudyPlanBlockType.examSimulation),
      isTrue,
    );
  });
}
''',
)
