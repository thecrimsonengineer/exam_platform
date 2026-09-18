import '../models/coverage_projection.dart';
import '../models/readiness_trajectory_point.dart';

class CoverageProjectionService {
  const CoverageProjectionService({
    this.minimumWindowDays = 14,
    this.algorithmVersion = currentAlgorithmVersion,
  });

  static const String currentAlgorithmVersion = 'm7f-coverage-projection-v1';

  final int minimumWindowDays;
  final String algorithmVersion;

  CoverageProjection project({
    required ReadinessTrajectorySummary trajectory,
    required int daysToExam,
  }) {
    final current = trajectory.coverage.endValue;
    final delta = trajectory.coverage.delta;

    if (!trajectory.hasMeaningfulWindow ||
        trajectory.windowDays < minimumWindowDays ||
        current == null ||
        delta == null ||
        daysToExam < 0) {
      return CoverageProjection(
        projectedCoverage: null,
        currentCoverage: current,
        windowDays: trajectory.windowDays,
        daysToExam: daysToExam,
        reasonCodes: const ['COVERAGE_PROJECTION_INSUFFICIENT_HISTORY'],
        algorithmVersion: algorithmVersion,
      );
    }

    final dailyRate = delta / trajectory.windowDays;
    final projected = (current + dailyRate * daysToExam)
        .clamp(0.0, 1.0)
        .toDouble();

    return CoverageProjection(
      projectedCoverage: projected,
      currentCoverage: current,
      windowDays: trajectory.windowDays,
      daysToExam: daysToExam,
      reasonCodes: const [
        'COVERAGE_PROJECTION_RECENT_PACE',
        'PROCESS_VARIABLE_NOT_EXAM_OUTCOME',
      ],
      algorithmVersion: algorithmVersion,
    );
  }
}
