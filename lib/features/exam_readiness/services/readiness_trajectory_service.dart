import '../models/competency_readiness_profile.dart';
import '../models/evidence_confidence.dart';
import '../models/readiness_trajectory_point.dart';

class ReadinessTrajectoryService {
  const ReadinessTrajectoryService({
    this.minimumTrendWindowDays = 14,
    this.stableDeltaThreshold = 0.03,
    this.algorithmVersion = currentAlgorithmVersion,
  });

  static const String currentAlgorithmVersion = 'm7f-trajectory-v1';

  final int minimumTrendWindowDays;
  final double stableDeltaThreshold;
  final String algorithmVersion;

  ReadinessTrajectoryPoint pointFromDashboard(
    ExamReadinessDashboard dashboard, {
    DateTime? date,
  }) {
    return ReadinessTrajectoryPoint(
      date: date ?? dashboard.generatedAt,
      knowledge: dashboard.knowledgeMastery.value,
      application: dashboard.applicationAbility.value,
      retention: dashboard.retention.value,
      coverage: dashboard.blueprintCoverage.ratio,
      difficulty: dashboard.difficultyPerformance.value,
      evidenceConfidence: dashboard.evidenceConfidence,
      algorithmVersion: algorithmVersion,
    );
  }

  ReadinessTrajectorySummary summarize(
    Iterable<ReadinessTrajectoryPoint> points,
  ) {
    final values = points.toList(growable: false)
      ..sort((left, right) => left.date.compareTo(right.date));

    if (values.length < 2) {
      return _unavailable(values);
    }

    final end = values.last;
    ReadinessTrajectoryPoint? start;
    for (final point in values) {
      final days = DateTime(
        end.date.year,
        end.date.month,
        end.date.day,
      ).difference(
        DateTime(point.date.year, point.date.month, point.date.day),
      ).inDays;
      if (days >= minimumTrendWindowDays) {
        start = point;
        break;
      }
    }

    if (start == null) {
      return _unavailable(values);
    }

    final windowDays = DateTime(
      end.date.year,
      end.date.month,
      end.date.day,
    ).difference(
      DateTime(start.date.year, start.date.month, start.date.day),
    ).inDays;

    return ReadinessTrajectorySummary(
      startDate: start.date,
      endDate: end.date,
      windowDays: windowDays,
      knowledge: _trend(start.knowledge, end.knowledge),
      application: _trend(start.application, end.application),
      retention: _trend(start.retention, end.retention),
      coverage: _trend(start.coverage, end.coverage),
      difficulty: _trend(start.difficulty, end.difficulty),
      latestEvidenceConfidence: end.evidenceConfidence,
      algorithmVersion: algorithmVersion,
    );
  }

  ReadinessTrajectorySummary _unavailable(
    List<ReadinessTrajectoryPoint> values,
  ) {
    final none = const ReadinessDimensionTrend(
      startValue: null,
      endValue: null,
      delta: null,
      direction: ReadinessTrendDirection.unavailable,
    );
    return ReadinessTrajectorySummary(
      startDate: null,
      endDate: null,
      windowDays: 0,
      knowledge: none,
      application: none,
      retention: none,
      coverage: none,
      difficulty: none,
      latestEvidenceConfidence:
          values.isEmpty ? EvidenceConfidence.none : values.last.evidenceConfidence,
      algorithmVersion: algorithmVersion,
    );
  }

  ReadinessDimensionTrend _trend(double? start, double? end) {
    if (start == null || end == null) {
      return ReadinessDimensionTrend(
        startValue: start,
        endValue: end,
        delta: null,
        direction: ReadinessTrendDirection.unavailable,
      );
    }

    final delta = end - start;
    final direction = delta.abs() < stableDeltaThreshold
        ? ReadinessTrendDirection.stable
        : delta > 0
            ? ReadinessTrendDirection.improving
            : ReadinessTrendDirection.declining;

    return ReadinessDimensionTrend(
      startValue: start,
      endValue: end,
      delta: delta,
      direction: direction,
    );
  }
}
