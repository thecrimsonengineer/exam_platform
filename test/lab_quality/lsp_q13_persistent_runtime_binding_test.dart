import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/lab/lab_dqg300_evidence_store.dart';
import 'package:exam_platform/features/lab/lab_firestore_repositories.dart';
import 'package:exam_platform/features/lab/lab_learner_catalogue.dart';
import 'package:exam_platform/features/lab/lab_learner_presentation.dart';
import 'package:exam_platform/features/lab/lab_runtime_binding.dart';
import 'package:exam_platform/features/lab/lab_scenario_population_manifest.dart';
import 'package:exam_platform/features/lab/lab_scenario_population_publication.dart';
import 'package:exam_platform/features/lab/lab_studio.dart';
import 'package:exam_platform/screens/lab/lab_library_screen.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _readObject(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! Map) throw StateError('Expected JSON object at ' + path);
  return decoded.cast<String, Object?>();
}

LabScenarioPopulationManifest _manifest() =>
    LabScenarioPopulationManifest.fromJson(
      _readObject('content/lab_population/manifest.json'),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LabScenarioPopulationManifest manifest;
  late LabScenarioPopulationManifestEntry manifestEntry;
  late LabPublishedVersion publishedVersion;
  late LabLearnerCatalogueEntry catalogueEntry;

  setUpAll(() async {
    manifest = _manifest();
    manifestEntry = manifest.entries.first;

    final publishedRepository = InMemoryLabPublishedRepository();
    final publicationGate = LabScenarioPopulationPublicationGate(
      studio: Lab1000StudioService(repository: publishedRepository),
    );

    await publicationGate.admit(
      manifest: manifest,
      entryId: manifestEntry.entryId,
      technicalRoot: _readObject(manifestEntry.technicalLabPath),
      dqg300Evidence: const LabDqg300EvidenceCodec().decode(
        File(manifestEntry.dqg300EvidencePath).readAsStringSync(),
      ),
      presentationPackage: LabLearnerPresentationPackage.fromJson(
        _readObject(manifestEntry.learnerPresentationPath),
      ),
      validatedAt: DateTime.utc(2026, 9, 24, 1),
      publishedAt: DateTime.utc(2026, 9, 24, 1, 1),
    );

    publishedVersion = (await publishedRepository.load(
      manifestEntry.labId,
      manifestEntry.versionId,
    ))!;

    final catalogueRepository = InMemoryLabLearnerCatalogueRepository();
    catalogueEntry = await LabLearnerCatalogueAdmissionService(
      publishedRepository: publishedRepository,
      catalogueRepository: catalogueRepository,
    ).admit(
      manifest: manifest,
      entryId: manifestEntry.entryId,
      presentation: LabLearnerPresentationPackage.fromJson(
        _readObject(manifestEntry.learnerPresentationPath),
      ),
    );
  });

  test('Q13 Firestore published repository round-trips immutable Q11 version',
      () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreLabPublishedRepository(firestore: firestore);

    await repository.saveImmutable(publishedVersion);
    final loaded = await repository.load(
      manifestEntry.labId,
      manifestEntry.versionId,
    );

    expect(loaded, isNotNull);
    expect(loaded!.publishedJson, publishedVersion.publishedJson);
    expect(loaded.snapshotFingerprint, publishedVersion.snapshotFingerprint);
    expect(loaded.validationAuthority, 'LSP-Q11-POPULATION-AUTO');

    await expectLater(
      repository.saveImmutable(publishedVersion),
      throwsA(isA<LabStudioException>()),
    );
  });

  test('Q13 Firestore learner catalogue round-trips learner-safe entry',
      () async {
    final firestore = FakeFirebaseFirestore();
    final repository =
        FirestoreLabLearnerCatalogueRepository(firestore: firestore);

    await repository.saveImmutable(catalogueEntry);
    final loaded = await repository.load(
      catalogueEntry.labId,
      catalogueEntry.versionId,
    );
    final available = await repository.listAvailable();

    expect(loaded, isNotNull);
    expect(loaded!.identityKey, catalogueEntry.identityKey);
    expect(loaded.title, catalogueEntry.title);
    expect(loaded.presentation.labId, catalogueEntry.labId);
    expect(available, hasLength(1));

    await expectLater(
      repository.saveImmutable(catalogueEntry),
      throwsA(isA<LabLearnerCatalogueException>()),
    );
  });

  test('Q13 runtime binding lists and loads exact persistent version', () async {
    final firestore = FakeFirebaseFirestore();
    await FirestoreLabPublishedRepository(firestore: firestore)
        .saveImmutable(publishedVersion);
    await FirestoreLabLearnerCatalogueRepository(firestore: firestore)
        .saveImmutable(catalogueEntry);

    final binding = LabLearnerRuntimeBinding.firestore(firestore: firestore);
    final available = await binding.listAvailable();
    final delivery = await binding.load(
      labId: catalogueEntry.labId,
      versionId: catalogueEntry.versionId,
    );

    expect(available, hasLength(1));
    expect(available.single.identityKey, catalogueEntry.identityKey);
    expect(delivery.package.metadata.id, catalogueEntry.labId);
    expect(delivery.package.metadata.versionId, catalogueEntry.versionId);
    expect(delivery.presentation.labId, catalogueEntry.labId);
  });

  testWidgets('Q13 persistent library reaches briefing through exact package',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final firestore = FakeFirebaseFirestore();
    await FirestoreLabPublishedRepository(firestore: firestore)
        .saveImmutable(publishedVersion);
    await FirestoreLabLearnerCatalogueRepository(firestore: firestore)
        .saveImmutable(catalogueEntry);

    final binding = LabLearnerRuntimeBinding.firestore(firestore: firestore);
    await tester.pumpWidget(
      MaterialApp(
        home: LabLibraryScreen.withBinding(runtimeBinding: binding),
      ),
    );

    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text(catalogueEntry.title).evaluate().isNotEmpty) break;
    }

    expect(find.text(catalogueEntry.title), findsOneWidget);
    final open = find.byKey(
      ValueKey('lab-scenario-open-' + catalogueEntry.labId),
    );
    await tester.ensureVisible(open);
    await tester.tap(open);

    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byKey(const ValueKey('lab-scenario-briefing')).evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.byKey(const ValueKey('lab-scenario-briefing')), findsOneWidget);
    expect(find.byKey(const ValueKey('lab-briefing-title')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('lab-briefing-title')),
        matching: find.text(catalogueEntry.title),
      ),
      findsOneWidget,
    );

    final next = find.byKey(const ValueKey('lab-briefing-continue'));
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pumpAndSettle();

    final guided = find.byKey(const ValueKey('lab-mode-guided'));
    await tester.ensureVisible(guided);
    await tester.tap(guided);

    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byKey(const ValueKey('lab-reference-player')).evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.byKey(const ValueKey('lab-reference-player')), findsOneWidget);
  });

  test('Q13 Firestore rules keep LAB writes admin-only and versions immutable',
      () {
    final rules = File('firestore.rules').readAsStringSync();

    expect(rules, contains('match /labPublishedVersions/{versionKey}'));
    expect(rules, contains('match /labLearnerCatalogue/{versionKey}'));
    expect(rules, contains('allow create: if isAdmin() && validLabPublishedVersion'));
    expect(rules, contains('allow create: if isAdmin() && validLabCatalogueEntry'));
    expect(rules, contains('allow update, delete: if false;'));
    expect(
      rules,
      contains("resource.data.lifecycle == 'published'"),
    );
    expect(
      rules,
      contains("resource.data.available == true"),
    );
  });

  test('Q13 production LAB tab binds to persistent learner library', () {
    final source = File(
      'lib/screens/navigation/bottom_navigation.dart',
    ).readAsStringSync();

    expect(source, contains('LabLibraryScreen.persistent()'));
  });
}
