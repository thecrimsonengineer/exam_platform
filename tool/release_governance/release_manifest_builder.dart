import 'dart:collection';
import 'dart:convert';

import 'release_version.dart';

enum GovernedReleaseStatus {
  development,
  candidate,
  validated,
  frozen,
  released,
  withdrawn,
  superseded,
}

class ReleaseSourceIdentity {
  const ReleaseSourceIdentity({
    required this.repository,
    required this.branch,
    required this.commitSha,
    required this.treeSha,
    required this.clean,
  });

  final String repository;
  final String branch;
  final String commitSha;
  final String treeSha;
  final bool clean;

  Map<String, Object?> toJson() => <String, Object?>{
    'repository': repository,
    'branch': branch,
    'commitSha': commitSha,
    'treeSha': treeSha,
    'clean': clean,
  };
}

class ReleaseComponentCheckpoint {
  const ReleaseComponentCheckpoint({
    required this.componentId,
    required this.status,
    required this.checkpoint,
    this.commitSha,
    this.version,
    this.evidence = const <Object?>[],
  });

  final String componentId;
  final String status;
  final String checkpoint;
  final String? commitSha;
  final String? version;
  final List<Object?> evidence;

  Map<String, Object?> toJson() => <String, Object?>{
    'componentId': componentId,
    'status': status,
    'checkpoint': checkpoint,
    'commitSha': commitSha,
    'version': version,
    'evidence': evidence,
  };
}

class ReleaseValidationSummary {
  const ReleaseValidationSummary({
    required this.requiredGateCount,
    required this.passedGateCount,
    required this.blockingFailureCount,
    this.evidenceRefs = const <String>[],
  });

  const ReleaseValidationSummary.empty()
    : requiredGateCount = 0,
      passedGateCount = 0,
      blockingFailureCount = 0,
      evidenceRefs = const <String>[];

  final int requiredGateCount;
  final int passedGateCount;
  final int blockingFailureCount;
  final List<String> evidenceRefs;

  Map<String, Object?> toJson() => <String, Object?>{
    'requiredGateCount': requiredGateCount,
    'passedGateCount': passedGateCount,
    'blockingFailureCount': blockingFailureCount,
    'evidenceRefs': evidenceRefs,
  };
}

class ReleaseManifestBuilder {
  ReleaseManifestBuilder({
    required this.releaseId,
    required this.version,
    required this.status,
    required this.createdAt,
    required this.source,
    this.environment = const <String, Object?>{},
    this.dependencies = const <String, Object?>{},
    this.components = const <ReleaseComponentCheckpoint>[],
    this.validation = const ReleaseValidationSummary.empty(),
    this.artifacts = const <Map<String, Object?>>[],
    this.recovery = const <String, Object?>{
      'previousStableRelease': null,
      'rollbackEligible': false,
    },
  });

  factory ReleaseManifestBuilder.candidate({
    required ReleaseVersion version,
    required int candidateOrdinal,
    required DateTime createdAt,
    required ReleaseSourceIdentity source,
    Map<String, Object?> environment = const <String, Object?>{},
    Map<String, Object?> dependencies = const <String, Object?>{},
    List<ReleaseComponentCheckpoint> components =
        const <ReleaseComponentCheckpoint>[],
    ReleaseValidationSummary validation =
        const ReleaseValidationSummary.empty(),
    List<Map<String, Object?>> artifacts = const <Map<String, Object?>>[],
    Map<String, Object?> recovery = const <String, Object?>{
      'previousStableRelease': null,
      'rollbackEligible': false,
    },
  }) {
    return ReleaseManifestBuilder(
      releaseId: version.releaseCandidateId(candidateOrdinal),
      version: version,
      status: GovernedReleaseStatus.candidate,
      createdAt: createdAt,
      source: source,
      environment: environment,
      dependencies: dependencies,
      components: components,
      validation: validation,
      artifacts: artifacts,
      recovery: recovery,
    );
  }

  static final RegExp _gitShaPattern = RegExp(r'^[0-9a-f]{40}$');
  static final RegExp _componentIdPattern = RegExp(r'^[A-Za-z][A-Za-z0-9_-]*$');

  final String releaseId;
  final ReleaseVersion version;
  final GovernedReleaseStatus status;
  final DateTime createdAt;
  final ReleaseSourceIdentity source;
  final Map<String, Object?> environment;
  final Map<String, Object?> dependencies;
  final List<ReleaseComponentCheckpoint> components;
  final ReleaseValidationSummary validation;
  final List<Map<String, Object?>> artifacts;
  final Map<String, Object?> recovery;

  Map<String, Object?> build() {
    _validate();

    final componentsById = SplayTreeMap<String, Object?>();
    for (final component in components) {
      componentsById[component.componentId] = component.toJson();
    }

    final manifest = <String, Object?>{
      'schemaVersion': 1,
      'release': <String, Object?>{
        'releaseId': releaseId,
        'versionName': version.versionName,
        'buildNumber': version.buildNumber,
        'status': status.name,
        'createdAt': createdAt.toUtc().toIso8601String(),
      },
      'source': source.toJson(),
      'environment': environment,
      'dependencies': dependencies,
      'components': componentsById,
      'validation': validation.toJson(),
      'artifacts': artifacts,
      'recovery': recovery,
    };

    return _canonicalizeMap(manifest);
  }

  String buildCanonicalJson({bool pretty = false}) {
    final manifest = build();
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(manifest);
    }
    return jsonEncode(manifest);
  }

  void _validate() {
    _requireNonEmpty(releaseId, 'releaseId');
    _requireNonEmpty(source.repository, 'source.repository');
    _requireNonEmpty(source.branch, 'source.branch');
    _requireGitSha(source.commitSha, 'source.commitSha');
    _requireGitSha(source.treeSha, 'source.treeSha');

    final componentIds = <String>{};
    for (final component in components) {
      _requireNonEmpty(component.componentId, 'component.componentId');
      if (!_componentIdPattern.hasMatch(component.componentId)) {
        throw ArgumentError.value(
          component.componentId,
          'component.componentId',
          'Component IDs must match ^[A-Za-z][A-Za-z0-9_-]*\$.',
        );
      }
      if (!componentIds.add(component.componentId)) {
        throw ArgumentError.value(
          component.componentId,
          'components',
          'Duplicate component ID.',
        );
      }
      _requireNonEmpty(component.status, 'component.status');
      _requireNonEmpty(component.checkpoint, 'component.checkpoint');
      if (component.commitSha != null) {
        _requireGitSha(component.commitSha!, 'component.commitSha');
      }
      _validateJsonValue(component.evidence, 'component.evidence');
    }

    if (validation.requiredGateCount < 0 ||
        validation.passedGateCount < 0 ||
        validation.blockingFailureCount < 0) {
      throw ArgumentError('Validation counts must be non-negative.');
    }
    if (validation.passedGateCount > validation.requiredGateCount) {
      throw ArgumentError('passedGateCount may not exceed requiredGateCount.');
    }
    if (validation.passedGateCount > 0 && validation.evidenceRefs.isEmpty) {
      throw ArgumentError(
        'A non-zero passedGateCount requires validation evidence references.',
      );
    }

    final evidenceRefs = <String>{};
    for (final ref in validation.evidenceRefs) {
      _requireNonEmpty(ref, 'validation.evidenceRefs');
      if (!evidenceRefs.add(ref)) {
        throw ArgumentError.value(
          ref,
          'validation.evidenceRefs',
          'Duplicate evidence reference.',
        );
      }
    }

    _validateJsonValue(environment, 'environment');
    _validateJsonValue(dependencies, 'dependencies');
    _validateJsonValue(artifacts, 'artifacts');
    _validateJsonValue(recovery, 'recovery');
  }

  static void _requireNonEmpty(String value, String field) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, field, 'Value must not be empty.');
    }
  }

  static void _requireGitSha(String value, String field) {
    if (!_gitShaPattern.hasMatch(value)) {
      throw ArgumentError.value(
        value,
        field,
        'Expected a lowercase 40-character hexadecimal Git SHA.',
      );
    }
  }

  static Map<String, Object?> _canonicalizeMap(Map<String, Object?> source) {
    final result = SplayTreeMap<String, Object?>();
    for (final entry in source.entries) {
      result[entry.key] = _canonicalizeValue(entry.value);
    }
    return Map<String, Object?>.from(result);
  }

  static Object? _canonicalizeValue(Object? value) {
    _validateJsonValue(value, 'manifest');
    if (value is Map<String, Object?>) {
      return _canonicalizeMap(value);
    }
    if (value is List) {
      return value.map<Object?>((item) => _canonicalizeValue(item)).toList();
    }
    return value;
  }

  static void _validateJsonValue(Object? value, String field) {
    if (value == null || value is String || value is num || value is bool) {
      return;
    }
    if (value is List) {
      for (final item in value) {
        _validateJsonValue(item, field);
      }
      return;
    }
    if (value is Map<String, Object?>) {
      for (final entry in value.entries) {
        if (entry.key.isEmpty) {
          throw ArgumentError.value(
            entry.key,
            field,
            'JSON keys must not be empty.',
          );
        }
        _validateJsonValue(entry.value, field);
      }
      return;
    }
    throw ArgumentError.value(
      value,
      field,
      'Unsupported JSON value type: ${value.runtimeType}.',
    );
  }
}
