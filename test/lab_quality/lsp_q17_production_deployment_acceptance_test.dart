import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/lab/lab_dqg300_evidence_store.dart';
import 'package:exam_platform/features/lab/lab_learner_catalogue.dart';
import 'package:exam_platform/features/lab/lab_learner_presentation.dart';
import 'package:exam_platform/features/lab/lab_production_deployment_acceptance.dart';
import 'package:exam_platform/features/lab/lab_production_population_seed.dart';
import 'package:exam_platform/features/lab/lab_production_release_closure.dart';
import 'package:exam_platform/features/lab/lab_production_release_operator.dart';
import 'package:exam_platform/features/lab/lab_runtime_binding.dart';
import 'package:exam_platform/features/lab/lab_scenario_population_manifest.dart';
import 'package:exam_platform/features/lab/lab_studio.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _readObject(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! Map) {
    throw StateError('Expected JSON object at ' + path + '.');
  }
  return decoded.cast<String, Object?>();
}

class _FilePopulationSource implements LabProductionPopulationSource {
  @override
  Future<LabScenarioPopulationManifest> loadManifest() async {
    return LabScenarioPopulationManifest.fromJson(
      _readObject('content/lab_population/manifest.json'),
    );
  }

  @override
  Future<List<LabProductionPopulationSeedCandidate>> loadCandidates(
    LabScenarioPopulationManifest manifest,
  ) async {
    return manifest.entries.map((entry) {
      return LabProductionPopulationSeedCandidate(
        entryId: entry.entryId,
        technicalRoot: _readObject(entry.technicalLabPath),
        dqg300Evidence: const LabDqg300EvidenceCodec().decode(
          File(entry.dqg300EvidencePath).readAsStringSync(),
        ),
        presentationPackage: LabLearnerPresentationPackage.fromJson(
          _readObject(entry.learnerPresentationPath),
        ),
      );
    }).toList();
  }
}

class _FakeReleaseOperator implements LabProductionReleaseOperator {
  _FakeReleaseOperator(this.inspection);

  final LabProductionOperatorInspection inspection;
  int executeCalls = 0;

  @override
  Future<LabProductionOperatorInspection> inspect() async => inspection;

  @override
  Future<LabProductionReleaseEvidence> executeInitialRelease({
    required String executedBy,
    required String confirmationPhrase,
    DateTime? executedAt,
  }) {
    executeCalls++;
    throw UnimplementedError();
  }

  @override
  Future<LabProductionReleaseEvidence> closeExistingRelease({
    required String executedBy,
    required String confirmationPhrase,
    DateTime? executedAt,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  test('Q17 preflight binds frozen Q16, project, manifest and 10/50 corpus',
      () async {
    final source = _FilePopulationSource();
    final operator = LabProductionReleaseOperatorService(
      populationSource: source,
      publishedRepository: InMemoryLabPublishedRepository(),
      catalogueRepository: InMemoryLabLearnerCatalogueRepository(),
      evidenceRepository: InMemoryLabProductionReleaseEvidenceRepository(),
      environmentId: 'firebase_project:csp11-exam-platform',
    );
    final deployment = InMemoryLabProductionDeploymentRepository();
    final service = LabProductionDeploymentAcceptanceService(
      populationSource: source,
      operator: operator,
      deploymentRepository: deployment,
      learnerRuntime: LabLearnerRuntimeBinding(
        deliveryService: LabLearnerControlledDeliveryService(
          publishedRepository: InMemoryLabPublishedRepository(),
          catalogueRepository: InMemoryLabLearnerCatalogueRepository(),
        ),
      ),
    );

    final evidence = await service.runPreflight(
      verifiedBy: 'admin_q17_test',
      verifiedAt: DateTime.utc(2026, 9, 24, 9),
    );

    expect(evidence.projectId, kExpectedProductionFirebaseProjectId);
    expect(evidence.q16ClosureSha, kLspQ16ClosedSha);
    expect(evidence.q16ValidationRunId, kLspQ16ClosureValidationRunId);
    expect(evidence.labCount, 10);
    expect(evidence.totalDecisionCount, 50);
    expect(
      evidence.preflightFingerprint,
      startsWith(kLabDeploymentPreflightFingerprintSchema + ':'),
    );
  });

  test('Q17 guarded release operator refuses action before preflight',
      () async {
    final inspection = LabProductionOperatorInspection(
      state: LabProductionOperatorState.pristine,
      manifestId: 'phase_l_population_v1',
      manifestFingerprint:
          kLabProductionManifestFingerprintSchema +
          ':' +
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      environmentId: 'firebase_project:csp11-exam-platform',
      expectedLabCount: 10,
      publishedCount: 0,
      catalogueCount: 0,
      catalogueIdentityCount: 0,
    );
    final delegate = _FakeReleaseOperator(inspection);
    final guarded = LabQ17GuardedProductionReleaseOperator(
      delegate: delegate,
      deploymentRepository: InMemoryLabProductionDeploymentRepository(),
    );

    await expectLater(
      guarded.executeInitialRelease(
        executedBy: 'admin_q17_test',
        confirmationPhrase: kQ16SeedConfirmationPhrase,
      ),
      throwsA(isA<LabProductionDeploymentException>()),
    );
    expect(delegate.executeCalls, 0);
  });

  test('Q17 live acceptance reconstructs exact 10-LAB / 50-decision runtime',
      () async {
    final source = _FilePopulationSource();
    final manifest = await source.loadManifest();
    final published = InMemoryLabPublishedRepository();
    final catalogue = InMemoryLabLearnerCatalogueRepository();
    final releaseEvidence = InMemoryLabProductionReleaseEvidenceRepository();
    final deployment = InMemoryLabProductionDeploymentRepository();
    final operator = LabProductionReleaseOperatorService(
      populationSource: source,
      publishedRepository: published,
      catalogueRepository: catalogue,
      evidenceRepository: releaseEvidence,
      environmentId: 'firebase_project:csp11-exam-platform',
    );
    final runtime = LabLearnerRuntimeBinding(
      deliveryService: LabLearnerControlledDeliveryService(
        publishedRepository: published,
        catalogueRepository: catalogue,
      ),
      releaseEvidenceRepository: releaseEvidence,
      requiredReleaseId: kInitialLabProductionReleaseId,
    );
    final service = LabProductionDeploymentAcceptanceService(
      populationSource: source,
      operator: operator,
      deploymentRepository: deployment,
      learnerRuntime: runtime,
    );

    await service.runPreflight(
      verifiedBy: 'admin_q17_test',
      verifiedAt: DateTime.utc(2026, 9, 24, 10),
    );

    await LabProductionPopulationSeedService(
      publishedRepository: published,
      catalogueRepository: catalogue,
    ).seedAndVerify(
      manifest: manifest,
      candidates: await source.loadCandidates(manifest),
      validatedAt: DateTime.utc(2026, 9, 24, 10, 10),
      publishedAt: DateTime.utc(2026, 9, 24, 10, 20),
    );

    await LabProductionReleaseClosureService(
      publishedRepository: published,
      catalogueRepository: catalogue,
      evidenceRepository: releaseEvidence,
    ).closeRelease(
      manifest: manifest,
      environmentId: 'firebase_project:csp11-exam-platform',
      executedBy: 'admin_q17_test',
      executedAt: DateTime.utc(2026, 9, 24, 10, 30),
    );

    final accepted = await service.acceptLiveRelease(
      acceptedBy: 'admin_q17_test',
      acceptedAt: DateTime.utc(2026, 9, 24, 10, 40),
    );

    expect(accepted.labCount, 10);
    expect(accepted.totalDecisionCount, 50);
    expect(accepted.learnerCatalogueIdentityKeys, hasLength(10));
    expect(
      accepted.acceptanceFingerprint,
      startsWith(kLabReleaseAcceptanceFingerprintSchema + ':'),
    );

    final status = await service.inspect();
    expect(status.operatorInspection.isClosed, isTrue);
    expect(status.preflight, isNotNull);
    expect(status.acceptance, isNotNull);
  });

  test('Q17 static deployment contract pins Firebase target and immutable paths',
      () {
    final firebase = File('firebase.json').readAsStringSync();
    final options = File('lib/firebase_options.dart').readAsStringSync();
    final rules = File('firestore.rules').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(firebase, contains('"projectId":  "csp11-exam-platform"'));
    expect(options, contains("projectId: 'csp11-exam-platform'"));
    expect(pubspec, contains('    - content/'));
    expect(
      rules,
      contains('match /labProductionDeploymentPreflight/{preflightId}'),
    );
    expect(
      rules,
      contains('match /labProductionReleaseAcceptance/{acceptanceId}'),
    );
    expect(rules, contains(kLspQ16ClosedSha));
    expect(rules, contains(kLspQ16ClosureValidationRunId));
    expect(rules, contains('allow update, delete: if false;'));
  });

  test('Q17 Admin Publishing routes through deployment preflight screen', () {
    final source =
        File('lib/screens/admin/admin_home_screen.dart').readAsStringSync();

    expect(source, contains('LabProductionDeploymentScreen('));
    expect(source, contains('LabProductionReleaseScreen('));
    expect(source, contains('releaseScreenBuilder:'));
  });
}
