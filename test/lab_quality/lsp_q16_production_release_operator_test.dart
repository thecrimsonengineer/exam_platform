import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/lab/lab_dqg300_evidence_store.dart';
import 'package:exam_platform/features/lab/lab_learner_catalogue.dart';
import 'package:exam_platform/features/lab/lab_learner_presentation.dart';
import 'package:exam_platform/features/lab/lab_production_population_seed.dart';
import 'package:exam_platform/features/lab/lab_production_release_closure.dart';
import 'package:exam_platform/features/lab/lab_production_release_operator.dart';
import 'package:exam_platform/features/lab/lab_scenario_population_manifest.dart';
import 'package:exam_platform/features/lab/lab_studio.dart';
import 'package:exam_platform/screens/admin/lab/lab_production_release_screen.dart';
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

class _PartialPublishedRepository implements LabPublishedRepository {
  _PartialPublishedRepository(this.firstEntry);

  final LabScenarioPopulationManifestEntry firstEntry;

  @override
  Future<LabPublishedVersion?> load(String labId, String versionId) async {
    if (labId == firstEntry.labId && versionId == firstEntry.versionId) {
      return LabPublishedVersion(
        labId: labId,
        versionId: versionId,
        publishedJson: '{}',
        publishedAt: DateTime.utc(2026, 9, 24),
        reviewerId: 'partial_test',
      );
    }
    return null;
  }

  @override
  Future<void> saveImmutable(LabPublishedVersion version) {
    throw UnimplementedError();
  }
}

class _FakeOperator implements LabProductionReleaseOperator {
  _FakeOperator(this.inspection);

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

void main() {
  test(
    'Q16 classifies pristine, complete-unclosed and closed release states',
    () async {
      final source = _FilePopulationSource();
      final manifest = await source.loadManifest();
      final published = InMemoryLabPublishedRepository();
      final catalogue = InMemoryLabLearnerCatalogueRepository();
      final evidenceRepository =
          InMemoryLabProductionReleaseEvidenceRepository();
      final operator = LabProductionReleaseOperatorService(
        populationSource: source,
        publishedRepository: published,
        catalogueRepository: catalogue,
        evidenceRepository: evidenceRepository,
        environmentId: 'production_test',
      );

      expect(
        (await operator.inspect()).state,
        LabProductionOperatorState.pristine,
      );

      await LabProductionPopulationSeedService(
        publishedRepository: published,
        catalogueRepository: catalogue,
      ).seedAndVerify(
        manifest: manifest,
        candidates: await source.loadCandidates(manifest),
        validatedAt: DateTime.utc(2026, 9, 24, 8),
        publishedAt: DateTime.utc(2026, 9, 24, 8, 10),
      );

      final unclosed = await operator.inspect();
      expect(
        unclosed.state,
        LabProductionOperatorState.completeUnclosed,
      );
      expect(unclosed.publishedCount, 10);
      expect(unclosed.catalogueCount, 10);

      final evidence = await operator.closeExistingRelease(
        executedBy: 'admin_q16_test',
        confirmationPhrase: kQ16CloseConfirmationPhrase,
        executedAt: DateTime.utc(2026, 9, 24, 8, 20),
      );
      final closed = await operator.inspect();

      expect(closed.state, LabProductionOperatorState.closed);
      expect(closed.evidence, isNotNull);
      expect(
        closed.evidence!.evidenceFingerprint,
        evidence.evidenceFingerprint,
      );
      expect(evidence.labCount, 10);
      expect(evidence.totalDecisionCount, 50);
    },
  );

  test('Q16 blocks partial production population from automatic repair',
      () async {
    final source = _FilePopulationSource();
    final manifest = await source.loadManifest();
    final operator = LabProductionReleaseOperatorService(
      populationSource: source,
      publishedRepository: _PartialPublishedRepository(
        manifest.entries.first,
      ),
      catalogueRepository: InMemoryLabLearnerCatalogueRepository(),
      evidenceRepository: InMemoryLabProductionReleaseEvidenceRepository(),
      environmentId: 'production_test',
    );

    final inspection = await operator.inspect();

    expect(
      inspection.state,
      LabProductionOperatorState.blockedPartial,
    );
    expect(inspection.publishedCount, 1);
    expect(inspection.canExecuteSeed, isFalse);
    expect(inspection.canCloseExisting, isFalse);
    expect(
      inspection.blockingReason,
      contains('partial population'),
    );
  });

  test('Q16 requires exact typed confirmation before initial seed', () async {
    final source = _FilePopulationSource();
    final published = InMemoryLabPublishedRepository();
    final operator = LabProductionReleaseOperatorService(
      populationSource: source,
      publishedRepository: published,
      catalogueRepository: InMemoryLabLearnerCatalogueRepository(),
      evidenceRepository: InMemoryLabProductionReleaseEvidenceRepository(),
      environmentId: 'production_test',
    );

    await expectLater(
      operator.executeInitialRelease(
        executedBy: 'admin_q16_test',
        confirmationPhrase: 'RELEASE LABS',
      ),
      throwsA(isA<LabProductionReleaseClosureException>()),
    );

    final manifest = await source.loadManifest();
    expect(
      await published.load(
        manifest.entries.first.labId,
        manifest.entries.first.versionId,
      ),
      isNull,
    );
  });

  test('Q16 Firestore rules keep learners gated but allow admin preflight', () {
    final rules = File('firestore.rules').readAsStringSync();

    expect(rules, contains('match /labLearnerCatalogue/{versionKey}'));
    expect(rules, contains('allow get, list: if isAdmin()'));
    expect(rules, contains('initialLabPopulationReleased()'));
    expect(
      rules,
      contains('match /labProductionReleaseEvidence/{releaseId}'),
    );
    expect(
      rules,
      contains('match /labLearnerReleaseState/{releaseId}'),
    );
  });

  testWidgets('Q16 production screen requires exact confirmation phrase',
      (tester) async {
    final inspection = LabProductionOperatorInspection(
      state: LabProductionOperatorState.pristine,
      manifestId: 'phase_l_population_v1',
      manifestFingerprint:
          kLabProductionManifestFingerprintSchema +
          ':' +
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      environmentId: 'production_test',
      expectedLabCount: 10,
      publishedCount: 0,
      catalogueCount: 0,
      catalogueIdentityCount: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LabProductionReleaseScreen(
          adminUserId: 'admin_q16_test',
          operator: _FakeOperator(inspection),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PRISTINE'), findsOneWidget);
    final confirmation = find.byKey(const ValueKey('q16-confirmation'));
    final action = find.byKey(const ValueKey('q16-release-action'));

    await tester.scrollUntilVisible(
      confirmation,
      320,
      scrollable: find.byType(Scrollable).first,
    );
    expect(confirmation, findsOneWidget);
    expect(action, findsOneWidget);
    expect(tester.widget<FilledButton>(action).onPressed, isNull);

    await tester.enterText(
      confirmation,
      kQ16SeedConfirmationPhrase,
    );
    await tester.pump();

    expect(tester.widget<FilledButton>(action).onPressed, isNotNull);
  });

  test('Q16 admin Publishing navigation opens the release surface', () {
    final source =
        File('lib/screens/admin/admin_home_screen.dart').readAsStringSync();

    expect(source, contains("else if (index == 5)"));
    expect(source, contains('_openProductionRelease()'));
    expect(source, contains('LabProductionReleaseScreen('));
  });
}
