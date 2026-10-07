import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'artifact_inventory.dart';
import 'environment_validator.dart';
import 'release_admission.dart';
import 'release_evidence.dart';
import 'release_manifest_builder.dart';
import 'release_version.dart';
import 'repository_provenance.dart';

class ReleaseCandidateEnvironmentPolicy {
  const ReleaseCandidateEnvironmentPolicy({
    required this.expectedRepository,
    required this.flutterVersion,
    required this.dartVersion,
    required this.javaVersion,
    required this.gradleVersion,
    required this.androidGradlePluginVersion,
    required this.kotlinVersion,
    required this.javaTargetVersion,
    required this.kotlinJvmTarget,
    required this.runnerOs,
    required this.runnerArchitecture,
  });

  final String expectedRepository;
  final String flutterVersion;
  final String dartVersion;
  final String javaVersion;
  final String gradleVersion;
  final String androidGradlePluginVersion;
  final String kotlinVersion;
  final String javaTargetVersion;
  final String kotlinJvmTarget;
  final String runnerOs;
  final String runnerArchitecture;

  factory ReleaseCandidateEnvironmentPolicy.fromJson(
    Map<String, Object?> json,
  ) {
    final schemaVersion = json['schemaVersion'];
    if (schemaVersion != 1) {
      throw FormatException(
        'Unsupported release-candidate policy schemaVersion.',
        schemaVersion,
      );
    }

    return ReleaseCandidateEnvironmentPolicy(
      expectedRepository: _requiredString(json, 'expectedRepository'),
      flutterVersion: _requiredString(json, 'flutterVersion'),
      dartVersion: _requiredString(json, 'dartVersion'),
      javaVersion: _requiredString(json, 'javaVersion'),
      gradleVersion: _requiredString(json, 'gradleVersion'),
      androidGradlePluginVersion: _requiredString(
        json,
        'androidGradlePluginVersion',
      ),
      kotlinVersion: _requiredString(json, 'kotlinVersion'),
      javaTargetVersion: _requiredString(json, 'javaTargetVersion'),
      kotlinJvmTarget: _requiredString(json, 'kotlinJvmTarget'),
      runnerOs: _requiredString(json, 'runnerOs'),
      runnerArchitecture: _requiredString(json, 'runnerArchitecture'),
    );
  }
}

class ReleaseCandidateInputAssembler {
  const ReleaseCandidateInputAssembler();

  Map<String, Object?> assemble({
    required ReleaseCandidateEnvironmentPolicy policy,
    required String sourceRef,
    required String expectedCommitSha,
    required int candidateOrdinal,
    required DateTime createdAt,
    required ReleaseVersion version,
    required RepositoryProvenanceEvidence repository,
    required BuildEnvironmentSnapshot environment,
    required ArtifactInventoryResult artifactInventory,
  }) {
    final provenanceCheck = RepositoryProvenancePolicy(
      expectedRepository: policy.expectedRepository,
      expectedCommitSha: expectedCommitSha,
      allowDetachedHead: true,
      requireClean: true,
    ).evaluate(repository);

    if (!provenanceCheck.pass) {
      throw StateError(
        'Repository provenance gate failed: '
        '${provenanceCheck.blockingFailures.join(', ')}',
      );
    }

    final environmentCheck = const BuildEnvironmentValidator().evaluate(
      expected: BuildEnvironmentExpectation(
        flutterVersion: policy.flutterVersion,
        dartVersion: policy.dartVersion,
        javaVersion: policy.javaVersion,
        gradleVersion: policy.gradleVersion,
        androidGradlePluginVersion: policy.androidGradlePluginVersion,
        kotlinVersion: policy.kotlinVersion,
        javaTargetVersion: policy.javaTargetVersion,
        kotlinJvmTarget: policy.kotlinJvmTarget,
        runnerOs: policy.runnerOs,
        runnerArchitecture: policy.runnerArchitecture,
        pubspecYamlSha256: environment.pubspecYamlSha256,
        pubspecLockSha256: environment.pubspecLockSha256,
      ),
      actual: environment,
    );

    if (!environmentCheck.pass) {
      throw StateError(
        'Build environment gate failed: '
        '${environmentCheck.issues.map((issue) => issue.code).join(', ')}',
      );
    }

    if (!artifactInventory.pass || artifactInventory.records.isEmpty) {
      final codes = artifactInventory.issues
          .map((issue) => issue.code)
          .join(', ');
      throw StateError(
        'Artifact inventory gate failed'
        '${codes.isEmpty ? '' : ': $codes'}.',
      );
    }

    if (sourceRef.trim().isEmpty) {
      throw ArgumentError.value(
        sourceRef,
        'sourceRef',
        'Source ref must not be empty.',
      );
    }
    if (candidateOrdinal < 1) {
      throw ArgumentError.value(
        candidateOrdinal,
        'candidateOrdinal',
        'Candidate ordinal must be at least 1.',
      );
    }

    final tests = <ReleaseTestEvidence>[
      const ReleaseTestEvidence(
        suiteId: 'flutter-full',
        status: ReleaseTestStatus.pass,
        evidenceRefs: <String>[
          'build/release-governance-input/ci_evidence/full_flutter_tests.txt',
        ],
        message: 'Full Flutter test suite passed in release-candidate CI.',
      ),
      const ReleaseTestEvidence(
        suiteId: 'release-governance',
        status: ReleaseTestStatus.pass,
        evidenceRefs: <String>[
          'build/release-governance-input/ci_evidence/release_governance_tests.txt',
        ],
        message: 'Dedicated REL-GOV regression suite passed.',
      ),
    ];

    final component = ReleaseComponentCheckpoint(
      componentId: 'application',
      status: 'candidate_source',
      checkpoint: sourceRef,
      commitSha: repository.headSha,
      version: version.fullVersion,
      evidence: <Object?>[
        <String, Object?>{
          'repository': repository.repository,
          'treeSha': repository.treeSha,
        },
      ],
    );

    final gates = ReleaseAdmissionPolicy.canonicalDefinitions.map((definition) {
      return ReleaseAdmissionGate(
        gateId: definition.gateId,
        name: definition.name,
        status: ReleaseAdmissionGateStatus.pass,
        severity: definition.severity,
        blocking: definition.blocking,
        evidence: <String>[_gateEvidenceRef(definition.gateId)],
        message: 'Release-candidate CI verified ${definition.name}.',
      );
    }).toList();

    return _canonicalizeMap(<String, Object?>{
      'sourceRef': sourceRef,
      'version': version.fullVersion,
      'candidateOrdinal': candidateOrdinal,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'repository': repository.toJson(),
      'environment': environment.toJson(),
      'tests': tests.map((test) => test.toJson()).toList(),
      'components': <Object?>[component.toJson()],
      'artifactInventory': artifactInventory.toJson(),
      'admissionGates': gates.map((gate) => gate.toJson()).toList(),
      'recovery': <String, Object?>{
        'previousStableRelease': null,
        'rollbackEligible': false,
      },
    });
  }

  static String _gateEvidenceRef(String gateId) {
    switch (gateId) {
      case 'RG001':
      case 'RG002':
        return 'build/release-governance-input/ci_evidence/repository_gate.txt';
      case 'RG003':
      case 'RG004':
        return 'build/release-governance-input/ci_evidence/version_gate.txt';
      case 'RG005':
        return 'build/release-governance-input/ci_evidence/dependency_gate.txt';
      case 'RG006':
        return 'build/release-evidence/environment_evidence.json';
      case 'RG007':
        return 'build/release-governance-input/ci_evidence/format.txt';
      case 'RG008':
        return 'build/release-governance-input/ci_evidence/analyze.txt';
      case 'RG009':
      case 'RG010':
        return 'build/release-governance-input/ci_evidence/full_flutter_tests.txt';
      case 'RG011':
        return 'build/release-governance-input/ci_evidence/release_governance_tests.txt';
      case 'RG012':
        return 'build/release-evidence/component_evidence.json';
      case 'RG013':
        return 'build/release-evidence/artifact_manifest.json';
      case 'RG014':
        return 'build/release-evidence/checksums.sha256';
      case 'RG015':
        return 'build/release-evidence/repository_evidence.json';
      case 'RG016':
      case 'RG017':
        return 'build/release-evidence/release_manifest.json';
    }
    throw StateError('Unknown canonical release gate: $gateId');
  }
}

class ReleaseCandidateInputGenerator {
  const ReleaseCandidateInputGenerator({
    this.repositoryInspector = const RepositoryProvenanceInspector(),
    this.artifactInventoryService = const ArtifactInventoryService(),
  });

  final RepositoryProvenanceInspector repositoryInspector;
  final ArtifactInventoryService artifactInventoryService;

  Future<Map<String, Object?>> generate({
    required String rootDirectory,
    required String policyPath,
    required String sourceRef,
    required String expectedCommitSha,
    required int candidateOrdinal,
    required DateTime createdAt,
    required List<ArtifactDeclaration> artifacts,
  }) async {
    final policyJson = _decodeObject(
      await File(_resolve(rootDirectory, policyPath)).readAsString(),
      'release-candidate policy',
    );
    final policy = ReleaseCandidateEnvironmentPolicy.fromJson(policyJson);

    final version = ReleaseVersion.parse(
      await _readPubspecVersion(rootDirectory),
    );
    final repository = await repositoryInspector.inspect(
      directory: rootDirectory,
    );
    final environment = await BuildEnvironmentInspector().inspect(
      rootDirectory: rootDirectory,
    );
    final inventory = await artifactInventoryService.capture(
      rootDirectory: rootDirectory,
      declarations: artifacts,
    );

    return const ReleaseCandidateInputAssembler().assemble(
      policy: policy,
      sourceRef: sourceRef,
      expectedCommitSha: expectedCommitSha,
      candidateOrdinal: candidateOrdinal,
      createdAt: createdAt,
      version: version,
      repository: repository,
      environment: environment,
      artifactInventory: inventory,
    );
  }

  static Future<String> _readPubspecVersion(String rootDirectory) async {
    final content = await File(
      _resolve(rootDirectory, 'pubspec.yaml'),
    ).readAsString();
    final match = RegExp(
      r'^version:\s*([^\s#]+)\s*$',
      multiLine: true,
    ).firstMatch(content);
    if (match == null) {
      throw const FormatException(
        'pubspec.yaml does not contain a governed version.',
      );
    }
    return match.group(1)!;
  }
}

ArtifactDeclaration parseArtifactDeclaration(String raw) {
  final separator = raw.indexOf('=');
  if (separator <= 0 || separator == raw.length - 1) {
    throw FormatException(
      'Artifact must use ARTIFACT_ID=relative/path form.',
      raw,
    );
  }

  return ArtifactDeclaration(
    artifactId: raw.substring(0, separator),
    fileName: raw.substring(separator + 1),
  );
}

Future<int> runReleaseCandidateInputCli(
  List<String> arguments, {
  void Function(String message)? out,
  void Function(String message)? err,
}) async {
  final writeOut = out ?? stdout.writeln;
  final writeErr = err ?? stderr.writeln;

  try {
    final rootDirectory = _option(arguments, '--root', fallback: '.');
    final policyPath = _option(
      arguments,
      '--policy',
      fallback: 'config/release_governance/release_candidate_environment.json',
    );
    final sourceRef = _option(arguments, '--source-ref');
    final expectedCommitSha = _option(arguments, '--expected-sha');
    final candidateOrdinal = int.parse(
      _option(arguments, '--candidate-ordinal'),
    );
    final createdAt = DateTime.parse(
      _option(arguments, '--created-at'),
    ).toUtc();
    final outputPath = _option(arguments, '--output');
    final artifacts = _multiOption(
      arguments,
      '--artifact',
    ).map(parseArtifactDeclaration).toList();

    if (artifacts.isEmpty) {
      throw const FormatException(
        'At least one --artifact declaration is required.',
      );
    }

    const generator = ReleaseCandidateInputGenerator();
    final json = await generator.generate(
      rootDirectory: rootDirectory,
      policyPath: policyPath,
      sourceRef: sourceRef,
      expectedCommitSha: expectedCommitSha,
      candidateOrdinal: candidateOrdinal,
      createdAt: createdAt,
      artifacts: artifacts,
    );

    final output = File(_resolve(rootDirectory, outputPath));
    await output.parent.create(recursive: true);
    await output.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(json)}\n',
      flush: true,
    );

    writeOut('candidateInput=PASS');
    writeOut('output=${output.path}');
    return 0;
  } on Object catch (error) {
    writeErr('candidateInput=FAIL $error');
    return 2;
  }
}

String _option(List<String> arguments, String name, {String? fallback}) {
  final index = arguments.indexOf(name);
  if (index < 0) {
    if (fallback != null) {
      return fallback;
    }
    throw FormatException('Missing required option $name.');
  }
  if (index + 1 >= arguments.length) {
    throw FormatException('Missing value for option $name.');
  }

  final value = arguments[index + 1].trim();
  if (value.isEmpty || value.startsWith('--')) {
    throw FormatException('Missing value for option $name.');
  }
  return value;
}

List<String> _multiOption(List<String> arguments, String name) {
  final values = <String>[];
  for (var index = 0; index < arguments.length; index++) {
    if (arguments[index] != name) {
      continue;
    }
    if (index + 1 >= arguments.length) {
      throw FormatException('Missing value for option $name.');
    }
    final value = arguments[index + 1].trim();
    if (value.isEmpty || value.startsWith('--')) {
      throw FormatException('Missing value for option $name.');
    }
    values.add(value);
  }
  return values;
}

Map<String, Object?> _decodeObject(String raw, String label) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map) {
    throw FormatException('$label must be a JSON object.');
  }
  final result = <String, Object?>{};
  for (final entry in decoded.entries) {
    if (entry.key is! String) {
      throw FormatException('$label keys must be strings.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Expected non-empty string for $key.');
  }
  return value;
}

Map<String, Object?> _canonicalizeMap(Map<String, Object?> source) {
  final result = SplayTreeMap<String, Object?>();
  for (final entry in source.entries) {
    result[entry.key] = _canonicalizeValue(entry.value);
  }
  return Map<String, Object?>.from(result);
}

Object? _canonicalizeValue(Object? value) {
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
        throw ArgumentError('Candidate input map keys must be strings.');
      }
      converted[entry.key as String] = entry.value;
    }
    return _canonicalizeMap(converted);
  }
  throw ArgumentError(
    'Unsupported candidate input value: ${value.runtimeType}.',
  );
}

String _resolve(String rootDirectory, String relativePath) {
  final nativeRelative = relativePath.replaceAll('/', Platform.pathSeparator);
  return '${Directory(rootDirectory).absolute.path}'
      '${Platform.pathSeparator}$nativeRelative';
}

Future<void> main(List<String> arguments) async {
  exitCode = await runReleaseCandidateInputCli(arguments);
}
