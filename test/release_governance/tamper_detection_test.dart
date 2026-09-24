import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/release_governance/artifact_inventory.dart';
import '../../tool/release_governance/checksum_service.dart';
import '../../tool/release_governance/environment_validator.dart';
import '../../tool/release_governance/release_admission.dart';
import '../../tool/release_governance/release_evidence.dart';
import '../../tool/release_governance/release_manifest_builder.dart';
import '../../tool/release_governance/release_version.dart';
import '../../tool/release_governance/repository_provenance.dart';

void main() {
  group('REL-GOV-10 positive control', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('rel_gov_tamper_positive_');
    });

    tearDown(() async {
      if (root.existsSync()) {
        await root.delete(recursive: true);
      }
    });

    test('exact valid fixture is ADMISSIBLE and self-verifying', () async {
      const generator = ReleaseEvidenceGenerator();
      final generated = await generator.generate(
        request: _request(),
        outputDirectory: '${root.path}/evidence',
      );
      final verified = await generator.verify(
        directory: '${root.path}/evidence',
      );

      expect(generated.admission.admissible, isTrue);
      expect(generated.admission.blockingFailureCount, 0);
      expect(verified.pass, isTrue);
      expect(verified.evidenceIdentitySha256, generated.evidenceIdentitySha256);
    });
  });

  group('REL-GOV-10 package tamper regression', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('rel_gov_tamper_package_');
    });

    tearDown(() async {
      if (root.existsSync()) {
        await root.delete(recursive: true);
      }
    });

    test(
      'blocks version and build mismatch even after identity refresh',
      () async {
        const generator = ReleaseEvidenceGenerator();
        final directory = '${root.path}/version';
        await generator.generate(
          request: _request(),
          outputDirectory: directory,
        );

        final file = File('$directory/version_evidence.json');
        final json =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        json['buildNumber'] = 2;
        json['fullVersion'] = '1.0.0+2';
        await _writeCanonicalJson(file, json);
        await _refreshSummaryIdentity(directory);

        final verified = await generator.verify(directory: directory);

        expect(verified.pass, isFalse);
        expect(verified.issues, contains('EVD010_VERSION_EVIDENCE_MISMATCH'));
        expect(
          verified.issues,
          isNot(contains('EVD009_SUMMARY_IDENTITY_MISMATCH')),
        );
      },
    );

    test('blocks manifest alteration', () async {
      const generator = ReleaseEvidenceGenerator();
      final directory = '${root.path}/manifest-alteration';
      await generator.generate(request: _request(), outputDirectory: directory);

      final file = File('$directory/release_manifest.json');
      final content = await file.readAsString();
      await file.writeAsString(
        content.replaceFirst('csp11-1.0.0-rc.1', 'csp11-9.9.9-rc.9'),
      );

      final verified = await generator.verify(directory: directory);

      expect(verified.pass, isFalse);
      expect(verified.issues, contains('EVD009_SUMMARY_IDENTITY_MISMATCH'));
    });

    test('blocks corrupt manifest JSON', () async {
      const generator = ReleaseEvidenceGenerator();
      final directory = '${root.path}/corrupt-manifest';
      await generator.generate(request: _request(), outputDirectory: directory);

      await File('$directory/release_manifest.json').writeAsString('{not-json');

      final verified = await generator.verify(directory: directory);

      expect(verified.pass, isFalse);
      expect(
        verified.issues,
        contains('EVD006_INVALID_JSON:release_manifest.json'),
      );
    });

    test('blocks checksum mismatch', () async {
      const generator = ReleaseEvidenceGenerator();
      final directory = '${root.path}/checksum';
      await generator.generate(request: _request(), outputDirectory: directory);

      await File('$directory/checksums.sha256').writeAsString(
        'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff'
        '  build/app.apk\n',
      );

      final verified = await generator.verify(directory: directory);

      expect(verified.pass, isFalse);
      expect(
        verified.issues,
        contains('EVD007_ARTIFACT_CHECKSUM_FILE_MISMATCH'),
      );
    });

    test(
      'blocks evidence from another commit after identity refresh',
      () async {
        const generator = ReleaseEvidenceGenerator();
        final directory = '${root.path}/foreign-commit';
        await generator.generate(
          request: _request(),
          outputDirectory: directory,
        );

        final file = File('$directory/repository_evidence.json');
        final json =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        json['headSha'] = 'ffffffffffffffffffffffffffffffffffffffff';
        await _writeCanonicalJson(file, json);
        await _refreshSummaryIdentity(directory);

        final verified = await generator.verify(directory: directory);

        expect(verified.pass, isFalse);
        expect(
          verified.issues,
          contains('EVD011_REPOSITORY_EVIDENCE_MISMATCH'),
        );
        expect(
          verified.issues,
          isNot(contains('EVD009_SUMMARY_IDENTITY_MISMATCH')),
        );
      },
    );
  });

  group('REL-GOV-10 admission tamper regression', () {
    const policy = ReleaseAdmissionPolicy();

    test('blocks missing evidence on a required PASS gate', () {
      final gates = _passingGates();
      gates[0] = gates[0].copyWith(evidence: const <String>[]);

      final result = policy.evaluate(gates);

      expect(result.admissible, isFalse);
      expect(
        result.issues.map((issue) => issue.code),
        contains('RGA008_PASS_EVIDENCE_MISSING'),
      );
    });

    test('blocks failed required test gate', () {
      final gates = _passingGates();
      gates[8] = gates[8].copyWith(
        status: ReleaseAdmissionGateStatus.fail,
        message: 'Required unit test failed.',
      );

      final result = policy.evaluate(gates);

      expect(result.admissible, isFalse);
      expect(
        result.issues.map((issue) => issue.code),
        contains('RGA012_REQUIRED_GATE_FAILED'),
      );
    });

    test('blocks illegal release state transition gate', () {
      final gates = _passingGates();
      gates[15] = gates[15].copyWith(
        status: ReleaseAdmissionGateStatus.fail,
        message: 'Illegal candidate-to-released transition.',
      );

      final result = policy.evaluate(gates);

      expect(gates[15].gateId, 'RG016');
      expect(gates[15].name, 'release_state');
      expect(result.admissible, isFalse);
      expect(
        result.issues.map((issue) => issue.code),
        contains('RGA012_REQUIRED_GATE_FAILED'),
      );
    });
  });

  group('REL-GOV-10 provenance tamper regression', () {
    test('blocks unknown Git SHA', () {
      const evidence = RepositoryProvenanceEvidence(
        repository: 'thecrimsonengineer/exam_platform',
        remoteUrl: 'https://github.com/thecrimsonengineer/exam_platform.git',
        branch: 'release/candidate',
        headSha: 'ffffffffffffffffffffffffffffffffffffffff',
        treeSha: _treeSha,
        tagsAtHead: <String>[],
        changes: <RepositoryChange>[],
      );
      const policy = RepositoryProvenancePolicy(
        expectedRepository: 'thecrimsonengineer/exam_platform',
        expectedCommitSha: _commitSha,
      );

      final result = policy.evaluate(evidence);

      expect(result.pass, isFalse);
      expect(result.blockingFailures, contains('RGP004_COMMIT_MISMATCH'));
    });

    test('blocks dirty governed source', () {
      const evidence = RepositoryProvenanceEvidence(
        repository: 'thecrimsonengineer/exam_platform',
        remoteUrl: 'https://github.com/thecrimsonengineer/exam_platform.git',
        branch: 'release/candidate',
        headSha: _commitSha,
        treeSha: _treeSha,
        tagsAtHead: <String>[],
        changes: <RepositoryChange>[
          RepositoryChange(status: ' M', path: 'lib/main.dart', tracked: true),
        ],
      );
      const policy = RepositoryProvenancePolicy(
        expectedRepository: 'thecrimsonengineer/exam_platform',
      );

      final result = policy.evaluate(evidence);

      expect(result.pass, isFalse);
      expect(result.blockingFailures, contains('RGP002_DIRTY_WORKTREE'));
    });

    test('blocks repository provenance mismatch', () {
      const evidence = RepositoryProvenanceEvidence(
        repository: 'attacker/fork',
        remoteUrl: 'https://github.com/attacker/fork.git',
        branch: 'release/candidate',
        headSha: _commitSha,
        treeSha: _treeSha,
        tagsAtHead: <String>[],
        changes: <RepositoryChange>[],
      );
      const policy = RepositoryProvenancePolicy(
        expectedRepository: 'thecrimsonengineer/exam_platform',
      );

      final result = policy.evaluate(evidence);

      expect(result.pass, isFalse);
      expect(result.blockingFailures, contains('RGP001_REPOSITORY_MISMATCH'));
    });
  });

  group('REL-GOV-10 dependency and environment drift regression', () {
    test('blocks missing dependency lock', () async {
      final root = await Directory.systemTemp.createTemp(
        'rel_gov_missing_lock_',
      );
      addTearDown(() async {
        if (root.existsSync()) {
          await root.delete(recursive: true);
        }
      });

      await Directory(
        '${root.path}/android/gradle/wrapper',
      ).create(recursive: true);
      await Directory('${root.path}/android/app').create(recursive: true);
      await File(
        '${root.path}/android/gradle/wrapper/gradle-wrapper.properties',
      ).writeAsString(
        'distributionUrl=https\\://services.gradle.org/distributions/'
        'gradle-9.1.0-all.zip\n',
      );
      await File('${root.path}/android/settings.gradle.kts').writeAsString(
        'plugins {\n'
        '  id("com.android.application") version "9.0.1" apply false\n'
        '  id("org.jetbrains.kotlin.android") version "2.3.20" apply false\n'
        '}\n',
      );
      await File('${root.path}/android/app/build.gradle.kts').writeAsString(
        'targetCompatibility = JavaVersion.VERSION_17\n'
        'jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17\n',
      );
      await File(
        '${root.path}/pubspec.yaml',
      ).writeAsString('name: synthetic\nversion: 1.0.0+1\n');

      final inspector = BuildEnvironmentInspector(
        commandRunner: _fakeCommandRunner,
      );

      expect(
        () => inspector.inspect(rootDirectory: root.path),
        throwsStateError,
      );
    });

    test('blocks dependency drift', () {
      final expected = BuildEnvironmentExpectation.exact(_environment);
      const actual = BuildEnvironmentSnapshot(
        flutterVersion: '3.44.9',
        dartVersion: '3.12.2',
        javaVersion: '17.0.16',
        gradleVersion: '9.1.0',
        androidGradlePluginVersion: '9.0.1',
        kotlinVersion: '2.3.20',
        javaTargetVersion: '17',
        kotlinJvmTarget: '17',
        runnerOs: 'linux',
        runnerOsVersion: 'Ubuntu 24.04',
        runnerArchitecture: 'X64',
        pubspecYamlSha256:
            'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        pubspecLockSha256:
            'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
      );

      final result = const BuildEnvironmentValidator().evaluate(
        expected: expected,
        actual: actual,
      );

      expect(result.pass, isFalse);
      expect(
        result.issues.map((issue) => issue.code),
        contains('ENV015_PUBSPEC_LOCK_DRIFT'),
      );
    });

    test('blocks environment drift', () {
      final expected = BuildEnvironmentExpectation.exact(_environment);
      const actual = BuildEnvironmentSnapshot(
        flutterVersion: '3.45.0',
        dartVersion: '3.12.2',
        javaVersion: '17.0.16',
        gradleVersion: '9.1.0',
        androidGradlePluginVersion: '9.0.1',
        kotlinVersion: '2.3.20',
        javaTargetVersion: '17',
        kotlinJvmTarget: '17',
        runnerOs: 'linux',
        runnerOsVersion: 'Ubuntu 24.04',
        runnerArchitecture: 'X64',
        pubspecYamlSha256:
            'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        pubspecLockSha256:
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
      );

      final result = const BuildEnvironmentValidator().evaluate(
        expected: expected,
        actual: actual,
      );

      expect(result.pass, isFalse);
      expect(
        result.issues.map((issue) => issue.code),
        contains('ENV001_FLUTTER_VERSION_DRIFT'),
      );
    });
  });

  group('REL-GOV-10 component and artifact tamper regression', () {
    test('blocks malformed component checkpoint', () {
      final builder = ReleaseManifestBuilder.candidate(
        version: ReleaseVersion.parse('1.0.0+1'),
        candidateOrdinal: 1,
        createdAt: DateTime.utc(2026, 9, 24),
        source: _source,
        components: const <ReleaseComponentCheckpoint>[
          ReleaseComponentCheckpoint(
            componentId: 'flashcards',
            status: 'closed',
            checkpoint: '',
          ),
        ],
      );

      expect(builder.build, throwsArgumentError);
    });

    test('blocks artifact alteration', () {
      const expected = <ArtifactRecord>[_artifact];
      const actual = <ArtifactRecord>[
        ArtifactRecord(
          artifactId: 'android-apk',
          fileName: 'build/app.apk',
          sizeBytes: 10,
          sha256:
              'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
          required: true,
        ),
      ];

      final result = const ArtifactIntegrityVerifier().verify(
        expected: expected,
        actual: actual,
      );

      expect(result.pass, isFalse);
      expect(
        result.issues.map((issue) => issue.code),
        contains('AIV011_SHA256_MISMATCH'),
      );
    });

    test('blocks missing required artifact', () {
      final result = const ArtifactIntegrityVerifier().verify(
        expected: const <ArtifactRecord>[_artifact],
        actual: const <ArtifactRecord>[],
      );

      expect(result.pass, isFalse);
      expect(
        result.issues.map((issue) => issue.code),
        contains('AIV007_REQUIRED_ARTIFACT_MISSING'),
      );
    });

    test('blocks duplicate artifact identity', () {
      final result = const ArtifactIntegrityVerifier().verify(
        expected: const <ArtifactRecord>[_artifact],
        actual: const <ArtifactRecord>[_artifact, _artifact],
      );

      expect(result.pass, isFalse);
      expect(
        result.issues.map((issue) => issue.code),
        contains('AIV005_DUPLICATE_ACTUAL_ARTIFACT_ID'),
      );
    });
  });
}

Future<void> _writeCanonicalJson(File file, Map<String, dynamic> json) async {
  await file.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(json)}\n',
    flush: true,
  );
}

Future<void> _refreshSummaryIdentity(String directory) async {
  const checksumService = ChecksumService();
  final parts = <String, String>{};

  for (final fileName in ReleaseEvidenceGenerator.structuredFileNames) {
    parts[fileName] = await File('$directory/$fileName').readAsString();
  }
  parts['checksums.sha256'] = await File(
    '$directory/checksums.sha256',
  ).readAsString();

  final buffer = StringBuffer();
  final names = parts.keys.toList()..sort();
  for (final name in names) {
    buffer
      ..write(name)
      ..write('\u0000')
      ..write(parts[name])
      ..write('\u0000');
  }
  final identity = checksumService.sha256Bytes(utf8.encode(buffer.toString()));

  final summary = File('$directory/release_summary.txt');
  final lines = const LineSplitter().convert(await summary.readAsString());
  final updated = lines
      .map(
        (line) => line.startsWith('evidenceIdentitySha256=')
            ? 'evidenceIdentitySha256=$identity'
            : line,
      )
      .join('\n');
  await summary.writeAsString('$updated\n', flush: true);
}

ReleaseEvidenceRequest _request() {
  return ReleaseEvidenceRequest(
    sourceRef: 'release/candidate',
    version: ReleaseVersion.parse('1.0.0+1'),
    candidateOrdinal: 1,
    createdAt: DateTime.utc(2026, 9, 24, 5),
    repository: _repository,
    environment: _environment,
    tests: const <ReleaseTestEvidence>[
      ReleaseTestEvidence(
        suiteId: 'unit',
        status: ReleaseTestStatus.pass,
        evidenceRefs: <String>['evidence/unit.txt'],
        message: 'Unit tests passed.',
      ),
    ],
    components: const <ReleaseComponentCheckpoint>[
      ReleaseComponentCheckpoint(
        componentId: 'flashcards',
        status: 'closed',
        checkpoint: 'phase-fc-closed',
      ),
    ],
    artifactInventory: const ArtifactInventoryResult(
      records: <ArtifactRecord>[_artifact],
      issues: <ArtifactIntegrityIssue>[],
    ),
    admissionGates: _passingGates(),
    recovery: const <String, Object?>{
      'previousStableRelease': null,
      'previousStableCommit': null,
      'previousStableTree': null,
      'rollbackEligible': false,
    },
  );
}

List<ReleaseAdmissionGate> _passingGates() {
  return ReleaseAdmissionPolicy.canonicalDefinitions.map((definition) {
    return ReleaseAdmissionGate(
      gateId: definition.gateId,
      name: definition.name,
      status: ReleaseAdmissionGateStatus.pass,
      severity: definition.severity,
      blocking: definition.blocking,
      evidence: <String>['evidence/${definition.gateId.toLowerCase()}.json'],
      message: 'Verified ${definition.name}.',
    );
  }).toList();
}

Future<EnvironmentCommandResult> _fakeCommandRunner(
  String executable,
  List<String> arguments,
  String workingDirectory,
) async {
  switch (executable) {
    case 'flutter':
      return const EnvironmentCommandResult(
        exitCode: 0,
        stdout:
            '{"frameworkVersion":"3.44.9",'
            '"dartSdkVersion":"3.12.2"}',
        stderr: '',
      );
    case 'dart':
      return const EnvironmentCommandResult(
        exitCode: 0,
        stdout: '',
        stderr: 'Dart SDK version: 3.12.2 (stable) on "linux_x64"',
      );
    case 'java':
      return const EnvironmentCommandResult(
        exitCode: 0,
        stdout: '',
        stderr: 'openjdk version "17.0.16" 2025-07-15',
      );
    case 'uname':
      return const EnvironmentCommandResult(
        exitCode: 0,
        stdout: 'x86_64\n',
        stderr: '',
      );
  }

  return const EnvironmentCommandResult(
    exitCode: 127,
    stdout: '',
    stderr: 'not found',
  );
}

const String _commitSha = '0123456789abcdef0123456789abcdef01234567';
const String _treeSha = '89abcdef0123456789abcdef0123456789abcdef';

const ReleaseSourceIdentity _source = ReleaseSourceIdentity(
  repository: 'thecrimsonengineer/exam_platform',
  branch: 'release/candidate',
  commitSha: _commitSha,
  treeSha: _treeSha,
  clean: true,
);

const RepositoryProvenanceEvidence _repository = RepositoryProvenanceEvidence(
  repository: 'thecrimsonengineer/exam_platform',
  remoteUrl: 'https://github.com/thecrimsonengineer/exam_platform.git',
  branch: 'release/candidate',
  headSha: _commitSha,
  treeSha: _treeSha,
  tagsAtHead: <String>[],
  changes: <RepositoryChange>[],
);

const BuildEnvironmentSnapshot _environment = BuildEnvironmentSnapshot(
  flutterVersion: '3.44.9',
  dartVersion: '3.12.2',
  javaVersion: '17.0.16',
  gradleVersion: '9.1.0',
  androidGradlePluginVersion: '9.0.1',
  kotlinVersion: '2.3.20',
  javaTargetVersion: '17',
  kotlinJvmTarget: '17',
  runnerOs: 'linux',
  runnerOsVersion: 'Ubuntu 24.04',
  runnerArchitecture: 'X64',
  pubspecYamlSha256:
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
  pubspecLockSha256:
      'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
);

const ArtifactRecord _artifact = ArtifactRecord(
  artifactId: 'android-apk',
  fileName: 'build/app.apk',
  sizeBytes: 10,
  sha256: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  required: true,
);
