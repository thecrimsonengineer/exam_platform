import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/release_governance/artifact_inventory.dart';
import '../../tool/release_governance/environment_validator.dart';
import '../../tool/release_governance/release_candidate_input.dart';
import '../../tool/release_governance/release_version.dart';
import '../../tool/release_governance/repository_provenance.dart';

void main() {
  group('ReleaseCandidateEnvironmentPolicy', () {
    test('parses the frozen policy contract', () {
      final policy = ReleaseCandidateEnvironmentPolicy.fromJson(
        <String, Object?>{
          'schemaVersion': 1,
          'expectedRepository': 'thecrimsonengineer/exam_platform',
          'flutterVersion': '3.44.9',
          'dartVersion': '3.12.2',
          'javaVersion': '17.0.16',
          'gradleVersion': '9.1.0',
          'androidGradlePluginVersion': '9.0.1',
          'kotlinVersion': '2.3.20',
          'javaTargetVersion': '17',
          'kotlinJvmTarget': '17',
          'runnerOs': 'linux',
          'runnerArchitecture': 'X64',
        },
      );

      expect(policy.expectedRepository, 'thecrimsonengineer/exam_platform');
      expect(policy.flutterVersion, '3.44.9');
      expect(policy.javaVersion, '17.0.16');
      expect(policy.runnerArchitecture, 'X64');
    });

    test('rejects unknown policy schema versions', () {
      expect(
        () => ReleaseCandidateEnvironmentPolicy.fromJson(
          <String, Object?>{
            'schemaVersion': 2,
            'expectedRepository': 'thecrimsonengineer/exam_platform',
          },
        ),
        throwsFormatException,
      );
    });
  });

  group('ReleaseCandidateInputAssembler', () {
    const assembler = ReleaseCandidateInputAssembler();

    test('assembles a fully admitted typed candidate input', () {
      final json = assembler.assemble(
        policy: _policy,
        sourceRef: 'phase-rel-gov-release-governance',
        expectedCommitSha: _headSha,
        candidateOrdinal: 2,
        createdAt: DateTime.utc(2026, 9, 24, 5, 30),
        version: ReleaseVersion.parse('1.0.0+1'),
        repository: _repository,
        environment: _environment,
        artifactInventory: _inventory,
      );

      expect(json['sourceRef'], 'phase-rel-gov-release-governance');
      expect(json['version'], '1.0.0+1');
      expect(json['candidateOrdinal'], 2);

      final artifacts = json['artifactInventory']! as Map<String, Object?>;
      expect(artifacts['artifactCount'], 1);

      final gates = json['admissionGates']! as List<Object?>;
      expect(gates, hasLength(17));
      expect(
        gates.every(
          (value) =>
              (value! as Map<String, Object?>)['status'] == 'PASS',
        ),
        isTrue,
      );
    });

    test('blocks repository SHA drift', () {
      expect(
        () => assembler.assemble(
          policy: _policy,
          sourceRef: 'release/candidate',
          expectedCommitSha:
              'ffffffffffffffffffffffffffffffffffffffff',
          candidateOrdinal: 1,
          createdAt: DateTime.utc(2026, 9, 24),
          version: ReleaseVersion.parse('1.0.0+1'),
          repository: _repository,
          environment: _environment,
          artifactInventory: _inventory,
        ),
        throwsStateError,
      );
    });

    test('blocks material environment drift', () {
      const drifted = BuildEnvironmentSnapshot(
        flutterVersion: '3.45.0',
        dartVersion: '3.12.2',
        javaVersion: '17.0.16',
        gradleVersion: '9.1.0',
        androidGradlePluginVersion: '9.0.1',
        kotlinVersion: '2.3.20',
        javaTargetVersion: '17',
        kotlinJvmTarget: '17',
        runnerOs: 'linux',
        runnerOsVersion: 'Ubuntu',
        runnerArchitecture: 'X64',
        pubspecYamlSha256:
            'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        pubspecLockSha256:
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
      );

      expect(
        () => assembler.assemble(
          policy: _policy,
          sourceRef: 'release/candidate',
          expectedCommitSha: _headSha,
          candidateOrdinal: 1,
          createdAt: DateTime.utc(2026, 9, 24),
          version: ReleaseVersion.parse('1.0.0+1'),
          repository: _repository,
          environment: drifted,
          artifactInventory: _inventory,
        ),
        throwsStateError,
      );
    });

    test('blocks an empty artifact inventory', () {
      expect(
        () => assembler.assemble(
          policy: _policy,
          sourceRef: 'release/candidate',
          expectedCommitSha: _headSha,
          candidateOrdinal: 1,
          createdAt: DateTime.utc(2026, 9, 24),
          version: ReleaseVersion.parse('1.0.0+1'),
          repository: _repository,
          environment: _environment,
          artifactInventory: const ArtifactInventoryResult(
            records: <ArtifactRecord>[],
            issues: <ArtifactIntegrityIssue>[],
          ),
        ),
        throwsStateError,
      );
    });
  });

  group('candidate artifact parsing', () {
    test('parses governed artifact declarations', () {
      final artifact = parseArtifactDeclaration(
        'android-apk=build/release-candidate/app.apk',
      );

      expect(artifact.artifactId, 'android-apk');
      expect(
        artifact.fileName,
        'build/release-candidate/app.apk',
      );
    });

    test('rejects malformed declarations', () {
      expect(
        () => parseArtifactDeclaration('android-apk'),
        throwsFormatException,
      );
    });
  });

  group('GitHub release-candidate workflow contract', () {
    late String workflow;

    setUpAll(() async {
      workflow = await File(
        '.github/workflows/csp11_release_candidate.yml',
      ).readAsString();
    });

    test('is manual-only and read-only', () {
      expect(workflow, contains('workflow_dispatch:'));
      expect(workflow, isNot(contains('\n  push:')));
      expect(workflow, isNot(contains('\n  pull_request:')));
      expect(workflow, contains('permissions:\n  contents: read'));
      expect(workflow, isNot(contains('contents: write')));
    });

    test('checks out the immutable dispatched SHA', () {
      expect(workflow, contains('uses: actions/checkout@v7'));
      expect(workflow, contains(r'ref: ${{ github.sha }}'));
      expect(workflow, contains('persist-credentials: false'));
    });

    test('pins the release-candidate toolchain', () {
      expect(workflow, contains('uses: actions/setup-java@v4'));
      expect(workflow, contains("java-version: '17.0.16'"));
      expect(workflow, contains('uses: subosito/flutter-action@v2'));
      expect(workflow, contains("flutter-version: '3.44.9'"));
      expect(workflow, contains('flutter pub get --enforce-lockfile'));
    });

    test('runs required release gates and selected builds', () {
      expect(
        workflow,
        contains(
          'dart format --output=none --set-exit-if-changed lib test tool',
        ),
      );
      expect(workflow, contains('flutter analyze'));
      expect(workflow, contains('flutter test test/release_governance'));
      expect(workflow, contains('flutter test 2>&1'));
      expect(workflow, contains('flutter build apk --release'));
      expect(workflow, contains('flutter build web --release'));
      expect(
        workflow,
        contains(
          'dart run tool/release_governance/release_candidate_input.dart',
        ),
      );
      expect(
        workflow,
        contains(
          'dart run tool/release_governance/release_governance.dart generate',
        ),
      );
      expect(
        workflow,
        contains(
          'dart run tool/release_governance/release_governance.dart verify',
        ),
      );
    });

    test('uploads evidence without publishing or deployment', () {
      expect(workflow, contains('uses: actions/upload-artifact@v4'));

      final forbidden = <String>[
        'actions/create-release',
        'softprops/action-gh-release',
        'google-play',
        'playstore',
        'app-store',
        'firebase deploy',
        'firebase hosting',
        'supabase db push',
        'supabase functions deploy',
        'git push',
      ];

      for (final value in forbidden) {
        expect(
          workflow.toLowerCase(),
          isNot(contains(value)),
          reason: value,
        );
      }
    });

    test('the frozen policy file matches the workflow pins', () async {
      final raw = await File(
        'config/release_governance/release_candidate_environment.json',
      ).readAsString();
      final policy = jsonDecode(raw) as Map<String, dynamic>;

      expect(policy['flutterVersion'], '3.44.9');
      expect(policy['javaVersion'], '17.0.16');
      expect(policy['gradleVersion'], '9.1.0');
      expect(policy['androidGradlePluginVersion'], '9.0.1');
      expect(policy['kotlinVersion'], '2.3.20');
      expect(policy['runnerOs'], 'linux');
      expect(policy['runnerArchitecture'], 'X64');
    });
  });
}

const String _headSha = '0123456789abcdef0123456789abcdef01234567';

const ReleaseCandidateEnvironmentPolicy _policy =
    ReleaseCandidateEnvironmentPolicy(
      expectedRepository: 'thecrimsonengineer/exam_platform',
      flutterVersion: '3.44.9',
      dartVersion: '3.12.2',
      javaVersion: '17.0.16',
      gradleVersion: '9.1.0',
      androidGradlePluginVersion: '9.0.1',
      kotlinVersion: '2.3.20',
      javaTargetVersion: '17',
      kotlinJvmTarget: '17',
      runnerOs: 'linux',
      runnerArchitecture: 'X64',
    );

const RepositoryProvenanceEvidence _repository =
    RepositoryProvenanceEvidence(
      repository: 'thecrimsonengineer/exam_platform',
      remoteUrl: 'https://github.com/thecrimsonengineer/exam_platform.git',
      branch: null,
      headSha: _headSha,
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
  runnerOsVersion: 'Ubuntu',
  runnerArchitecture: 'X64',
  pubspecYamlSha256:
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
  pubspecLockSha256:
      'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
);

const ArtifactInventoryResult _inventory = ArtifactInventoryResult(
  records: <ArtifactRecord>[
    ArtifactRecord(
      artifactId: 'android-apk',
      fileName: 'build/release-candidate/app.apk',
      sizeBytes: 10,
      sha256:
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      required: true,
    ),
  ],
  issues: <ArtifactIntegrityIssue>[],
);
