import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/release_governance/artifact_inventory.dart';
import '../../tool/release_governance/checksum_service.dart';
import '../../tool/release_governance/environment_validator.dart';
import '../../tool/release_governance/release_admission.dart';
import '../../tool/release_governance/release_evidence.dart';
import '../../tool/release_governance/release_manifest_builder.dart';
import '../../tool/release_governance/release_recovery.dart';
import '../../tool/release_governance/release_version.dart';
import '../../tool/release_governance/repository_provenance.dart';

void main() {
  group('REL-GOV-11 validation harness', () {
    test(
      'CI supplies format, analyze and complete REL-GOV regression',
      () async {
        final workflow = await File(
          '.github/workflows/rel_gov_validation.yml',
        ).readAsString();

        expect(
          workflow,
          contains(
            'dart format tool/release_governance test/release_governance',
          ),
        );
        expect(
          workflow,
          contains(
            'dart analyze tool/release_governance test/release_governance',
          ),
        );
        expect(workflow, contains('flutter test test/release_governance'));
      },
    );
  });

  group('REL-GOV-11 synthetic internal candidate', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('rel_gov_whole_phase_');
    });

    tearDown(() async {
      if (root.existsSync()) {
        await root.delete(recursive: true);
      }
    });

    test('passes complete governance and evidence re-verification', () async {
      final run = await _generateSyntheticCandidate(root);
      const generator = ReleaseEvidenceGenerator();

      expect(run.inventory.pass, isTrue);
      expect(run.inventory.records, hasLength(1));
      expect(
        run.inventory.records.single.sha256,
        matches(RegExp(r'^[0-9a-f]{64}$')),
      );
      expect(run.admission.admissible, isTrue);
      expect(run.admission.requiredGateCount, 17);
      expect(run.admission.passedGateCount, 17);
      expect(run.admission.blockingFailureCount, 0);
      expect(
        run.admission.gates.any(
          (gate) =>
              gate.gateId == 'RG016' &&
              gate.name == 'release_state' &&
              gate.status == ReleaseAdmissionGateStatus.pass,
        ),
        isTrue,
      );

      final verified = await generator.verify(directory: run.directory);
      expect(verified.pass, isTrue);
      expect(
        verified.evidenceIdentitySha256,
        run.generated.evidenceIdentitySha256,
      );

      final manifest =
          jsonDecode(
                await File(
                  '${run.directory}/release_manifest.json',
                ).readAsString(),
              )
              as Map<String, dynamic>;
      final release = manifest['release']! as Map<String, dynamic>;
      final source = manifest['source']! as Map<String, dynamic>;
      final components = manifest['components']! as Map<String, dynamic>;
      final artifacts = manifest['artifacts']! as List<dynamic>;
      final artifact = artifacts.single as Map<String, dynamic>;

      expect(release['releaseId'], 'csp11-1.0.1-rc.11');
      expect(release['status'], 'candidate');
      expect(source['commitSha'], _commitSha);
      expect(source['treeSha'], _treeSha);
      expect(components.keys, contains('application'));
      expect(artifact['sha256'], run.inventory.records.single.sha256);
      expect(
        Directory(run.directory)
            .listSync()
            .whereType<File>()
            .map((file) => file.uri.pathSegments.last)
            .toSet(),
        ReleaseEvidenceGenerator.packageFileNames.toSet(),
      );

      final review = const ReleaseCandidateReviewPolicy().evaluate(
        intent: ReleaseCandidateReviewIntent.approve,
        admission: run.generated.admission,
        recovery: const ReleaseRecoveryMetadata.none(),
        rationale: 'Synthetic candidate completed whole-phase validation.',
      );

      expect(review.allowed, isTrue);
      expect(review.issues, isEmpty);
    });

    test('blocks tampered evidence after package identity refresh', () async {
      final run = await _generateSyntheticCandidate(root);
      final repositoryFile = File('${run.directory}/repository_evidence.json');
      final repositoryJson =
          jsonDecode(await repositoryFile.readAsString())
              as Map<String, dynamic>;

      repositoryJson['headSha'] = 'ffffffffffffffffffffffffffffffffffffffff';
      await _writeCanonicalJson(repositoryFile, repositoryJson);
      await _refreshSummaryIdentity(run.directory);

      final verified = await const ReleaseEvidenceGenerator().verify(
        directory: run.directory,
      );

      expect(verified.pass, isFalse);
      expect(verified.issues, contains('EVD011_REPOSITORY_EVIDENCE_MISMATCH'));
      expect(
        verified.issues,
        isNot(contains('EVD009_SUMMARY_IDENTITY_MISMATCH')),
      );
    });

    test('blocks approval when a required release gate fails', () {
      final gates = _passingGates();
      gates[8] = gates[8].copyWith(
        status: ReleaseAdmissionGateStatus.fail,
        message: 'Synthetic required test failure.',
      );

      final admission = const ReleaseAdmissionPolicy().evaluate(gates);
      expect(admission.admissible, isFalse);
      expect(admission.blockingFailureCount, greaterThan(0));

      final review = const ReleaseCandidateReviewPolicy().evaluate(
        intent: ReleaseCandidateReviewIntent.approve,
        admission: admission,
        recovery: const ReleaseRecoveryMetadata.none(),
        rationale: 'Attempted synthetic approval.',
      );

      expect(review.allowed, isFalse);
      expect(
        review.issues.map((issue) => issue.code),
        contains('RCR002_APPROVAL_REQUIRES_ADMISSIBLE'),
      );
    });
  });

  group('REL-GOV-11 repository hygiene', () {
    test('does not track generated build artifacts', () async {
      final result = await Process.run('git', const <String>[
        'ls-files',
        'build',
      ]);

      expect(result.exitCode, 0);
      expect((result.stdout as String).trim(), isEmpty);
    });
  });
}

Future<_SyntheticRun> _generateSyntheticCandidate(Directory root) async {
  final artifactFile = File(
    '${root.path}/build/release-candidate/csp11-synthetic.apk',
  );
  await artifactFile.parent.create(recursive: true);
  await artifactFile.writeAsBytes(
    utf8.encode('REL-GOV-11 synthetic internal artifact\n'),
  );

  final inventory = await const ArtifactInventoryService().capture(
    rootDirectory: root.path,
    declarations: const <ArtifactDeclaration>[
      ArtifactDeclaration(
        artifactId: 'synthetic-android-apk',
        fileName: 'build/release-candidate/csp11-synthetic.apk',
      ),
    ],
  );

  final version = ReleaseVersion.parse('1.0.1+2');
  if (!version.isValidSuccessorOf(ReleaseVersion.parse('1.0.0+1'))) {
    throw StateError('Synthetic version is not a valid governed successor.');
  }

  const provenancePolicy = RepositoryProvenancePolicy(
    expectedRepository: 'thecrimsonengineer/exam_platform',
    expectedBranch: 'synthetic/internal-candidate',
    expectedCommitSha: _commitSha,
    expectedTreeSha: _treeSha,
  );
  if (!provenancePolicy.evaluate(_repository).pass) {
    throw StateError('Synthetic repository provenance did not pass.');
  }

  final environmentResult = const BuildEnvironmentValidator().evaluate(
    expected: BuildEnvironmentExpectation.exact(_environment),
    actual: _environment,
  );
  if (!environmentResult.pass) {
    throw StateError('Synthetic build environment did not pass.');
  }

  const recovery = ReleaseRecoveryMetadata.none();
  recovery.validate();

  final gates = _passingGates();
  final admission = const ReleaseAdmissionPolicy().evaluate(gates);
  if (!admission.admissible) {
    throw StateError('Synthetic admission unexpectedly blocked.');
  }

  const components = <ReleaseComponentCheckpoint>[
    ReleaseComponentCheckpoint(
      componentId: 'application',
      status: 'synthetic_internal_candidate',
      checkpoint: 'rel-gov-11-synthetic',
      commitSha: _commitSha,
      version: '1.0.1+2',
      evidence: <Object?>[
        <String, Object?>{
          'kind': 'whole_phase_validation',
          'internalOnly': true,
        },
      ],
    ),
  ];

  final directory = '${root.path}/release-evidence';
  const generator = ReleaseEvidenceGenerator();
  final generated = await generator.generate(
    request: ReleaseEvidenceRequest(
      sourceRef: 'synthetic/internal-candidate',
      version: version,
      candidateOrdinal: 11,
      createdAt: DateTime.utc(2026, 9, 24, 6),
      repository: _repository,
      environment: _environment,
      tests: const <ReleaseTestEvidence>[
        ReleaseTestEvidence(
          suiteId: 'rel-gov-whole-phase',
          status: ReleaseTestStatus.pass,
          evidenceRefs: <String>[
            'test/release_governance/rel_gov_whole_phase_test.dart',
          ],
          message: 'Synthetic internal whole-phase validation passed.',
        ),
      ],
      components: components,
      artifactInventory: inventory,
      admissionGates: gates,
      recovery: recovery.toJson(),
    ),
    outputDirectory: directory,
  );

  return _SyntheticRun(
    directory: directory,
    inventory: inventory,
    admission: admission,
    generated: generated,
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
        'synthetic/evidence/${definition.gateId.toLowerCase()}.json',
      ],
      message: 'Synthetic validation passed ${definition.name}.',
    );
  }).toList();
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

class _SyntheticRun {
  const _SyntheticRun({
    required this.directory,
    required this.inventory,
    required this.admission,
    required this.generated,
  });

  final String directory;
  final ArtifactInventoryResult inventory;
  final ReleaseAdmissionResult admission;
  final ReleaseEvidencePackageResult generated;
}

const String _commitSha = '0123456789abcdef0123456789abcdef01234567';
const String _treeSha = '89abcdef0123456789abcdef0123456789abcdef';

const RepositoryProvenanceEvidence _repository = RepositoryProvenanceEvidence(
  repository: 'thecrimsonengineer/exam_platform',
  remoteUrl: 'https://github.com/thecrimsonengineer/exam_platform.git',
  branch: 'synthetic/internal-candidate',
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
