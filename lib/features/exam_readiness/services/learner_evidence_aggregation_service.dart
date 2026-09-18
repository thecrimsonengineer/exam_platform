import '../models/competency_evidence_snapshot.dart';
import '../models/evidence_confidence.dart';
import '../models/learner_assessment_attempt.dart';
import 'retention_evidence_service.dart';

class CompetencyEvidenceScope {
  const CompetencyEvidenceScope({
    required this.competencyId,
    this.topicIds = const <String>{},
    this.subtopicIds = const <String>{},
  });

  final String competencyId;
  final Set<String> topicIds;
  final Set<String> subtopicIds;
}

class LearnerEvidenceAggregationService {
  const LearnerEvidenceAggregationService({
    this.retentionService = const RetentionEvidenceService(),
  });

  final RetentionEvidenceService retentionService;

  CompetencyEvidenceSnapshot buildSnapshot({
    required String competencyId,
    required Iterable<LearnerAssessmentAttempt> attempts,
    required CompetencyEvidenceScope scope,
    required DateTime now,
  }) {
    final normalizedCompetency = competencyId.trim().toLowerCase();

    final deduplicated = <String, LearnerAssessmentAttempt>{};
    for (final attempt in attempts) {
      if (!attempt.publishedAtAttempt ||
          !attempt.hasCanonicalCompetencyId ||
          attempt.competencyId.trim().toLowerCase() != normalizedCompetency ||
          attempt.attemptId.trim().isEmpty ||
          attempt.questionId <= 0) {
        continue;
      }
      deduplicated.putIfAbsent(attempt.attemptId, () => attempt);
    }

    final evidence = deduplicated.values.toList(growable: false)
      ..sort((left, right) => left.answeredAt.compareTo(right.answeredAt));

    final availableTopics = scope.topicIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    final availableSubtopics = scope.subtopicIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();

    final assessedTopics = evidence
        .map((item) => item.topicId.trim())
        .where((item) => item.isNotEmpty)
        .where((item) => availableTopics.isEmpty || availableTopics.contains(item))
        .toSet();

    final assessedSubtopics = evidence
        .map((item) => item.subtopicId.trim())
        .where((item) => item.isNotEmpty)
        .where(
          (item) =>
              availableSubtopics.isEmpty || availableSubtopics.contains(item),
        )
        .toSet();

    final coverage = EvidenceCoverage(
      topicsAvailable: availableTopics.length,
      topicsAssessed: assessedTopics.length,
      subtopicsAvailable: availableSubtopics.length,
      subtopicsAssessed: assessedSubtopics.length,
    );

    final uniqueQuestions = evidence.map((item) => item.questionId).toSet();
    final correct = evidence.where((item) => item.correct).length;

    final attemptStats = AttemptEvidenceStats(
      total: evidence.length,
      correct: correct,
      incorrect: evidence.length - correct,
      uniqueQuestions: uniqueQuestions.length,
      repeatedAttempts: evidence.length - uniqueQuestions.length,
    );

    var recallAttempts = 0;
    var recallCorrect = 0;
    var applicationAttempts = 0;
    var applicationCorrect = 0;
    var analysisAttempts = 0;
    var analysisCorrect = 0;

    var standardAttempts = 0;
    var standardCorrect = 0;
    var hardAttempts = 0;
    var hardCorrect = 0;
    var ultraHardAttempts = 0;
    var ultraHardCorrect = 0;

    for (final attempt in evidence) {
      switch (_cognitiveLane(attempt.cognitiveLevel)) {
        case _CognitiveLane.recall:
          recallAttempts++;
          if (attempt.correct) recallCorrect++;
          break;
        case _CognitiveLane.application:
          applicationAttempts++;
          if (attempt.correct) applicationCorrect++;
          break;
        case _CognitiveLane.analysis:
          analysisAttempts++;
          if (attempt.correct) analysisCorrect++;
          break;
      }

      switch (attempt.difficultyLane) {
        case AttemptDifficultyLane.standard:
          standardAttempts++;
          if (attempt.correct) standardCorrect++;
          break;
        case AttemptDifficultyLane.hard:
          hardAttempts++;
          if (attempt.correct) hardCorrect++;
          break;
        case AttemptDifficultyLane.ultraHard:
          ultraHardAttempts++;
          if (attempt.correct) ultraHardCorrect++;
          break;
      }
    }

    final cognition = CognitionEvidenceStats(
      recallAttempts: recallAttempts,
      recallCorrect: recallCorrect,
      applicationAttempts: applicationAttempts,
      applicationCorrect: applicationCorrect,
      analysisAttempts: analysisAttempts,
      analysisCorrect: analysisCorrect,
    );

    final difficulty = DifficultyEvidenceStats(
      standardAttempts: standardAttempts,
      standardCorrect: standardCorrect,
      hardAttempts: hardAttempts,
      hardCorrect: hardCorrect,
      ultraHardAttempts: ultraHardAttempts,
      ultraHardCorrect: ultraHardCorrect,
    );

    final retention = retentionService.build(attempts: evidence, now: now);
    final confidence = _confidenceCalibration(evidence);
    final recency = _recency(evidence, now);

    final repeatedAttemptConcentration = evidence.isEmpty
        ? 0.0
        : attemptStats.repeatedAttempts / evidence.length;

    final quantityLevel = _quantityLevel(
      totalAttempts: evidence.length,
      uniqueQuestions: uniqueQuestions.length,
    );
    final breadthLevel = _breadthLevel(
      coverage: coverage,
      uniqueQuestions: uniqueQuestions.length,
    );
    final recencyLevel = _recencyConfidence(recency.band);
    final difficultyLevel = _difficultyConfidence(difficulty);
    final retentionLevel = _retentionConfidence(retention);
    final diversityLevel = _diversityConfidence(
      cognition: cognition,
      difficulty: difficulty,
    );

    final overall = _overallConfidence(
      totalAttempts: evidence.length,
      breadth: breadthLevel,
      levels: [
        quantityLevel,
        breadthLevel,
        recencyLevel,
        difficultyLevel,
        retentionLevel,
        diversityLevel,
      ],
      repeatedAttemptConcentration: repeatedAttemptConcentration,
    );

    final breakdown = EvidenceConfidenceBreakdown(
      quantity: quantityLevel,
      breadth: breadthLevel,
      recency: recencyLevel,
      difficulty: difficultyLevel,
      retention: retentionLevel,
      diversity: diversityLevel,
      overall: overall,
      repeatedAttemptConcentration: repeatedAttemptConcentration,
    );

    final state = _evidenceState(
      attempts: evidence.length,
      overall: overall,
      recencyBand: recency.band,
    );

    final quality = EvidenceQualitySnapshot(
      quantity: quantityLevel,
      breadth: breadthLevel,
      recency: recencyLevel,
      diversity: diversityLevel,
      confidenceLevel: overall,
      breakdown: breakdown,
      state: state,
    );

    return CompetencyEvidenceSnapshot(
      competencyId: normalizedCompetency,
      generatedAt: now,
      schemaVersion: CompetencyEvidenceSnapshot.currentSchemaVersion,
      algorithmVersion: CompetencyEvidenceSnapshot.currentAlgorithmVersion,
      sourceAttemptCount: evidence.length,
      coverage: coverage,
      attempts: attemptStats,
      cognition: cognition,
      difficulty: difficulty,
      retention: retention,
      confidence: confidence,
      recency: recency,
      evidenceQuality: quality,
      traceability: _traceability(
        attempts: attemptStats,
        coverage: coverage,
        cognition: cognition,
        difficulty: difficulty,
        retention: retention,
        recency: recency,
        confidence: confidence,
      ),
    );
  }

  Map<String, CompetencyEvidenceSnapshot> buildAllSnapshots({
    required Iterable<LearnerAssessmentAttempt> attempts,
    required Iterable<CompetencyEvidenceScope> scopes,
    required DateTime now,
  }) {
    final result = <String, CompetencyEvidenceSnapshot>{};

    for (final scope in scopes) {
      final competencyId = scope.competencyId.trim().toLowerCase();
      if (competencyId.isEmpty) {
        continue;
      }

      result[competencyId] = buildSnapshot(
        competencyId: competencyId,
        attempts: attempts,
        scope: scope,
        now: now,
      );
    }

    return Map<String, CompetencyEvidenceSnapshot>.unmodifiable(result);
  }

  CompetencyEvidenceSnapshot updateCompetencySnapshot({
    required String competencyId,
    required Iterable<LearnerAssessmentAttempt> attemptsForCompetency,
    required CompetencyEvidenceScope scope,
    required DateTime now,
  }) {
    return buildSnapshot(
      competencyId: competencyId,
      attempts: attemptsForCompetency,
      scope: scope,
      now: now,
    );
  }

  ConfidenceCalibrationStats _confidenceCalibration(
    List<LearnerAssessmentAttempt> attempts,
  ) {
    final samples = attempts
        .where((attempt) => attempt.confidence != null)
        .toList(growable: false);

    if (samples.isEmpty) {
      return const ConfidenceCalibrationStats(
        confidenceSamples: 0,
        calibrationError: null,
        overconfidenceRate: null,
        underconfidenceRate: null,
        highConfidenceIncorrectCount: 0,
      );
    }

    var absoluteError = 0.0;
    var highConfidenceIncorrect = 0;
    var lowConfidenceCorrect = 0;

    for (final attempt in samples) {
      final predicted = switch (attempt.confidence!) {
        LearnerConfidenceLevel.low => 0.25,
        LearnerConfidenceLevel.medium => 0.60,
        LearnerConfidenceLevel.high => 0.85,
      };
      final observed = attempt.correct ? 1.0 : 0.0;
      absoluteError += (predicted - observed).abs();

      if (attempt.confidence == LearnerConfidenceLevel.high &&
          !attempt.correct) {
        highConfidenceIncorrect++;
      }

      if (attempt.confidence == LearnerConfidenceLevel.low && attempt.correct) {
        lowConfidenceCorrect++;
      }
    }

    return ConfidenceCalibrationStats(
      confidenceSamples: samples.length,
      calibrationError: absoluteError / samples.length,
      overconfidenceRate: highConfidenceIncorrect / samples.length,
      underconfidenceRate: lowConfidenceCorrect / samples.length,
      highConfidenceIncorrectCount: highConfidenceIncorrect,
    );
  }

  RecencyEvidenceStats _recency(
    List<LearnerAssessmentAttempt> attempts,
    DateTime now,
  ) {
    if (attempts.isEmpty) {
      return const RecencyEvidenceStats(
        attempts7d: 0,
        attempts30d: 0,
        lastAttemptAt: null,
        band: EvidenceRecencyBand.noEvidence,
      );
    }

    final latest = attempts
        .map((attempt) => attempt.answeredAt)
        .reduce((left, right) => left.isAfter(right) ? left : right);

    final attempts7d = attempts
        .where(
          (attempt) =>
              !attempt.answeredAt.isBefore(now.subtract(const Duration(days: 7))),
        )
        .length;
    final attempts30d = attempts
        .where(
          (attempt) => !attempt.answeredAt.isBefore(
            now.subtract(const Duration(days: 30)),
          ),
        )
        .length;

    final days = now.difference(latest).inDays.clamp(0, 1 << 30);

    return RecencyEvidenceStats(
      attempts7d: attempts7d,
      attempts30d: attempts30d,
      lastAttemptAt: latest,
      band: _recencyBand(days),
    );
  }

  EvidenceRecencyBand _recencyBand(int days) {
    if (days <= 7) return EvidenceRecencyBand.veryRecent;
    if (days <= 30) return EvidenceRecencyBand.recent;
    if (days <= 60) return EvidenceRecencyBand.aging;
    if (days <= 90) return EvidenceRecencyBand.stale;
    return EvidenceRecencyBand.veryStale;
  }

  EvidenceConfidence _quantityLevel({
    required int totalAttempts,
    required int uniqueQuestions,
  }) {
    if (totalAttempts == 0) return EvidenceConfidence.none;
    if (uniqueQuestions <= 1 || totalAttempts <= 2) {
      return EvidenceConfidence.veryLow;
    }
    if (uniqueQuestions <= 3 || totalAttempts <= 5) {
      return EvidenceConfidence.low;
    }
    if (uniqueQuestions <= 6 || totalAttempts <= 11) {
      return EvidenceConfidence.moderate;
    }
    if (uniqueQuestions <= 12 || totalAttempts <= 24) {
      return EvidenceConfidence.high;
    }
    return EvidenceConfidence.veryHigh;
  }

  EvidenceConfidence _breadthLevel({
    required EvidenceCoverage coverage,
    required int uniqueQuestions,
  }) {
    if (uniqueQuestions == 0) return EvidenceConfidence.none;
    final ratio = coverage.coverageRatio;
    if (ratio == 0) return EvidenceConfidence.veryLow;
    if (ratio < 0.25) return EvidenceConfidence.low;
    if (ratio < 0.50) return EvidenceConfidence.moderate;
    if (ratio < 0.80) return EvidenceConfidence.high;
    return EvidenceConfidence.veryHigh;
  }

  EvidenceConfidence _recencyConfidence(EvidenceRecencyBand band) {
    return switch (band) {
      EvidenceRecencyBand.noEvidence => EvidenceConfidence.none,
      EvidenceRecencyBand.veryRecent => EvidenceConfidence.veryHigh,
      EvidenceRecencyBand.recent => EvidenceConfidence.high,
      EvidenceRecencyBand.aging => EvidenceConfidence.moderate,
      EvidenceRecencyBand.stale => EvidenceConfidence.low,
      EvidenceRecencyBand.veryStale => EvidenceConfidence.veryLow,
    };
  }

  EvidenceConfidence _difficultyConfidence(DifficultyEvidenceStats stats) {
    if (stats.activeLanes == 0) return EvidenceConfidence.none;
    if (stats.activeLanes == 1) return EvidenceConfidence.low;
    if (stats.activeLanes == 2) return EvidenceConfidence.high;
    return EvidenceConfidence.veryHigh;
  }

  EvidenceConfidence _retentionConfidence(RetentionEvidenceStats stats) {
    if (stats.delayedAttempts == 0) return EvidenceConfidence.none;
    if (stats.delayedAttempts <= 2) return EvidenceConfidence.low;
    if (stats.delayedAttempts <= 5) return EvidenceConfidence.moderate;
    if (stats.delayedAttempts <= 10) return EvidenceConfidence.high;
    return EvidenceConfidence.veryHigh;
  }

  EvidenceConfidence _diversityConfidence({
    required CognitionEvidenceStats cognition,
    required DifficultyEvidenceStats difficulty,
  }) {
    final lanes = cognition.activeLanes + difficulty.activeLanes;
    if (lanes == 0) return EvidenceConfidence.none;
    if (lanes <= 2) return EvidenceConfidence.low;
    if (lanes <= 4) return EvidenceConfidence.moderate;
    if (lanes == 5) return EvidenceConfidence.high;
    return EvidenceConfidence.veryHigh;
  }

  EvidenceConfidence _overallConfidence({
    required int totalAttempts,
    required EvidenceConfidence breadth,
    required List<EvidenceConfidence> levels,
    required double repeatedAttemptConcentration,
  }) {
    if (totalAttempts == 0) return EvidenceConfidence.none;

    final nonNone = levels.where((level) => level != EvidenceConfidence.none);
    if (nonNone.isEmpty) return EvidenceConfidence.veryLow;

    var average =
        nonNone.map((level) => level.rank).reduce((a, b) => a + b) /
            nonNone.length;

    if (repeatedAttemptConcentration > 0.60) {
      average -= 1;
    } else if (repeatedAttemptConcentration > 0.35) {
      average -= 0.5;
    }

    if (breadth == EvidenceConfidence.none ||
        breadth == EvidenceConfidence.veryLow) {
      average = average.clamp(0, EvidenceConfidence.low.rank.toDouble());
    }

    final rank = average.round().clamp(
      EvidenceConfidence.veryLow.rank,
      EvidenceConfidence.veryHigh.rank,
    );
    return EvidenceConfidence.values[rank];
  }

  EvidenceState _evidenceState({
    required int attempts,
    required EvidenceConfidence overall,
    required EvidenceRecencyBand recencyBand,
  }) {
    if (attempts == 0) return EvidenceState.unassessed;
    if (recencyBand == EvidenceRecencyBand.stale ||
        recencyBand == EvidenceRecencyBand.veryStale) {
      return EvidenceState.stale;
    }

    return switch (overall) {
      EvidenceConfidence.none ||
      EvidenceConfidence.veryLow => EvidenceState.insufficient,
      EvidenceConfidence.low => EvidenceState.emerging,
      EvidenceConfidence.moderate => EvidenceState.adequate,
      EvidenceConfidence.high ||
      EvidenceConfidence.veryHigh => EvidenceState.robust,
    };
  }

  List<String> _traceability({
    required AttemptEvidenceStats attempts,
    required EvidenceCoverage coverage,
    required CognitionEvidenceStats cognition,
    required DifficultyEvidenceStats difficulty,
    required RetentionEvidenceStats retention,
    required RecencyEvidenceStats recency,
    required ConfidenceCalibrationStats confidence,
  }) {
    final lines = <String>[
      '${attempts.total} eligible attempts from '
          '${attempts.uniqueQuestions} unique questions',
      '${coverage.subtopicsAssessed}/${coverage.subtopicsAvailable} '
          'subtopics assessed',
      '${coverage.topicsAssessed}/${coverage.topicsAvailable} topics assessed',
      '${cognition.applicationAttempts + cognition.analysisAttempts} '
          'Application/Analysis attempts',
      '${difficulty.ultraHardAttempts} Ultra Hard attempts',
      '${recency.attempts30d} attempts in the last 30 days',
    ];

    if (retention.delayedAttempts == 0) {
      lines.add('No delayed retrieval evidence');
    } else {
      lines.add('${retention.delayedAttempts} delayed retrieval attempts');
    }

    if (confidence.confidenceSamples == 0) {
      lines.add('No learner-confidence samples');
    } else {
      lines.add('${confidence.confidenceSamples} learner-confidence samples');
    }

    return List<String>.unmodifiable(lines);
  }

  _CognitiveLane _cognitiveLane(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('analysis') ||
        normalized.contains('analy') ||
        normalized.contains('evaluat')) {
      return _CognitiveLane.analysis;
    }
    if (normalized.contains('application') ||
        normalized.contains('apply') ||
        normalized.contains('scenario')) {
      return _CognitiveLane.application;
    }
    return _CognitiveLane.recall;
  }
}

enum _CognitiveLane { recall, application, analysis }
