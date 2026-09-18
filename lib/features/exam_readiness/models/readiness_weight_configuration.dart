class ReadinessWeightConfiguration {
  const ReadinessWeightConfiguration({
    this.knowledgeMastery = 0.20,
    this.applicationAbility = 0.20,
    this.retention = 0.15,
    this.blueprintCoverage = 0.15,
    this.difficultyPerformance = 0.10,
    this.competencyBreadth = 0.10,
    this.recentPerformance = 0.05,
    this.confidenceCalibration = 0.05,
    this.version = currentVersion,
  });

  static const String currentVersion = 'm7f-readiness-weights-v1';

  final double knowledgeMastery;
  final double applicationAbility;
  final double retention;
  final double blueprintCoverage;
  final double difficultyPerformance;
  final double competencyBreadth;
  final double recentPerformance;
  final double confidenceCalibration;
  final String version;

  double get total =>
      knowledgeMastery +
      applicationAbility +
      retention +
      blueprintCoverage +
      difficultyPerformance +
      competencyBreadth +
      recentPerformance +
      confidenceCalibration;

  void validate() {
    for (final value in [
      knowledgeMastery,
      applicationAbility,
      retention,
      blueprintCoverage,
      difficultyPerformance,
      competencyBreadth,
      recentPerformance,
      confidenceCalibration,
    ]) {
      if (value < 0 || value > 1) {
        throw StateError('Readiness weights must remain within 0-1.');
      }
    }
    if ((total - 1).abs() > 0.000001) {
      throw StateError('Readiness weights must total 1.0.');
    }
    if (version.trim().isEmpty) {
      throw StateError('Readiness weight configuration must be versioned.');
    }
  }

  Map<String, double> asMap() => {
    'knowledgeMastery': knowledgeMastery,
    'applicationAbility': applicationAbility,
    'retention': retention,
    'blueprintCoverage': blueprintCoverage,
    'difficultyPerformance': difficultyPerformance,
    'competencyBreadth': competencyBreadth,
    'recentPerformance': recentPerformance,
    'confidenceCalibration': confidenceCalibration,
  };
}
