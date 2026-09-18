enum ExamPreparationPhase {
  foundation,
  integration,
  readiness,
  consolidation,
}

class PhaseAllocationProfile {
  const PhaseAllocationProfile({
    required this.learning,
    required this.practice,
    required this.review,
    required this.diagnostics,
  });

  final double learning;
  final double practice;
  final double review;
  final double diagnostics;

  double get total => learning + practice + review + diagnostics;

  void validate() {
    for (final value in [learning, practice, review, diagnostics]) {
      if (value < 0 || value > 1) {
        throw StateError('Phase allocation values must remain within 0-1.');
      }
    }
    if ((total - 1).abs() > 0.000001) {
      throw StateError('Phase allocation values must total 1.0.');
    }
  }

  Map<String, dynamic> toJson() => {
        'learning': learning,
        'practice': practice,
        'review': review,
        'diagnostics': diagnostics,
      };

  factory PhaseAllocationProfile.fromJson(Map<String, dynamic> json) {
    return PhaseAllocationProfile(
      learning: _asDouble(json['learning']),
      practice: _asDouble(json['practice']),
      review: _asDouble(json['review']),
      diagnostics: _asDouble(json['diagnostics']),
    );
  }
}

class ExamPreparationPhaseConfiguration {
  const ExamPreparationPhaseConfiguration({
    this.foundationMinimumDays = 61,
    this.integrationMinimumDays = 31,
    this.readinessMinimumDays = 15,
    this.foundationAllocation = const PhaseAllocationProfile(
      learning: 0.55,
      practice: 0.20,
      review: 0.15,
      diagnostics: 0.10,
    ),
    this.integrationAllocation = const PhaseAllocationProfile(
      learning: 0.35,
      practice: 0.35,
      review: 0.20,
      diagnostics: 0.10,
    ),
    this.readinessAllocation = const PhaseAllocationProfile(
      learning: 0.20,
      practice: 0.45,
      review: 0.25,
      diagnostics: 0.10,
    ),
    this.consolidationAllocation = const PhaseAllocationProfile(
      learning: 0.10,
      practice: 0.35,
      review: 0.45,
      diagnostics: 0.10,
    ),
    this.version = currentVersion,
  });

  static const String currentVersion = 'm7f-phase-v1';

  final int foundationMinimumDays;
  final int integrationMinimumDays;
  final int readinessMinimumDays;
  final PhaseAllocationProfile foundationAllocation;
  final PhaseAllocationProfile integrationAllocation;
  final PhaseAllocationProfile readinessAllocation;
  final PhaseAllocationProfile consolidationAllocation;
  final String version;

  void validate() {
    if (foundationMinimumDays <= integrationMinimumDays ||
        integrationMinimumDays <= readinessMinimumDays ||
        readinessMinimumDays <= 0) {
      throw StateError('Exam phase thresholds must descend toward exam day.');
    }
    if (version.trim().isEmpty) {
      throw StateError('Exam phase configuration must be versioned.');
    }
    for (final allocation in [
      foundationAllocation,
      integrationAllocation,
      readinessAllocation,
      consolidationAllocation,
    ]) {
      allocation.validate();
    }
  }

  PhaseAllocationProfile allocationFor(ExamPreparationPhase phase) {
    switch (phase) {
      case ExamPreparationPhase.foundation:
        return foundationAllocation;
      case ExamPreparationPhase.integration:
        return integrationAllocation;
      case ExamPreparationPhase.readiness:
        return readinessAllocation;
      case ExamPreparationPhase.consolidation:
        return consolidationAllocation;
    }
  }
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
