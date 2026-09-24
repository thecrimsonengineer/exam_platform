import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'artifact_inventory.dart';
import 'checksum_service.dart';
import 'environment_validator.dart';
import 'release_admission.dart';
import 'release_manifest_builder.dart';
import 'release_version.dart';
import 'repository_provenance.dart';

enum ReleaseTestStatus {
  pass,
  fail;

  String get wireValue {
    switch (this) {
      case ReleaseTestStatus.pass:
        return 'PASS';
      case ReleaseTestStatus.fail:
        return 'FAIL';
    }
  }
}

class ReleaseTestEvidence {
  const ReleaseTestEvidence({
    required this.suiteId,
    required this.status,
    required this.evidenceRefs,
    required this.message,
  });

  final String suiteId;
  final ReleaseTestStatus status;
  final List<String> evidenceRefs;
  final String message;

  Map<String, Object?> toJson() => <String, Object?>{
    'suiteId': suiteId,
    'status': status.wireValue,
    'evidenceRefs': evidenceRefs,
    'message': message,
  };
}

class ReleaseEvidenceRequest {
  const ReleaseEvidenceRequest({
    required this.sourceRef,
    required this.version,
    required this.candidateOrdinal,
    required this.createdAt,
    required this.repository,
    required this.environment,
    required this.tests,
    required this.components,
    required this.artifactInventory,
    required this.admissionGates,
    this.recovery = const <String, Object?>{
      'previousStableRelease': null,
      'rollbackEligible': false,
    },
  });

  final String sourceRef;
  final ReleaseVersion version;
  final int candidateOrdinal;
  final DateTime createdAt;
  final RepositoryProvenanceEvidence repository;
  final BuildEnvironmentSnapshot environment;
  final List<ReleaseTestEvidence> tests;
  final List<ReleaseComponentCheckpoint> components;
  final ArtifactInventoryResult artifactInventory;
  final List<ReleaseAdmissionGate> admissionGates;
  final Map<String, Object?> recovery;

  factory ReleaseEvidenceRequest.fromJson(Map<String, Object?> json) {
    final repositoryJson = _map(json, 'repository');
    final environmentJson = _map(json, 'environment');
    final artifactInventoryJson = _map(json, 'artifactInventory');

    return ReleaseEvidenceRequest(
      sourceRef: _string(json, 'sourceRef'),
      version: ReleaseVersion.parse(_string(json, 'version')),
      candidateOrdinal: _integer(json, 'candidateOrdinal'),
      createdAt: DateTime.parse(_string(json, 'createdAt')).toUtc(),
      repository: RepositoryProvenanceEvidence(
        repository: _string(repositoryJson, 'repository'),
        remoteUrl: _string(repositoryJson, 'remoteUrl'),
        branch: _nullableString(repositoryJson, 'branch'),
        headSha: _string(repositoryJson, 'headSha'),
        treeSha: _string(repositoryJson, 'treeSha'),
        tagsAtHead: _stringList(repositoryJson, 'tagsAtHead'),
        changes: _list(repositoryJson, 'changes').map((value) {
          final item = _asMap(value, 'repository.changes');
          return RepositoryChange(
            status: _string(item, 'status'),
            path: _string(item, 'path'),
            tracked: _boolean(item, 'tracked'),
          );
        }).toList(),
      ),
      environment: BuildEnvironmentSnapshot(
        flutterVersion: _string(environmentJson, 'flutterVersion'),
        dartVersion: _string(environmentJson, 'dartVersion'),
        javaVersion: _string(environmentJson, 'javaVersion'),
        gradleVersion: _string(environmentJson, 'gradleVersion'),
        androidGradlePluginVersion: _nullableString(
          environmentJson,
          'androidGradlePluginVersion',
        ),
        kotlinVersion: _nullableString(environmentJson, 'kotlinVersion'),
        javaTargetVersion: _nullableString(
          environmentJson,
          'javaTargetVersion',
        ),
        kotlinJvmTarget: _nullableString(environmentJson, 'kotlinJvmTarget'),
        runnerOs: _string(environmentJson, 'runnerOs'),
        runnerOsVersion: _string(environmentJson, 'runnerOsVersion'),
        runnerArchitecture: _string(environmentJson, 'runnerArchitecture'),
        pubspecYamlSha256: _string(environmentJson, 'pubspecYamlSha256'),
        pubspecLockSha256: _string(environmentJson, 'pubspecLockSha256'),
      ),
      tests: _list(json, 'tests').map((value) {
        final item = _asMap(value, 'tests');
        return ReleaseTestEvidence(
          suiteId: _string(item, 'suiteId'),
          status: _testStatus(_string(item, 'status')),
          evidenceRefs: _stringList(item, 'evidenceRefs'),
          message: _string(item, 'message'),
        );
      }).toList(),
      components: _list(json, 'components').map((value) {
        final item = _asMap(value, 'components');
        return ReleaseComponentCheckpoint(
          componentId: _string(item, 'componentId'),
          status: _string(item, 'status'),
          checkpoint: _string(item, 'checkpoint'),
          commitSha: _nullableString(item, 'commitSha'),
          version: _nullableString(item, 'version'),
          evidence: _list(item, 'evidence'),
        );
      }).toList(),
      artifactInventory: ArtifactInventoryResult(
        records: _list(artifactInventoryJson, 'artifacts').map((value) {
          final item = _asMap(value, 'artifactInventory.artifacts');
          return ArtifactRecord(
            artifactId: _string(item, 'artifactId'),
            fileName: _string(item, 'fileName'),
            sizeBytes: _integer(item, 'sizeBytes'),
            sha256: _string(item, 'sha256'),
            required: _boolean(item, 'required'),
          );
        }).toList(),
        issues: _list(artifactInventoryJson, 'issues').map((value) {
          final item = _asMap(value, 'artifactInventory.issues');
          return ArtifactIntegrityIssue(
            code: _string(item, 'code'),
            artifactId: _nullableString(item, 'artifactId'),
            fileName: _nullableString(item, 'fileName'),
            message: _string(item, 'message'),
          );
        }).toList(),
      ),
      admissionGates: _list(json, 'admissionGates').map((value) {
        final item = _asMap(value, 'admissionGates');
        return ReleaseAdmissionGate(
          gateId: _string(item, 'gateId'),
          name: _string(item, 'name'),
          status: _gateStatus(_string(item, 'status')),
          severity: _gateSeverity(_string(item, 'severity')),
          blocking: _boolean(item, 'blocking'),
          evidence: _stringList(item, 'evidence'),
          message: _string(item, 'message'),
        );
      }).toList(),
      recovery: json['recovery'] == null
          ? const <String, Object?>{
              'previousStableRelease': null,
              'rollbackEligible': false,
            }
          : _map(json, 'recovery'),
    );
  }

  static ReleaseTestStatus _testStatus(String value) {
    switch (value) {
      case 'PASS':
        return ReleaseTestStatus.pass;
      case 'FAIL':
        return ReleaseTestStatus.fail;
    }
    throw FormatException('Unknown test status.', value);
  }

  static ReleaseAdmissionGateStatus _gateStatus(String value) {
    switch (value) {
      case 'PASS':
        return ReleaseAdmissionGateStatus.pass;
      case 'FAIL':
        return ReleaseAdmissionGateStatus.fail;
      case 'NOT_APPLICABLE':
        return ReleaseAdmissionGateStatus.notApplicable;
    }
    throw FormatException('Unknown admission gate status.', value);
  }

  static ReleaseAdmissionGateSeverity _gateSeverity(String value) {
    switch (value) {
      case 'INFO':
        return ReleaseAdmissionGateSeverity.info;
      case 'WARNING':
        return ReleaseAdmissionGateSeverity.warning;
      case 'ERROR':
        return ReleaseAdmissionGateSeverity.error;
    }
    throw FormatException('Unknown admission gate severity.', value);
  }
}

class ReleaseEvidencePackageResult {
  const ReleaseEvidencePackageResult({
    required this.outputDirectory,
    required this.evidenceIdentitySha256,
    required this.admission,
    required this.files,
  });

  final String outputDirectory;
  final String evidenceIdentitySha256;
  final ReleaseAdmissionResult admission;
  final List<String> files;
}

class ReleaseEvidenceVerificationResult {
  const ReleaseEvidenceVerificationResult({
    required this.evidenceIdentitySha256,
    required this.issues,
  });

  final String? evidenceIdentitySha256;
  final List<String> issues;

  bool get pass => issues.isEmpty;
}

class ReleaseEvidenceGenerator {
  const ReleaseEvidenceGenerator({
    this.checksumService = const ChecksumService(),
    this.admissionPolicy = const ReleaseAdmissionPolicy(),
  });

  static const List<String> structuredFileNames = <String>[
    'release_manifest.json',
    'repository_evidence.json',
    'version_evidence.json',
    'environment_evidence.json',
    'dependency_evidence.json',
    'test_evidence.json',
    'component_evidence.json',
    'artifact_manifest.json',
    'admission_result.json',
  ];

  static const List<String> packageFileNames = <String>[
    ...structuredFileNames,
    'checksums.sha256',
    'release_summary.txt',
  ];

  final ChecksumService checksumService;
  final ReleaseAdmissionPolicy admissionPolicy;

  Future<ReleaseEvidencePackageResult> generate({
    required ReleaseEvidenceRequest request,
    required String outputDirectory,
  }) async {
    _validateRequest(request);

    final admission = admissionPolicy.evaluate(request.admissionGates);
    final evidenceRefs =
        admission.gates
            .where((gate) => gate.status == ReleaseAdmissionGateStatus.pass)
            .expand((gate) => gate.evidence)
            .toSet()
            .toList()
          ..sort();

    final source = ReleaseSourceIdentity(
      repository: request.repository.repository,
      branch: request.sourceRef,
      commitSha: request.repository.headSha,
      treeSha: request.repository.treeSha,
      clean: request.repository.clean,
    );

    final manifest = ReleaseManifestBuilder.candidate(
      version: request.version,
      candidateOrdinal: request.candidateOrdinal,
      createdAt: request.createdAt,
      source: source,
      environment: request.environment.toJson(),
      dependencies: _dependencyEvidence(request.environment),
      components: request.components,
      validation: ReleaseValidationSummary(
        requiredGateCount: admission.requiredGateCount,
        passedGateCount: admission.passedGateCount,
        blockingFailureCount: admission.blockingFailureCount,
        evidenceRefs: evidenceRefs,
      ),
      artifacts: request.artifactInventory.records
          .map((record) => record.toJson())
          .toList(),
      recovery: request.recovery,
    ).build();

    final structured = <String, Map<String, Object?>>{
      'release_manifest.json': manifest,
      'repository_evidence.json': request.repository.toJson(),
      'version_evidence.json': <String, Object?>{
        'versionName': request.version.versionName,
        'buildNumber': request.version.buildNumber,
        'fullVersion': request.version.fullVersion,
        'releaseId': request.version.releaseCandidateId(
          request.candidateOrdinal,
        ),
      },
      'environment_evidence.json': request.environment.toJson(),
      'dependency_evidence.json': _dependencyEvidence(request.environment),
      'test_evidence.json': _testEvidence(request.tests),
      'component_evidence.json': _componentEvidence(request.components),
      'artifact_manifest.json': request.artifactInventory.toJson(),
      'admission_result.json': admission.toJson(),
    };

    final output = Directory(outputDirectory);
    await output.create(recursive: true);

    final identityParts = <String, String>{};
    for (final fileName in structuredFileNames) {
      final content = _canonicalJson(structured[fileName]!, pretty: true);
      await File(
        _join(output.path, fileName),
      ).writeAsString(content, flush: true);
      identityParts[fileName] = content;
    }

    final checksums = checksumService.renderChecksumFile(
      request.artifactInventory.checksumEntries,
    );
    await File(
      _join(output.path, 'checksums.sha256'),
    ).writeAsString(checksums, flush: true);
    identityParts['checksums.sha256'] = checksums;

    issues.addAll(_semanticConsistencyIssues(decoded));

    final identity = _evidenceIdentity(identityParts);
    final release = manifest['release']! as Map<String, Object?>;
    final summary = _summary(
      releaseId: release['releaseId']! as String,
      fullVersion: request.version.fullVersion,
      repository: request.repository.repository,
      sourceRef: request.sourceRef,
      commitSha: request.repository.headSha,
      decision: admission.decision.wireValue,
      evidenceIdentitySha256: identity,
    );
    await File(
      _join(output.path, 'release_summary.txt'),
    ).writeAsString(summary, flush: true);

    return ReleaseEvidencePackageResult(
      outputDirectory: output.absolute.path,
      evidenceIdentitySha256: identity,
      admission: admission,
      files: List<String>.unmodifiable(packageFileNames),
    );
  }

  Future<ReleaseEvidenceVerificationResult> verify({
    required String directory,
  }) async {
    final issues = <String>[];
    final root = Directory(directory);
    if (!root.existsSync()) {
      return const ReleaseEvidenceVerificationResult(
        evidenceIdentitySha256: null,
        issues: <String>['EVD001_PACKAGE_DIRECTORY_MISSING'],
      );
    }

    final actualNames = await root
        .list(followLinks: false)
        .where((entity) => entity is File)
        .map((entity) => entity.uri.pathSegments.last)
        .toList();
    actualNames.sort();

    final expectedNames = packageFileNames.toList()..sort();
    for (final expected in expectedNames) {
      if (!actualNames.contains(expected)) {
        issues.add('EVD002_REQUIRED_FILE_MISSING:$expected');
      }
    }
    for (final actual in actualNames) {
      if (!expectedNames.contains(actual)) {
        issues.add('EVD003_UNEXPECTED_FILE:$actual');
      }
    }

    if (issues.isNotEmpty) {
      issues.sort();
      return ReleaseEvidenceVerificationResult(
        evidenceIdentitySha256: null,
        issues: List<String>.unmodifiable(issues),
      );
    }

    final identityParts = <String, String>{};
    final decoded = <String, Map<String, Object?>>{};

    for (final fileName in structuredFileNames) {
      final file = File(_join(root.path, fileName));
      final content = await file.readAsString();
      try {
        final value = jsonDecode(content);
        if (value is! Map<String, dynamic>) {
          issues.add('EVD004_STRUCTURED_FILE_NOT_OBJECT:$fileName');
          continue;
        }
        final map = value.map<String, Object?>(
          (key, value) => MapEntry(key, value),
        );
        decoded[fileName] = map;
        final canonical = _canonicalJson(map, pretty: true);
        if (content != canonical) {
          issues.add('EVD005_NON_CANONICAL_JSON:$fileName');
        }
        identityParts[fileName] = content;
      } on FormatException {
        issues.add('EVD006_INVALID_JSON:$fileName');
      }
    }

    final checksumsFile = File(_join(root.path, 'checksums.sha256'));
    final checksums = await checksumsFile.readAsString();
    identityParts['checksums.sha256'] = checksums;

    final artifactManifest = decoded['artifact_manifest.json'];
    if (artifactManifest != null) {
      try {
        final artifacts = _list(artifactManifest, 'artifacts').map((value) {
          final item = _asMap(value, 'artifact_manifest.artifacts');
          return ChecksumEntry(
            fileName: _string(item, 'fileName'),
            sha256: _string(item, 'sha256'),
          );
        });
        final expectedChecksums = checksumService.renderChecksumFile(artifacts);
        if (checksums != expectedChecksums) {
          issues.add('EVD007_ARTIFACT_CHECKSUM_FILE_MISMATCH');
        }
      } on Object {
        issues.add('EVD008_ARTIFACT_MANIFEST_INVALID');
      }
    }

    final identity = _evidenceIdentity(identityParts);
    final summary = await File(
      _join(root.path, 'release_summary.txt'),
    ).readAsString();
    final summaryIdentity = _summaryValue(summary, 'evidenceIdentitySha256');
    if (summaryIdentity != identity) {
      issues.add('EVD009_SUMMARY_IDENTITY_MISMATCH');
    }

    issues.sort();
    return ReleaseEvidenceVerificationResult(
      evidenceIdentitySha256: identity,
      issues: List<String>.unmodifiable(issues),
    );
  }

  static List<String> _semanticConsistencyIssues(
    Map<String, Map<String, Object?>> decoded,
  ) {
    final issues = <String>[];
    final manifest = decoded['release_manifest.json'];
    if (manifest == null) {
      return issues;
    }

    final versionEvidence = decoded['version_evidence.json'];
    if (versionEvidence != null) {
      try {
        final release = _map(manifest, 'release');
        final versionName = _string(release, 'versionName');
        final buildNumber = _integer(release, 'buildNumber');
        final releaseId = _string(release, 'releaseId');

        final evidenceVersionName = _string(
          versionEvidence,
          'versionName',
        );
        final evidenceBuildNumber = _integer(
          versionEvidence,
          'buildNumber',
        );
        final evidenceFullVersion = _string(
          versionEvidence,
          'fullVersion',
        );
        final evidenceReleaseId = _string(
          versionEvidence,
          'releaseId',
        );

        if (evidenceVersionName != versionName ||
            evidenceBuildNumber != buildNumber ||
            evidenceFullVersion != '$versionName+$buildNumber' ||
            evidenceReleaseId != releaseId) {
          issues.add('EVD010_VERSION_EVIDENCE_MISMATCH');
        }
      } on Object {
        issues.add('EVD010_VERSION_EVIDENCE_MISMATCH');
      }
    }

    final repositoryEvidence = decoded['repository_evidence.json'];
    if (repositoryEvidence != null) {
      try {
        final source = _map(manifest, 'source');
        if (_string(repositoryEvidence, 'repository') !=
                _string(source, 'repository') ||
            _string(repositoryEvidence, 'headSha') !=
                _string(source, 'commitSha') ||
            _string(repositoryEvidence, 'treeSha') !=
                _string(source, 'treeSha') ||
            _boolean(repositoryEvidence, 'clean') !=
                _boolean(source, 'clean')) {
          issues.add('EVD011_REPOSITORY_EVIDENCE_MISMATCH');
        }
      } on Object {
        issues.add('EVD011_REPOSITORY_EVIDENCE_MISMATCH');
      }
    }

    return issues;
  }

  void _validateRequest(ReleaseEvidenceRequest request) {
    if (request.sourceRef.trim().isEmpty) {
      throw ArgumentError.value(
        request.sourceRef,
        'sourceRef',
        'Source ref must not be empty.',
      );
    }
    if (request.candidateOrdinal < 1) {
      throw ArgumentError.value(
        request.candidateOrdinal,
        'candidateOrdinal',
        'Candidate ordinal must be at least 1.',
      );
    }

    final suiteIds = <String>{};
    for (final test in request.tests) {
      if (test.suiteId.trim().isEmpty) {
        throw ArgumentError('Test suite ID must not be empty.');
      }
      if (!suiteIds.add(test.suiteId)) {
        throw ArgumentError.value(
          test.suiteId,
          'tests',
          'Duplicate test suite ID.',
        );
      }
      if (test.message.trim().isEmpty) {
        throw ArgumentError('Test evidence message must not be empty.');
      }
      if (test.status == ReleaseTestStatus.pass && test.evidenceRefs.isEmpty) {
        throw ArgumentError(
          'A passed test suite requires at least one evidence reference.',
        );
      }
      final refs = <String>{};
      for (final ref in test.evidenceRefs) {
        if (ref.trim().isEmpty || !refs.add(ref)) {
          throw ArgumentError(
            'Test evidence references must be non-empty and unique.',
          );
        }
      }
    }
  }

  Map<String, Object?> _dependencyEvidence(
    BuildEnvironmentSnapshot environment,
  ) {
    return <String, Object?>{
      'pubspecYamlSha256': environment.pubspecYamlSha256,
      'pubspecLockSha256': environment.pubspecLockSha256,
    };
  }

  Map<String, Object?> _testEvidence(List<ReleaseTestEvidence> tests) {
    final sorted = tests.toList()
      ..sort((left, right) => left.suiteId.compareTo(right.suiteId));
    return <String, Object?>{
      'suiteCount': sorted.length,
      'passedSuiteCount': sorted
          .where((test) => test.status == ReleaseTestStatus.pass)
          .length,
      'failedSuiteCount': sorted
          .where((test) => test.status == ReleaseTestStatus.fail)
          .length,
      'suites': sorted.map((test) => test.toJson()).toList(),
    };
  }

  Map<String, Object?> _componentEvidence(
    List<ReleaseComponentCheckpoint> components,
  ) {
    final sorted = components.toList()
      ..sort((left, right) => left.componentId.compareTo(right.componentId));
    return <String, Object?>{
      'componentCount': sorted.length,
      'components': sorted.map((component) => component.toJson()).toList(),
    };
  }

  String _evidenceIdentity(Map<String, String> parts) {
    final buffer = StringBuffer();
    final names = parts.keys.toList()..sort();
    for (final name in names) {
      buffer
        ..write(name)
        ..write('\u0000')
        ..write(parts[name])
        ..write('\u0000');
    }
    return checksumService.sha256Bytes(utf8.encode(buffer.toString()));
  }

  static String _summary({
    required String releaseId,
    required String fullVersion,
    required String repository,
    required String sourceRef,
    required String commitSha,
    required String decision,
    required String evidenceIdentitySha256,
  }) {
    return 'CSP11 REL-GOV Release Evidence\n'
        'releaseId=$releaseId\n'
        'fullVersion=$fullVersion\n'
        'repository=$repository\n'
        'sourceRef=$sourceRef\n'
        'commitSha=$commitSha\n'
        'decision=$decision\n'
        'evidenceIdentitySha256=$evidenceIdentitySha256\n';
  }

  static String? _summaryValue(String summary, String key) {
    for (final line in const LineSplitter().convert(summary)) {
      if (line.startsWith('$key=')) {
        return line.substring(key.length + 1);
      }
    }
    return null;
  }

  static String _canonicalJson(
    Map<String, Object?> value, {
    required bool pretty,
  }) {
    final canonical = _canonicalizeMap(value);
    final encoder = pretty
        ? const JsonEncoder.withIndent('  ')
        : const JsonEncoder();
    return '${encoder.convert(canonical)}\n';
  }

  static Map<String, Object?> _canonicalizeMap(Map<String, Object?> source) {
    final result = SplayTreeMap<String, Object?>();
    for (final entry in source.entries) {
      result[entry.key] = _canonicalizeValue(entry.value);
    }
    return Map<String, Object?>.from(result);
  }

  static Object? _canonicalizeValue(Object? value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is List) {
      return value.map<Object?>(_canonicalizeValue).toList();
    }
    if (value is Map) {
      final converted = <String, Object?>{};
      for (final entry in value.entries) {
        if (entry.key is! String) {
          throw ArgumentError('Evidence JSON map keys must be strings.');
        }
        converted[entry.key as String] = entry.value;
      }
      return _canonicalizeMap(converted);
    }
    throw ArgumentError(
      'Unsupported evidence JSON value: ${value.runtimeType}.',
    );
  }

  static String _join(String directory, String fileName) {
    return '${Directory(directory).absolute.path}'
        '${Platform.pathSeparator}$fileName';
  }
}

Map<String, Object?> _map(Map<String, Object?> json, String key) {
  return _asMap(json[key], key);
}

Map<String, Object?> _asMap(Object? value, String field) {
  if (value is! Map) {
    throw FormatException('Expected JSON object for $field.');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('Expected string JSON keys for $field.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

List<Object?> _list(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! List) {
    throw FormatException('Expected JSON array for $key.');
  }
  return value.cast<Object?>();
}

String _string(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Expected non-empty string for $key.');
  }
  return value;
}

String? _nullableString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Expected string or null for $key.');
  }
  return value;
}

int _integer(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('Expected integer for $key.');
  }
  return value;
}

bool _boolean(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! bool) {
    throw FormatException('Expected boolean for $key.');
  }
  return value;
}

List<String> _stringList(Map<String, Object?> json, String key) {
  return _list(json, key).map((value) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Expected non-empty string items for $key.');
    }
    return value;
  }).toList();
}
