import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/release_governance/artifact_inventory.dart';
import '../../tool/release_governance/environment_validator.dart';
import '../../tool/release_governance/release_admission.dart';
import '../../tool/release_governance/release_evidence.dart';
import '../../tool/release_governance/release_governance.dart';
import '../../tool/release_governance/release_manifest_builder.dart';
import '../../tool/release_governance/release_version.dart';
import '../../tool/release_governance/repository_provenance.dart';

void main() {
  group('ReleaseEvidenceGenerator', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('rel_gov_evidence_');
    });

    tearDown(() async {
      if (root.existsSync()) {
        await root.delete(recursive: true);
      }
    });

    test('writes the complete frozen evidence package', () async {
      const generator = ReleaseEvidenceGenerator();
      final result = await generator.generate(
        request: _request(),
        outputDirectory: '${root.path}/first',
      );

      expect(result.admission.admissible, isTrue);
      expect(
        Directory('${root.path}/first')
            .listSync()
            .whereType<File>()
            .map((file) => file.uri.pathSegments.last)
            .toSet(),
        ReleaseEvidenceGenerator.packageFileNames.toSet(),
      );

      final verification = await generator.verify(
        directory: '${root.path}/first',
      );
      expect(verification.pass, isTrue);
      expect(
        verification.evidenceIdentitySha256,
        result.evidenceIdentitySha256,
      );
    });

    test('is byte-stable across output directories', () async {
      const generator = ReleaseEvidenceGenerator();
      final first = await generator.generate(
        request: _request(),
        outputDirectory: '${root.path}/one',
      );
      final second = await generator.generate(
        request: _request(),
        outputDirectory: '${root.path}/two',
      );

      expect(
        second.evidenceIdentitySha256,
        first.evidenceIdentitySha256,
      );

      for (final fileName in ReleaseEvidenceGenerator.packageFileNames) {
        expect(
          await File('${root.path}/two/$fileName').readAsBytes(),
          await File('${root.path}/one/$fileName').readAsBytes(),
          reason: fileName,
        );
      }
    });

    test('sorts tests and components deterministically', () async {
      const generator = ReleaseEvidenceGenerator();
      await generator.generate(
        request: _request(
          tests: <ReleaseTestEvidence>[
            _testEvidence('widget', 'evidence/widget.txt'),
            _testEvidence('unit', 'evidence/unit.txt'),
          ],
          components: const <ReleaseComponentCheckpoint>[
            ReleaseComponentCheckpoint(
              componentId: 'learningTwin',
              status: 'closed',
              checkpoint: 'phase-m-closed',
            ),
            ReleaseComponentCheckpoint(
              componentId: 'flashcards',
              status: 'closed',
              checkpoint: 'phase-fc-closed',
            ),
          ],
        ),
        outputDirectory: '${root.path}/sorted',
      );

      final tests = jsonDecode(
        await File(
          '${root.path}/sorted/test_evidence.json',
        ).readAsString(),
      ) as Map<String, dynamic>;
      final testSuites = tests['suites']! as List<dynamic>;
      expect(
        testSuites
            .map((value) => (value as Map<String, dynamic>)['suiteId'])
            .toList(),
        <String>['unit', 'widget'],
      );

      final components = jsonDecode(
        await File(
          '${root.path}/sorted/component_evidence.json',
        ).readAsString(),
      ) as Map<String, dynamic>;
      final componentList = components['components']! as List<dynamic>;
      expect(
        componentList
            .map(
              (value) =>
                  (value as Map<String, dynamic>)['componentId'],
            )
            .toList(),
        <String>['flashcards', 'learningTwin'],
      );
    });

    test('recomputes admission instead of accepting a declared decision', () async {
      final gates = _passingGates();
      gates[8] = gates[8].copyWith(
        status: ReleaseAdmissionGateStatus.fail,
        message: 'Unit tests failed.',
      );

      const generator = ReleaseEvidenceGenerator();
      final result = await generator.generate(
        request: _request(admissionGates: gates),
        outputDirectory: '${root.path}/blocked',
      );

      expect(result.admission.admissible, isFalse);
      final admission = jsonDecode(
        await File(
          '${root.path}/blocked/admission_result.json',
        ).readAsString(),
      ) as Map<String, dynamic>;
      expect(admission['decision'], 'BLOCKED');
    });

    test('rejects passed test evidence without an evidence reference', () {
      const generator = ReleaseEvidenceGenerator();

      expect(
        () => generator.generate(
          request: _request(
            tests: const <ReleaseTestEvidence>[
              ReleaseTestEvidence(
                suiteId: 'unit',
                status: ReleaseTestStatus.pass,
                evidenceRefs: <String>[],
                message: 'Passed.',
              ),
            ],
          ),
          outputDirectory: '${root.path}/invalid',
        ),
        throwsArgumentError,
      );
    });

    test('verifier detects JSON tampering', () async {
      const generator = ReleaseEvidenceGenerator();
      await generator.generate(
        request: _request(),
        outputDirectory: '${root.path}/tamper-json',
      );

      final file = File(
        '${root.path}/tamper-json/version_evidence.json',
      );
      await file.writeAsString(
        (await file.readAsString()).replaceFirst('1.0.0', '9.9.9'),
      );

      final result = await generator.verify(
        directory: '${root.path}/tamper-json',
      );

      expect(result.pass, isFalse);
      expect(
        result.issues,
        contains('EVD009_SUMMARY_IDENTITY_MISMATCH'),
      );
    });

    test('verifier detects checksum manifest tampering', () async {
      const generator = ReleaseEvidenceGenerator();
      await generator.generate(
        request: _request(),
        outputDirectory: '${root.path}/tamper-checksum',
      );

      final checksumFile = File(
        '${root.path}/tamper-checksum/checksums.sha256',
      );
      await checksumFile.writeAsString(
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
        '  build/app.apk\n',
      );

      final result = await generator.verify(
        directory: '${root.path}/tamper-checksum',
      );

      expect(result.pass, isFalse);
      expect(
        result.issues,
        contains('EVD007_ARTIFACT_CHECKSUM_FILE_MISMATCH'),
      );
      expect(
        result.issues,
        contains('EVD009_SUMMARY_IDENTITY_MISMATCH'),
      );
    });

    test('verifier detects missing and unexpected files', () async {
      const generator = ReleaseEvidenceGenerator();
      await generator.generate(
        request: _request(),
        outputDirectory: '${root.path}/shape',
      );

      await File(
        '${root.path}/shape/test_evidence.json',
      ).delete();
      await File(
        '${root.path}/shape/rogue.txt',
      ).writeAsString('rogue');

      final result = await generator.verify(
        directory: '${root.path}/shape',
      );

      expect(
        result.issues,
        contains('EVD002_REQUIRED_FILE_MISSING:test_evidence.json'),
      );
      expect(
        result.issues,
        contains('EVD003_UNEXPECTED_FILE:rogue.txt'),
      );
    });
  });

  group('ReleaseEvidenceRequest JSON contract', () {
    test('round-trips normalized CLI input into typed evidence', () {
      final request = ReleaseEvidenceRequest.fromJson(_requestJson());

      expect(request.sourceRef, 'release/candidate');
      expect(request.version.fullVersion, '1.0.0+1');
      expect(request.repository.repository, 'thecrimsonengineer/exam_platform');
      expect(request.environment.flutterVersion, '3.44.9');
      expect(request.artifactInventory.records.single.artifactId, 'android-apk');
      expect(request.admissionGates, hasLength(17));
    });

    test('rejects unknown admission vocabulary', () {
      final json = _requestJson();
      final gates = json['admissionGates']! as List<Object?>;
      final first = Map<String, Object?>.from(
        gates.first! as Map<String, Object?>,
      );
      first['status'] = 'MAYBE';
      gates[0] = first;

      expect(
        () => ReleaseEvidenceRequest.fromJson(json),
        throwsFormatException,
      );
    });
  });

  group('REL-GOV evidence CLI', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('rel_gov_cli_');
    });

    tearDown(() async {
      if (root.existsSync()) {
        await root.delete(recursive: true);
      }
    });

    test('generate creates and self-verifies the package', () async {
      final input = File('${root.path}/input.json');
      await input.writeAsString(jsonEncode(_requestJson()));
      final output = <String>[];
      final errors = <String>[];

      final code = await runReleaseGovernanceCli(
        <String>[
          'generate',
          '--input',
          input.path,
          '--output',
          '${root.path}/evidence',
        ],
        out: output.add,
        err: errors.add,
      );

      expect(code, 0);
      expect(errors, isEmpty);
      expect(output, contains('releaseEvidence=PASS'));
      expect(output, contains('decision=ADMISSIBLE'));
    });

    test('verify rejects a tampered package', () async {
      const generator = ReleaseEvidenceGenerator();
      await generator.generate(
        request: _request(),
        outputDirectory: '${root.path}/evidence',
      );
      await File(
        '${root.path}/evidence/release_summary.txt',
      ).writeAsString('tampered\n');

      final output = <String>[];
      final errors = <String>[];
      final code = await runReleaseGovernanceCli(
        <String>[
          'verify',
          '--directory',
          '${root.path}/evidence',
        ],
        out: output.add,
        err: errors.add,
      );

      expect(code, 2);
      expect(output, isEmpty);
      expect(errors.single, contains('releaseEvidence=FAIL'));
    });

    test('returns usage error for unknown commands', () async {
      final errors = <String>[];

      final code = await runReleaseGovernanceCli(
        const <String>['launch'],
        out: (_) {},
        err: errors.add,
      );

      expect(code, 64);
      expect(errors.first, contains('Unknown REL-GOV command'));
    });
  });
}

ReleaseEvidenceRequest _request({
  List<ReleaseTestEvidence>? tests,
  List<ReleaseComponentCheckpoint>? components,
  List<ReleaseAdmissionGate>? admissionGates,
}) {
  return ReleaseEvidenceRequest(
    sourceRef: 'release/candidate',
    version: ReleaseVersion.parse('1.0.0+1'),
    candidateOrdinal: 1,
    createdAt: DateTime.utc(2026, 9, 24, 5),
    repository: _repository,
    environment: _environment,
    tests: tests ?? <ReleaseTestEvidence>[
      _testEvidence('unit', 'evidence/unit.txt'),
      _testEvidence('widget', 'evidence/widget.txt'),
    ],
    components: components ?? const <ReleaseComponentCheckpoint>[
      ReleaseComponentCheckpoint(
        componentId: 'flashcards',
        status: 'closed',
        checkpoint: 'phase-fc-closed',
      ),
    ],
    artifactInventory: const ArtifactInventoryResult(
      records: <ArtifactRecord>[
        ArtifactRecord(
          artifactId: 'android-apk',
          fileName: 'build/app.apk',
          sizeBytes: 10,
          sha256:
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          required: true,
        ),
      ],
      issues: <ArtifactIntegrityIssue>[],
    ),
    admissionGates: admissionGates ?? _passingGates(),
  );
}

ReleaseTestEvidence _testEvidence(String suiteId, String evidenceRef) {
  return ReleaseTestEvidence(
    suiteId: suiteId,
    status: ReleaseTestStatus.pass,
    evidenceRefs: <String>[evidenceRef],
    message: 'Suite passed.',
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
      evidence: <String>[
        'evidence/${definition.gateId.toLowerCase()}.json',
      ],
      message: 'Verified ${definition.name}.',
    );
  }).toList();
}

Map<String, Object?> _requestJson() {
  return <String, Object?>{
    'sourceRef': 'release/candidate',
    'version': '1.0.0+1',
    'candidateOrdinal': 1,
    'createdAt': '2026-09-24T05:00:00.000Z',
    'repository': _repository.toJson(),
    'environment': _environment.toJson(),
    'tests': <Object?>[
      _testEvidence('unit', 'evidence/unit.txt').toJson(),
    ],
    'components': <Object?>[
      const ReleaseComponentCheckpoint(
        componentId: 'flashcards',
        status: 'closed',
        checkpoint: 'phase-fc-closed',
      ).toJson(),
    ],
    'artifactInventory': const ArtifactInventoryResult(
      records: <ArtifactRecord>[
        ArtifactRecord(
          artifactId: 'android-apk',
          fileName: 'build/app.apk',
          sizeBytes: 10,
          sha256:
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          required: true,
        ),
      ],
      issues: <ArtifactIntegrityIssue>[],
    ).toJson(),
    'admissionGates': _passingGates()
        .map((gate) => gate.toJson())
        .toList(),
    'recovery': <String, Object?>{
      'previousStableRelease': null,
      'rollbackEligible': false,
    },
  };
}

const RepositoryProvenanceEvidence _repository =
    RepositoryProvenanceEvidence(
      repository: 'thecrimsonengineer/exam_platform',
      remoteUrl: 'https://github.com/thecrimsonengineer/exam_platform.git',
      branch: 'release/candidate',
      headSha: '0123456789abcdef0123456789abcdef01234567',
      treeSha: '89abcdef0123456789abcdef0123456789abcdef',
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
