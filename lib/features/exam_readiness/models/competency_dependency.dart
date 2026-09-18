class CompetencyDependency {
  const CompetencyDependency({
    required this.prerequisiteCompetencyId,
    required this.dependentCompetencyId,
    required this.strength,
    required this.rationale,
    required this.source,
    required this.version,
  });

  final String prerequisiteCompetencyId;
  final String dependentCompetencyId;
  final double strength;
  final String rationale;
  final String source;
  final String version;

  void validate() {
    final canonical = RegExp(r'^d\d{2}_c\d{2}$');
    if (!canonical.hasMatch(prerequisiteCompetencyId) ||
        !canonical.hasMatch(dependentCompetencyId)) {
      throw StateError('Dependency competency IDs must be canonical.');
    }
    if (prerequisiteCompetencyId == dependentCompetencyId) {
      throw StateError('A competency cannot depend on itself.');
    }
    if (strength < 0 || strength > 1) {
      throw StateError('Dependency strength must remain within 0-1.');
    }
    if (rationale.trim().isEmpty ||
        source.trim().isEmpty ||
        version.trim().isEmpty) {
      throw StateError(
        'Dependency rationale, source and version are required.',
      );
    }
  }

  Map<String, dynamic> toJson() => {
        'prerequisiteCompetencyId': prerequisiteCompetencyId,
        'dependentCompetencyId': dependentCompetencyId,
        'strength': strength,
        'rationale': rationale,
        'source': source,
        'version': version,
      };

  factory CompetencyDependency.fromJson(Map<String, dynamic> json) {
    return CompetencyDependency(
      prerequisiteCompetencyId:
          json['prerequisiteCompetencyId']?.toString() ?? '',
      dependentCompetencyId:
          json['dependentCompetencyId']?.toString() ?? '',
      strength: _asDouble(json['strength']),
      rationale: json['rationale']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
    );
  }
}

class RootGapCandidate {
  const RootGapCandidate({
    required this.prerequisiteCompetencyId,
    required this.dependentCompetencyIds,
    required this.averageDependencyStrength,
    required this.reasonCodes,
  });

  final String prerequisiteCompetencyId;
  final List<String> dependentCompetencyIds;
  final double averageDependencyStrength;
  final List<String> reasonCodes;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
