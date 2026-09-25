import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/lab/lab_batch2_release_integration.dart';
import 'package:exam_platform/features/lab/lab_dqg300_evidence_store.dart';
import 'package:exam_platform/features/lab/lab_learner_catalogue.dart';
import 'package:exam_platform/features/lab/lab_learner_presentation.dart';
import 'package:exam_platform/features/lab/lab_production_deployment_acceptance.dart';
import 'package:exam_platform/features/lab/lab_production_population_seed.dart';
import 'package:exam_platform/features/lab/lab_production_release_operator.dart';
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

class _FileBatch2PopulationSource implements LabProductionPopulationSource {
  @override
  Future<LabScenarioPopulationManifest> loadManifest() async {
    return LabScenarioPopulationManifest.fromJson(
      _readObject('content/lab_population_batch2/manifest.json'),
    );
  }

  @override
  Future<List<LabProductionPopulationSeedCandidate>> loadCandidates(
    LabScenarioPopulationManifest manifest,
  ) async {
    return manifest.entries
        .map((entry) {
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
        })
        .toList(growable: false);
  }
}

void main() {
  test('Batch 2 learner catalogue activates only after Batch 2 Q17', () async {
    final source = _FileBatch2PopulationSource();
    final published = InMemoryLabPublishedRepository();
    final staging = InMemoryLabBatch2CatalogueStagingRepository();
    final evidence = InMemoryLabBatch2ReleaseEvidenceRepository();
    final catalogue = InMemoryLabLearnerCatalogueRepository();
    final releaseOperator = LabBatch2ReleaseOperatorService(
      populationSource: source,
      publishedRepository: published,
      stagingRepository: staging,
      evidenceRepository: evidence,
      environmentId: kExpectedLabProductionEnvironmentId,
    );
    final acceptanceRepository = InMemoryLabBatch2ReleaseAcceptanceRepository(
      stagingRepository: staging,
      catalogueRepository: catalogue,
    );
    final acceptanceService = LabBatch2AcceptanceService(
      releaseOperator: releaseOperator,
      populationSource: source,
      acceptanceRepository: acceptanceRepository,
    );

    final beforeQ16 = await acceptanceService.inspect();
    expect(beforeQ16.state, LabBatch2AcceptanceState.blocked);
    expect(beforeQ16.activatedCount, 0);
    expect(await catalogue.listAvailable(), isEmpty);

    await releaseOperator.executeRelease(
      executedBy: 'admin_batch2_test',
      confirmationPhrase: kBatch2ReleaseConfirmationPhrase,
      executedAt: DateTime.utc(2026, 9, 25, 1),
    );

    final ready = await acceptanceService.inspect();
    expect(ready.state, LabBatch2AcceptanceState.ready);
    expect(ready.activatedCount, 0);
    expect(await catalogue.listAvailable(), isEmpty);

    final acceptance = await acceptanceService.acceptLiveRelease(
      acceptedBy: 'admin_batch2_test',
      confirmationPhrase: kBatch2AcceptanceConfirmationPhrase,
      acceptedAt: DateTime.utc(2026, 9, 25, 1, 15),
    );

    expect(acceptance.releaseId, kBatch2ReleaseId);
    expect(acceptance.labCount, 10);
    expect(acceptance.totalDecisionCount, 50);

    final accepted = await acceptanceService.inspect();
    expect(accepted.state, LabBatch2AcceptanceState.accepted);
    expect(accepted.activatedCount, 10);
    expect(await catalogue.listAvailable(), hasLength(10));
  });

  test('Batch 2 release exposes a distinct resume confirmation phrase', () {
    expect(kBatch2ResumeConfirmationPhrase, 'RESUME BATCH 2 RELEASE');
  });

  test('Batch 2 exact confirmation phrases remain fail closed', () async {
    final source = _FileBatch2PopulationSource();
    final operator = LabBatch2ReleaseOperatorService(
      populationSource: source,
      publishedRepository: InMemoryLabPublishedRepository(),
      stagingRepository: InMemoryLabBatch2CatalogueStagingRepository(),
      evidenceRepository: InMemoryLabBatch2ReleaseEvidenceRepository(),
      environmentId: kExpectedLabProductionEnvironmentId,
    );

    await expectLater(
      operator.executeRelease(
        executedBy: 'admin_batch2_test',
        confirmationPhrase: 'RELEASE LABS',
      ),
      throwsA(isA<LabBatch2ReleaseException>()),
    );

    final inspection = await operator.inspect();
    expect(inspection.state, LabBatch2ReleaseState.pristine);
    expect(inspection.publishedCount, 0);
    expect(inspection.stagedCount, 0);
  });

  test('learner visibility is pinned to Batch 2 and excludes legacy LABs', () {
    final rules = File('firestore.rules').readAsStringSync();
    final repository = File(
      'lib/features/lab/lab_firestore_repositories.dart',
    ).readAsStringSync();
    final runtime = File(
      'lib/features/lab/lab_runtime_binding.dart',
    ).readAsStringSync();

    expect(
      kLearnerVisibleLabReleaseId,
      'phase_l_population_batch2_v1_q16_extension_v1',
    );
    expect(
      rules,
      contains(
        "resource.data.releaseId\n            == 'phase_l_population_batch2_v1_q16_extension_v1'",
      ),
    );
    expect(rules, contains('batch2LabPopulationAccepted()'));
    expect(rules, contains('csp11.lab.learner_extension_visibility.v1'));
    expect(
      rules,
      contains('match /labProductionReleaseExtensionState/{releaseId}'),
    );
    expect(
      rules,
      contains('match /labLearnerReleaseExtensionState/{releaseId}'),
    );
    expect(
      rules,
      contains(
        '/documents/labProductionReleaseExtensionAcceptance/phase_l_population_batch2_v1_q16_extension_v1',
      ),
    );
    expect(repository, contains('visibleReleaseId'));
    expect(runtime, contains('visibleReleaseId: kLearnerVisibleLabReleaseId'));
    expect(runtime, contains('FirestoreLabBatch2LearnerVisibilityRepository'));

    final catalogueBlock = RegExp(
      r'match /labLearnerCatalogue/\{versionKey\} \{([\s\S]*?)match /labProductionCatalogueStaging',
    ).firstMatch(rules);
    expect(catalogueBlock, isNotNull);
    expect(
      catalogueBlock!.group(1),
      isNot(contains('initialLabPopulationReleased()')),
    );
  });

  test('Batch 2 assets and admin release surface are bundled', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final admin = File(
      'lib/screens/admin/admin_home_screen.dart',
    ).readAsStringSync();

    expect(pubspec, contains('content/lab_population_batch2/'));
    expect(pubspec, contains('contractor_permit_coordination/v1/'));
    expect(pubspec, contains('emergency_evacuation_muster/v1/'));
    expect(admin, contains("'Batch 2 Release'"));
    expect(admin, contains('_openBatch2Release()'));
    expect(admin, contains('LabBatch2ReleaseScreen('));
  });
}
