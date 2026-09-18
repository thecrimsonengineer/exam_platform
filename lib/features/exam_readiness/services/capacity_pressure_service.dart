import '../models/capacity_pressure_snapshot.dart';
import '../models/competency_readiness_profile.dart';
import '../models/exam_preparation_phase.dart';
import '../models/readiness_gap.dart';
import '../models/study_capacity_snapshot.dart';

class CapacityPressureConfiguration {
  const CapacityPressureConfiguration({
    this.criticalGapMinMinutes = 60,
    this.criticalGapMaxMinutes = 90,
    this.highGapMinMinutes = 40,
    this.highGapMaxMinutes = 60,
    this.evidenceBlindSpotMinMinutes = 15,
    this.evidenceBlindSpotMaxMinutes = 25,
    this.lowRatioUpperBound = 0.75,
    this.manageableRatioUpperBound = 1.0,
    this.elevatedRatioUpperBound = 1.25,
    this.highRatioUpperBound = 1.5,
    this.version = currentVersion,
  });

  static const String currentVersion = 'm7f-capacity-pressure-v1';

  final int criticalGapMinMinutes;
  final int criticalGapMaxMinutes;
  final int highGapMinMinutes;
  final int highGapMaxMinutes;
  final int evidenceBlindSpotMinMinutes;
  final int evidenceBlindSpotMaxMinutes;
  final double lowRatioUpperBound;
  final double manageableRatioUpperBound;
  final double elevatedRatioUpperBound;
  final double highRatioUpperBound;
  final String version;

  void validate() {
    if (criticalGapMinMinutes < 0 ||
        criticalGapMaxMinutes < criticalGapMinMinutes ||
        highGapMinMinutes < 0 ||
        highGapMaxMinutes < highGapMinMinutes ||
        evidenceBlindSpotMinMinutes < 0 ||
        evidenceBlindSpotMaxMinutes < evidenceBlindSpotMinMinutes) {
      throw StateError('Capacity pressure workload ranges are invalid.');
    }
    if (!(0 < lowRatioUpperBound &&
        lowRatioUpperBound < manageableRatioUpperBound &&
        manageableRatioUpperBound < elevatedRatioUpperBound &&
        elevatedRatioUpperBound < highRatioUpperBound)) {
      throw StateError('Capacity pressure ratio thresholds are invalid.');
    }
    if (version.trim().isEmpty) {
      throw StateError('Capacity pressure configuration must be versioned.');
    }
  }
}

class CapacityPressureService {
  const CapacityPressureService({
    this.configuration = const CapacityPressureConfiguration(),
  });

  final CapacityPressureConfiguration configuration;

  CapacityPressureSnapshot calculate({
    required StudyCapacitySnapshot capacity,
    required ExamPreparationPhase phase,
    required Iterable<CompetencyReadinessProfile> profiles,
    int scheduledReviewDebtMinutes = 0,
    DateTime? generatedAt,
  }) {
    configuration.validate();

    final profileList = profiles.toList(growable: false);
    var critical = 0;
    var high = 0;
    var blindSpots = 0;

    for (final profile in profileList) {
      var strongestObserved = ReadinessGapSeverity.low;
      var hasObserved = false;
      var hasEvidenceBlindSpot = false;

      for (final gap in profile.gaps) {
        if (gap.evidenceLimited || gap.type == ReadinessGapType.evidenceGap) {
          if (gap.severity == ReadinessGapSeverity.high ||
              gap.severity == ReadinessGapSeverity.critical) {
            hasEvidenceBlindSpot = true;
          }
          continue;
        }

        if (gap.severity.index > strongestObserved.index) {
          strongestObserved = gap.severity;
        }
        if (gap.severity == ReadinessGapSeverity.high ||
            gap.severity == ReadinessGapSeverity.critical) {
          hasObserved = true;
        }
      }

      if (hasObserved) {
        if (strongestObserved == ReadinessGapSeverity.critical) {
          critical++;
        } else {
          high++;
        }
      }
      if (hasEvidenceBlindSpot) {
        blindSpots++;
      }
    }

    final reviewDebt = scheduledReviewDebtMinutes.clamp(0, 1000000).toInt();
    final phaseMultiplier = _phaseMultiplier(phase);

    final rawMin =
        critical * configuration.criticalGapMinMinutes +
        high * configuration.highGapMinMinutes +
        blindSpots * configuration.evidenceBlindSpotMinMinutes +
        reviewDebt;
    final rawMax =
        critical * configuration.criticalGapMaxMinutes +
        high * configuration.highGapMaxMinutes +
        blindSpots * configuration.evidenceBlindSpotMaxMinutes +
        reviewDebt;

    final minMinutes = (rawMin * phaseMultiplier).round();
    final maxMinutes = (rawMax * phaseMultiplier).round();
    final available = capacity.plannedMinutesRemaining
        .clamp(0, 100000000)
        .toInt();

    final state = _state(
      availableMinutes: available,
      workloadMaxMinutes: maxMinutes,
    );

    final reasons = <String>{
      if (critical > 0) 'CRITICAL_GAPS_PRESENT',
      if (high > 0) 'HIGH_GAPS_PRESENT',
      if (blindSpots > 0) 'CRITICAL_EVIDENCE_BLIND_SPOTS',
      if (reviewDebt > 0) 'SCHEDULED_REVIEW_DEBT',
      if (minMinutes > available) 'PRIORITY_WORKLOAD_EXCEEDS_CAPACITY',
      'EXAM_PHASE_${phase.name.toUpperCase()}',
    }.toList(growable: false);

    final snapshot = CapacityPressureSnapshot(
      generatedAt: generatedAt ?? capacity.generatedAt,
      phase: phase,
      availableMinutes: available,
      estimatedPriorityWorkloadMinMinutes: minMinutes,
      estimatedPriorityWorkloadMaxMinutes: maxMinutes,
      state: state,
      criticalGapCount: critical,
      highGapCount: high,
      evidenceBlindSpotCount: blindSpots,
      scheduledReviewDebtMinutes: reviewDebt,
      reasonCodes: reasons,
      algorithmVersion: configuration.version,
      schemaVersion: CapacityPressureSnapshot.currentSchemaVersion,
    );
    snapshot.validate();
    return snapshot;
  }

  double _phaseMultiplier(ExamPreparationPhase phase) {
    switch (phase) {
      case ExamPreparationPhase.foundation:
        return 0.90;
      case ExamPreparationPhase.integration:
        return 1.00;
      case ExamPreparationPhase.readiness:
        return 1.10;
      case ExamPreparationPhase.consolidation:
        return 1.00;
    }
  }

  CapacityPressureState _state({
    required int availableMinutes,
    required int workloadMaxMinutes,
  }) {
    if (workloadMaxMinutes <= 0) {
      return CapacityPressureState.low;
    }
    if (availableMinutes <= 0) {
      return CapacityPressureState.critical;
    }

    final ratio = workloadMaxMinutes / availableMinutes;
    if (ratio <= configuration.lowRatioUpperBound) {
      return CapacityPressureState.low;
    }
    if (ratio <= configuration.manageableRatioUpperBound) {
      return CapacityPressureState.manageable;
    }
    if (ratio <= configuration.elevatedRatioUpperBound) {
      return CapacityPressureState.elevated;
    }
    if (ratio <= configuration.highRatioUpperBound) {
      return CapacityPressureState.high;
    }
    return CapacityPressureState.critical;
  }
}
