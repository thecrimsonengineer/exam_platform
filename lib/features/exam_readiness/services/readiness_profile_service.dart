import '../../../data/csp11_blueprint.dart';
import '../models/competency_evidence_snapshot.dart';
import '../models/competency_readiness_profile.dart';
import '../models/evidence_confidence.dart';
import '../models/learner_assessment_attempt.dart';
import '../models/readiness_gap.dart';
import 'readiness_gap_service.dart';

class ReadinessProfileService {
  const ReadinessProfileService({
    this.gapService = const ReadinessGapService(),
  });

  final ReadinessGapService gapService;

  CompetencyReadinessProfile buildCompetencyProfile({
    required CompetencyEvidenceSnapshot evidence,
    Iterable<LearnerAssessmentAttempt> attempts = const [],
    required DateTime now,
  }) {
    final relevantAttempts =
        attempts
            .where(
              (attempt) =>
                  attempt.publishedAtAttempt &&
                  attempt.competencyId.trim().toLowerCase() ==
                      evidence.competencyId.trim().toLowerCase(),
            )
            .toList(growable: false)
          ..sort((left, right) => left.answeredAt.compareTo(right.answeredAt));

    final knowledge = _knowledgeMastery(evidence);
    final application = _applicationAbility(evidence);
    final retention = _retention(evidence);
    final coverage = _coverage(evidence);
    final difficulty = _difficulty(evidence);
    final calibration = _calibration(evidence);
    final recent = _recentPerformance(evidence, relevantAttempts, now);
    final stability = _stability(evidence, relevantAttempts);

    final gaps = gapService.build(
      evidence: evidence,
      knowledge: knowledge,
      application: application,
      retention: retention,
      coverage: coverage,
      difficulty: difficulty,
      calibration: calibration,
    );

    final state = _state(
      evidence: evidence,
      knowledge: knowledge,
      application: application,
      retention: retention,
      stability: stability,
      gaps: gaps,
    );

    final limitingFactors = <String>[
      for (final gap in gaps)
        if (gap.severity == ReadinessGapSeverity.high ||
            gap.severity == ReadinessGapSeverity.critical)
          gap.explanation,
    ];

    final codes = <String>{
      ...knowledge.reasonCodes,
      ...application.reasonCodes,
      ...retention.reasonCodes,
      ...coverage.reasonCodes,
      ...difficulty.dimension.reasonCodes,
      ...calibration.reasonCodes,
      ...recent.reasonCodes,
      ...stability.reasonCodes,
      ...gaps.map((gap) => gap.reasonCode),
    }.toList(growable: false);

    return CompetencyReadinessProfile(
      competencyId: evidence.competencyId,
      generatedAt: now,
      readinessAlgorithmVersion:
          CompetencyReadinessProfile.currentAlgorithmVersion,
      knowledgeMastery: knowledge,
      applicationAbility: application,
      retention: retention,
      difficultyPerformance: difficulty,
      blueprintCoverage: coverage,
      confidenceCalibration: calibration,
      recentPerformance: recent,
      stability: stability,
      evidenceConfidence: evidence.evidenceQuality.confidenceLevel,
      readinessState: state,
      gaps: List<ReadinessGap>.unmodifiable(gaps),
      limitingFactors: List<String>.unmodifiable(limitingFactors),
      explanationCodes: List<String>.unmodifiable(codes),
    );
  }

  ExamReadinessDashboard buildDashboard({
    required Map<String, CompetencyEvidenceSnapshot> evidenceByCompetency,
    Iterable<LearnerAssessmentAttempt> attempts = const [],
    required DateTime now,
  }) {
    final attemptsByCompetency = <String, List<LearnerAssessmentAttempt>>{};
    for (final attempt in attempts) {
      attemptsByCompetency
          .putIfAbsent(
            attempt.competencyId.trim().toLowerCase(),
            () => <LearnerAssessmentAttempt>[],
          )
          .add(attempt);
    }

    final profiles = <String, CompetencyReadinessProfile>{};

    for (final domain in csp11Domains) {
      for (final competency in domain.competencies) {
        final evidence = evidenceByCompetency[competency.id];
        if (evidence == null) {
          continue;
        }

        profiles[competency.id] = buildCompetencyProfile(
          evidence: evidence,
          attempts: attemptsByCompetency[competency.id] ?? const [],
          now: now,
        );
      }
    }

    final overallEvidence = _dashboardEvidenceConfidence(
      profiles.values.toList(growable: false),
    );

    final knowledge = _aggregateDimension(
      code: 'KNOWLEDGE_MASTERY',
      dimensions: profiles.values.map((profile) => profile.knowledgeMastery),
      overallEvidence: overallEvidence,
    );
    final application = _aggregateDimension(
      code: 'APPLICATION_ABILITY',
      dimensions: profiles.values.map((profile) => profile.applicationAbility),
      overallEvidence: overallEvidence,
    );
    final retention = _aggregateDimension(
      code: 'RETENTION',
      dimensions: profiles.values.map((profile) => profile.retention),
      overallEvidence: overallEvidence,
    );
    final difficulty = _aggregateDimension(
      code: 'DIFFICULTY_PERFORMANCE',
      dimensions: profiles.values.map(
        (profile) => profile.difficultyPerformance.dimension,
      ),
      overallEvidence: overallEvidence,
    );
    final calibration = _aggregateDimension(
      code: 'CONFIDENCE_CALIBRATION',
      dimensions: profiles.values.map(
        (profile) => profile.confidenceCalibration,
      ),
      overallEvidence: overallEvidence,
    );

    final coverage = _blueprintCoverage(evidenceByCompetency);
    final domainCoverage = _domainCoverage(evidenceByCompetency);

    final allGaps = profiles.values.expand((profile) => profile.gaps).toList();

    return ExamReadinessDashboard(
      generatedAt: now,
      algorithmVersion: CompetencyReadinessProfile.currentAlgorithmVersion,
      evidenceConfidence: overallEvidence,
      knowledgeMastery: knowledge,
      applicationAbility: application,
      retention: retention,
      blueprintCoverage: coverage,
      difficultyPerformance: difficulty,
      confidenceCalibration: calibration,
      criticalGapCount: allGaps
          .where((gap) => gap.severity == ReadinessGapSeverity.critical)
          .length,
      weakCompetencyCount: profiles.values
          .where(
            (profile) =>
                profile.readinessState == ReadinessState.atRisk ||
                profile.readinessState == ReadinessState.learning,
          )
          .length,
      evidenceGapCount: allGaps
          .where((gap) => gap.type == ReadinessGapType.evidenceGap)
          .length,
      staleCompetencyCount: profiles.values
          .where((profile) => profile.readinessState == ReadinessState.stale)
          .length,
      profiles: Map<String, CompetencyReadinessProfile>.unmodifiable(profiles),
      domainCoverage: Map<String, BlueprintCoverageSummary>.unmodifiable(
        domainCoverage,
      ),
    );
  }

  ReadinessDimension _knowledgeMastery(CompetencyEvidenceSnapshot evidence) {
    if (!_performanceEvidenceSufficient(evidence)) {
      return ReadinessDimension(
        code: 'KNOWLEDGE_MASTERY',
        value: null,
        evidenceConfidence: evidence.evidenceQuality.confidenceLevel,
        reasonCodes: const ['INSUFFICIENT_KNOWLEDGE_EVIDENCE'],
      );
    }

    final accuracy = evidence.attempts.accuracy ?? 0;
    final breadth = evidence.coverage.coverageRatio;
    final freshness = _recencyFactor(evidence.recency.band);
    final repeatDiversity =
        1 - evidence.evidenceQuality.breakdown.repeatedAttemptConcentration;

    final score = _weighted([
      (accuracy, 0.55),
      (breadth, 0.20),
      (freshness, 0.15),
      (repeatDiversity.clamp(0, 1), 0.10),
    ]);

    return ReadinessDimension(
      code: 'KNOWLEDGE_MASTERY',
      value: score,
      evidenceConfidence: evidence.evidenceQuality.confidenceLevel,
      reasonCodes: const ['KNOWLEDGE_EVIDENCE_AVAILABLE'],
    );
  }

  ReadinessDimension _applicationAbility(CompetencyEvidenceSnapshot evidence) {
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

  ReadinessDimension _retention(CompetencyEvidenceSnapshot evidence) {
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

  ReadinessDimension _coverage(CompetencyEvidenceSnapshot evidence) {
    return ReadinessDimension(
      code: 'BLUEPRINT_COVERAGE',
      value: evidence.coverage.coverageRatio,
      evidenceConfidence: evidence.evidenceQuality.breakdown.breadth,
      reasonCodes: const ['CANONICAL_BLUEPRINT_COVERAGE'],
    );
  }

  DifficultyReadinessProfile _difficulty(CompetencyEvidenceSnapshot evidence) {
    final values = <(double, double)>[];

    if (evidence.difficulty.standardAccuracy != null) {
      values.add((evidence.difficulty.standardAccuracy!, 0.25));
    }
    if (evidence.difficulty.hardAccuracy != null) {
      values.add((evidence.difficulty.hardAccuracy!, 0.35));
    }
    if (evidence.difficulty.ultraHardAccuracy != null) {
      values.add((evidence.difficulty.ultraHardAccuracy!, 0.40));
    }

    if (values.isEmpty) {
      return DifficultyReadinessProfile(
        standardAccuracy: null,
        hardAccuracy: null,
        ultraHardAccuracy: null,
        dimension: ReadinessDimension(
          code: 'DIFFICULTY_PERFORMANCE',
          value: null,
          evidenceConfidence: EvidenceConfidence.none,
          reasonCodes: const ['DIFFICULTY_EVIDENCE_MISSING'],
        ),
        state: DifficultyReadinessState.unavailable,
      );
    }

    final score = _weighted(values);
    final state = score >= 0.78
        ? DifficultyReadinessState.strong
        : score >= 0.60
        ? DifficultyReadinessState.developing
        : DifficultyReadinessState.emerging;

    return DifficultyReadinessProfile(
      standardAccuracy: evidence.difficulty.standardAccuracy,
      hardAccuracy: evidence.difficulty.hardAccuracy,
      ultraHardAccuracy: evidence.difficulty.ultraHardAccuracy,
      dimension: ReadinessDimension(
        code: 'DIFFICULTY_PERFORMANCE',
        value: score,
        evidenceConfidence: evidence.evidenceQuality.breakdown.difficulty,
        reasonCodes: const ['DIFFICULTY_LANES_INTERPRETED'],
      ),
      state: state,
    );
  }

  ReadinessDimension _calibration(CompetencyEvidenceSnapshot evidence) {
    if (evidence.confidence.confidenceSamples < 3 ||
        evidence.confidence.calibrationError == null) {
      return ReadinessDimension(
        code: 'CONFIDENCE_CALIBRATION',
        value: null,
        evidenceConfidence: EvidenceConfidence.none,
        reasonCodes: const ['CONFIDENCE_EVIDENCE_MISSING'],
      );
    }

    final score = (1 - evidence.confidence.calibrationError!).clamp(0, 1);

    return ReadinessDimension(
      code: 'CONFIDENCE_CALIBRATION',
      value: score,
      evidenceConfidence: _sampleConfidence(
        evidence.confidence.confidenceSamples,
      ),
      reasonCodes: evidence.confidence.highConfidenceIncorrectCount >= 2
          ? const ['HIGH_CONFIDENCE_INCORRECT_PATTERN']
          : const ['CONFIDENCE_CALIBRATION_AVAILABLE'],
    );
  }

  ReadinessDimension _recentPerformance(
    CompetencyEvidenceSnapshot evidence,
    List<LearnerAssessmentAttempt> attempts,
    DateTime now,
  ) {
    final recent = attempts
        .where(
          (attempt) => !attempt.answeredAt.isBefore(
            now.subtract(const Duration(days: 30)),
          ),
        )
        .toList(growable: false);

    if (recent.length < 3) {
      return ReadinessDimension(
        code: 'RECENT_PERFORMANCE',
        value: null,
        evidenceConfidence: evidence.evidenceQuality.breakdown.recency,
        reasonCodes: const ['INSUFFICIENT_RECENT_PERFORMANCE_EVIDENCE'],
      );
    }

    final correct = recent.where((attempt) => attempt.correct).length;
    return ReadinessDimension(
      code: 'RECENT_PERFORMANCE',
      value: correct / recent.length,
      evidenceConfidence: _sampleConfidence(recent.length),
      reasonCodes: const ['RECENT_30_DAY_PERFORMANCE_AVAILABLE'],
    );
  }

  ReadinessDimension _stability(
    CompetencyEvidenceSnapshot evidence,
    List<LearnerAssessmentAttempt> attempts,
  ) {
    if (attempts.length < 6) {
      return ReadinessDimension(
        code: 'STABILITY',
        value: null,
        evidenceConfidence: EvidenceConfidence.none,
        reasonCodes: const ['INSUFFICIENT_STABILITY_EVIDENCE'],
      );
    }

    final window = attempts.length > 10
        ? attempts.sublist(attempts.length - 10)
        : attempts;
    final split = window.length ~/ 2;
    final first = window.sublist(0, split);
    final second = window.sublist(split);

    double accuracy(List<LearnerAssessmentAttempt> values) =>
        values.where((attempt) => attempt.correct).length / values.length;

    final drift = (accuracy(first) - accuracy(second)).abs();
    final repeatPenalty =
        evidence.evidenceQuality.breakdown.repeatedAttemptConcentration * 0.25;
    final score = (1 - drift - repeatPenalty).clamp(0, 1);

    return ReadinessDimension(
      code: 'STABILITY',
      value: score,
      evidenceConfidence: _sampleConfidence(window.length),
      reasonCodes: const ['PERFORMANCE_STABILITY_AVAILABLE'],
    );
  }

  ReadinessState _state({
    required CompetencyEvidenceSnapshot evidence,
    required ReadinessDimension knowledge,
    required ReadinessDimension application,
    required ReadinessDimension retention,
    required ReadinessDimension stability,
    required List<ReadinessGap> gaps,
  }) {
    if (evidence.sourceAttemptCount == 0) {
      return ReadinessState.unknown;
    }

    if (evidence.evidenceQuality.state == EvidenceState.stale) {
      return ReadinessState.stale;
    }

    final confidence = evidence.evidenceQuality.confidenceLevel;
    if (confidence == EvidenceConfidence.none ||
        confidence == EvidenceConfidence.veryLow) {
      return ReadinessState.insufficientEvidence;
    }

    final performanceGaps = gaps.where((gap) => !gap.evidenceLimited).toList();
    final hasCriticalPerformanceGap = performanceGaps.any(
      (gap) => gap.severity == ReadinessGapSeverity.critical,
    );
    final hasHighPerformanceGap = performanceGaps.any(
      (gap) => gap.severity == ReadinessGapSeverity.high,
    );

    if (confidence.rank >= EvidenceConfidence.high.rank &&
        (hasCriticalPerformanceGap || hasHighPerformanceGap)) {
      return ReadinessState.atRisk;
    }

    final values = <double>[
      if (knowledge.value != null) knowledge.value!,
      if (application.value != null) application.value!,
      if (retention.value != null) retention.value!,
    ];

    if (values.isEmpty) {
      return ReadinessState.insufficientEvidence;
    }

    final mean = values.reduce((a, b) => a + b) / values.length;

    if (confidence == EvidenceConfidence.low && mean >= 0.70) {
      return ReadinessState.provisional;
    }

    if (confidence.rank >= EvidenceConfidence.high.rank &&
        mean >= 0.78 &&
        retention.value != null &&
        retention.value! >= 0.70 &&
        stability.value != null &&
        stability.value! >= 0.70) {
      return ReadinessState.stable;
    }

    if (mean >= 0.75 && confidence.rank >= EvidenceConfidence.moderate.rank) {
      return ReadinessState.strong;
    }

    if (mean >= 0.58) {
      return ReadinessState.developing;
    }

    return ReadinessState.learning;
  }

  bool _performanceEvidenceSufficient(CompetencyEvidenceSnapshot evidence) {
    return evidence.attempts.total >= 3 &&
        evidence.attempts.uniqueQuestions >= 2 &&
        evidence.evidenceQuality.confidenceLevel.rank >=
            EvidenceConfidence.low.rank;
  }

  EvidenceConfidence _sampleConfidence(int samples) {
    if (samples <= 0) return EvidenceConfidence.none;
    if (samples <= 2) return EvidenceConfidence.veryLow;
    if (samples <= 4) return EvidenceConfidence.low;
    if (samples <= 7) return EvidenceConfidence.moderate;
    if (samples <= 12) return EvidenceConfidence.high;
    return EvidenceConfidence.veryHigh;
  }

  double _recencyFactor(EvidenceRecencyBand band) {
    return switch (band) {
      EvidenceRecencyBand.noEvidence => 0,
      EvidenceRecencyBand.veryRecent => 1,
      EvidenceRecencyBand.recent => 0.85,
      EvidenceRecencyBand.aging => 0.65,
      EvidenceRecencyBand.stale => 0.40,
      EvidenceRecencyBand.veryStale => 0.20,
    };
  }

  double _weighted(List<(double, double)> values) {
    if (values.isEmpty) return 0;
    final weight = values.fold<double>(0, (sum, item) => sum + item.$2);
    if (weight <= 0) return 0;
    final value = values.fold<double>(
      0,
      (sum, item) => sum + item.$1.clamp(0, 1) * item.$2,
    );
    return (value / weight).clamp(0, 1);
  }

  EvidenceConfidence _dashboardEvidenceConfidence(
    List<CompetencyReadinessProfile> profiles,
  ) {
    if (profiles.isEmpty) return EvidenceConfidence.none;

    final canonicalTotal = csp11Domains.fold<int>(
      0,
      (sum, domain) => sum + domain.competencies.length,
    );
    final represented = profiles.length / canonicalTotal;
    final averageRank =
        profiles
            .map((profile) => profile.evidenceConfidence.rank)
            .fold<int>(0, (sum, rank) => sum + rank) /
        profiles.length;

    var rank = averageRank.round();
    if (represented < 0.20) {
      rank = rank.clamp(0, EvidenceConfidence.low.rank);
    } else if (represented < 0.45) {
      rank = rank.clamp(0, EvidenceConfidence.moderate.rank);
    }

    return EvidenceConfidence.values[rank.clamp(
      0,
      EvidenceConfidence.veryHigh.rank,
    )];
  }

  ReadinessDimension _aggregateDimension({
    required String code,
    required Iterable<ReadinessDimension> dimensions,
    required EvidenceConfidence overallEvidence,
  }) {
    final available = dimensions
        .where((dimension) => dimension.value != null)
        .toList(growable: false);

    if (available.length < 3 ||
        overallEvidence.rank < EvidenceConfidence.low.rank) {
      return ReadinessDimension(
        code: code,
        value: null,
        evidenceConfidence: overallEvidence,
        reasonCodes: const ['INSUFFICIENT_AGGREGATE_EVIDENCE'],
      );
    }

    final value =
        available.map((item) => item.value!).reduce((a, b) => a + b) /
        available.length;

    return ReadinessDimension(
      code: code,
      value: value.clamp(0, 1),
      evidenceConfidence: overallEvidence,
      reasonCodes: const ['AGGREGATED_COMPETENCY_EVIDENCE'],
    );
  }

  BlueprintCoverageSummary _blueprintCoverage(
    Map<String, CompetencyEvidenceSnapshot> evidenceByCompetency,
  ) {
    var competenciesTotal = 0;
    var competenciesAssessed = 0;
    var topicsTotal = 0;
    var topicsAssessed = 0;
    var subtopicsTotal = 0;
    var subtopicsAssessed = 0;

    for (final domain in csp11Domains) {
      competenciesTotal += domain.competencies.length;

      for (final competency in domain.competencies) {
        final evidence = evidenceByCompetency[competency.id];
        if (evidence == null) continue;

        if (evidence.sourceAttemptCount > 0) {
          competenciesAssessed++;
        }
        topicsTotal += evidence.coverage.topicsAvailable;
        topicsAssessed += evidence.coverage.topicsAssessed;
        subtopicsTotal += evidence.coverage.subtopicsAvailable;
        subtopicsAssessed += evidence.coverage.subtopicsAssessed;
      }
    }

    return BlueprintCoverageSummary(
      competenciesTotal: competenciesTotal,
      competenciesAssessed: competenciesAssessed,
      topicsTotal: topicsTotal,
      topicsAssessed: topicsAssessed,
      subtopicsTotal: subtopicsTotal,
      subtopicsAssessed: subtopicsAssessed,
    );
  }

  Map<String, BlueprintCoverageSummary> _domainCoverage(
    Map<String, CompetencyEvidenceSnapshot> evidenceByCompetency,
  ) {
    final result = <String, BlueprintCoverageSummary>{};

    for (final domain in csp11Domains) {
      var assessedCompetencies = 0;
      var topicsTotal = 0;
      var topicsAssessed = 0;
      var subtopicsTotal = 0;
      var subtopicsAssessed = 0;

      for (final competency in domain.competencies) {
        final evidence = evidenceByCompetency[competency.id];
        if (evidence == null) continue;

        if (evidence.sourceAttemptCount > 0) {
          assessedCompetencies++;
        }
        topicsTotal += evidence.coverage.topicsAvailable;
        topicsAssessed += evidence.coverage.topicsAssessed;
        subtopicsTotal += evidence.coverage.subtopicsAvailable;
        subtopicsAssessed += evidence.coverage.subtopicsAssessed;
      }

      result[domain.id] = BlueprintCoverageSummary(
        competenciesTotal: domain.competencies.length,
        competenciesAssessed: assessedCompetencies,
        topicsTotal: topicsTotal,
        topicsAssessed: topicsAssessed,
        subtopicsTotal: subtopicsTotal,
        subtopicsAssessed: subtopicsAssessed,
      );
    }

    return result;
  }
}
