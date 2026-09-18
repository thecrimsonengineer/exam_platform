class CoverageProjection {
  const CoverageProjection({
    required this.projectedCoverage,
    required this.currentCoverage,
    required this.windowDays,
    required this.daysToExam,
    required this.reasonCodes,
    required this.algorithmVersion,
  });

  final double? projectedCoverage;
  final double? currentCoverage;
  final int windowDays;
  final int daysToExam;
  final List<String> reasonCodes;
  final String algorithmVersion;

  bool get isAvailable => projectedCoverage != null;

  int? get projectedPercent =>
      projectedCoverage == null ? null : (projectedCoverage! * 100).round();
}
