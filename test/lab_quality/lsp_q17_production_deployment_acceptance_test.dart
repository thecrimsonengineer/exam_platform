import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/lab/lab_dqg300_evidence_store.dart';
import 'package:exam_platform/features/lab/lab_learner_catalogue.dart';
import 'package:exam_platform/features/lab/lab_learner_presentation.dart';
import 'package:exam_platform/features/lab/lab_production_deployment_acceptance.dart';
import 'package:exam_platform/features/lab/lab_production_population_seed.dart';
import 'package:exam_platform/features/lab/lab_production_release_closure.dart';
import 'package:exam_platform/features/lab/lab_production_release_operator.dart';
import 'package:exam_platform/features/lab/lab_scenario_population_manifest.dart';
import 'package:exam_platform/features/lab/lab_studio.dart';
import 'package:exam_platform/screens/admin/lab/lab_production_deployment_acceptance_screen.dart';
import 'package:flutter/material.dart';
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

  @override
  Future<LabProductionOperatorInspection> inspect() async => inspection;

  @override
  Future<LabProductionReleaseEvidence> closeExistingRelease({
    required String executedBy,
    required String confirmationPhrase,
    DateTime? executedAt,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<LabProductionReleaseEvidence> executeInitialRelease({
    required String executedBy,
    required String confirmationPhrase,
    DateTime? executedAt,
  }) {
    throw UnimplementedError();
  }
}

class _FakeAcceptanceOperator
    implements LabProductionDeploymentAcceptanceOperator {
  _FakeAcceptanceOperator(this.inspection);

  final LabProductionDeploymentInspection inspection;

  @override
  Future<LabProductionDeploymentInspection> inspect() async => inspection;

  @override
  Future<LabProductionReleaseAcceptance> acceptLiveRelease({
    required String acceptedBy,
    required String confirmationPhrase,
    DateTime? acceptedAt,
  }) {
    throw UnimplementedError();
  }
}

Future<LabProductionOperatorInspection> _closedQ16Inspection() async {
  final source = _FilePopulationSource();
  final manifest = await source.loadManifest();
  final published = InMemoryLabPublishedRepository();
  final catalogue = InMemoryLabLearnerCatalogueRepository();
  final evidenceRepository = InMemoryLabProductionReleaseEvidenceRepository();

  await LabProductionPopulationSeedService(
    publishedRepository: published,
    catalogueRepository: catalogue,
  ).seedAndVerify(
    manifest: manifest,
    candidates: await source.loadCandidates(manifest),
    validatedAt: DateTime.utc(2026, 9, 24, 8),
    publishedAt: DateTime.utc(2026, 9, 24, 8, 10),
  );

  final operator = LabProductionReleaseOperatorService(
    populationSource: source,
    publishedRepository: published,
    catalogueRepository: catalogue,
    evidenceRepository: evidenceRepository,
    environmentId: kExpectedLabProductionEnvironmentId,
  );

  await operator.closeExistingRelease(
    executedBy: 'admin_q17_test',
    confirmationPhrase: kQ16CloseConfirmationPhrase,
    executedAt: DateTime.utc(2026, 9, 24, 8, 20),
  );
  return operator.inspect();
}

void main() {
  test('Q17 accepts only the frozen production environment', () async {
    final closed = await _closedQ16Inspection();
    final wrongEnvironment = LabProductionOperatorInspection(
      state: closed.state,
      manifestId: closed.manifestId,
      manifestFingerprint: closed.manifestFingerprint,
      environmentId: 'firebase_project:not-production',
      expectedLabCount: closed.expectedLabCount,
      publishedCount: closed.publishedCount,
      catalogueCount: closed.catalogueCount,
      catalogueIdentityCount: closed.catalogueIdentityCount,
      evidence: closed.evidence,
    );

    final service = LabProductionDeploymentAcceptanceService(
      releaseOperator: _FakeReleaseOperator(wrongEnvironment),
      acceptanceRepository: InMemoryLabProductionReleaseAcceptanceRepository(),
    );

    final inspection = await service.inspect();
    expect(inspection.state, LabProductionDeploymentState.blocked);
    expect(inspection.blockingReason, contains('not the frozen production'));
  });

  test('Q17 moves CLOSED release from READY to immutable ACCEPTED', () async {
    final closed = await _closedQ16Inspection();
    final repository = InMemoryLabProductionReleaseAcceptanceRepository();
    final service = LabProductionDeploymentAcceptanceService(
      releaseOperator: _FakeReleaseOperator(closed),
      acceptanceRepository: repository,
    );

    final ready = await service.inspect();
    expect(ready.state, LabProductionDeploymentState.ready);
    expect(ready.canAccept, isTrue);
    expect(ready.evidence!.labCount, 10);
    expect(ready.evidence!.totalDecisionCount, 50);

    final acceptance = await service.acceptLiveRelease(
      acceptedBy: 'admin_q17_test',
      confirmationPhrase: kQ17AcceptanceConfirmationPhrase,
      acceptedAt: DateTime.utc(2026, 9, 24, 9),
    );

    final accepted = await service.inspect();
    expect(accepted.state, LabProductionDeploymentState.accepted);
    expect(
      accepted.acceptance!.acceptanceFingerprint,
      acceptance.acceptanceFingerprint,
    );

    await expectLater(
      service.acceptLiveRelease(
        acceptedBy: 'admin_q17_test',
        confirmationPhrase: kQ17AcceptanceConfirmationPhrase,
      ),
      throwsA(isA<LabProductionDeploymentAcceptanceException>()),
    );
  });

  test('Q17 requires exact typed acceptance phrase', () async {
    final closed = await _closedQ16Inspection();
    final service = LabProductionDeploymentAcceptanceService(
      releaseOperator: _FakeReleaseOperator(closed),
      acceptanceRepository: InMemoryLabProductionReleaseAcceptanceRepository(),
    );

    await expectLater(
      service.acceptLiveRelease(
        acceptedBy: 'admin_q17_test',
        confirmationPhrase: 'ACCEPT RELEASE',
      ),
      throwsA(isA<LabProductionDeploymentAcceptanceException>()),
    );
  });

  test('Q17 Firestore rules make acceptance admin-only and immutable', () {
    final rules = File('firestore.rules').readAsStringSync();

    expect(
      rules,
      contains('match /labProductionReleaseAcceptance/{releaseId}'),
    );
    expect(rules, contains("'04bfdc9d5c61faeb5a7a30e86cb753947ba8e49a'"));
    expect(rules, contains("'35950731991'"));
    expect(rules, contains("'firebase_project:csp11-exam-platform'"));
    expect(rules, contains('allow update, delete: if false;'));
  });

  testWidgets('Q17 acceptance screen requires exact confirmation phrase', (
    tester,
  ) async {
    final inspection = LabProductionDeploymentInspection(
      state: LabProductionDeploymentState.ready,
      environmentId: kExpectedLabProductionEnvironmentId,
      expectedEnvironmentId: kExpectedLabProductionEnvironmentId,
      manifestId: 'phase_l_population_v1',
      manifestFingerprint:
          kLabProductionManifestFingerprintSchema +
          ':' +
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      expectedLabCount: 10,
      publishedCount: 10,
      catalogueCount: 10,
      catalogueIdentityCount: 10,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LabProductionDeploymentAcceptanceScreen(
          adminUserId: 'admin_q17_test',
          operator: _FakeAcceptanceOperator(inspection),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('READY'), findsOneWidget);
    final confirmation = find.byKey(const ValueKey('q17-confirmation'));
    final action = find.byKey(const ValueKey('q17-accept-action'));

    await tester.scrollUntilVisible(
      confirmation,
      320,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<FilledButton>(action).onPressed, isNull);

    await tester.enterText(confirmation, kQ17AcceptanceConfirmationPhrase);
    await tester.pump();

    expect(tester.widget<FilledButton>(action).onPressed, isNotNull);
  });

  test('Q17 Admin navigation exposes deployment acceptance', () {
    final source = File(
      'lib/screens/admin/admin_home_screen.dart',
    ).readAsStringSync();

    expect(source, contains("'Release Acceptance'"));
    expect(source, contains('_openProductionAcceptance()'));
    expect(source, contains('LabProductionDeploymentAcceptanceScreen('));
  });
}
