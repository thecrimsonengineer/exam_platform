import 'dart:io';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_session.dart';
import 'package:exam_platform/features/lab/lab_studio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lab_l2_test_fixtures.dart';

void main() {
  for (var i = 0; i < 10; i++) {
    test('LAB-6 JSON file import ' + (i + 1).toString(), () async {
      final source =
          File('test/fixtures/lab/l2_valid_lab.json').readAsStringSync();
      final service = buildL2StudioService();
      final workspace = service.importJson(source);

      expect(workspace.package.metadata.id, 'l2_lab');
      expect(workspace.lifecycle, LabLifecycleStatus.draft);
      expect(workspace.report.isValid, isTrue);

      if (i == 0) {
        final review = service.requestReview(workspace);
        final validated = service.approveReview(
          review,
          reviewerId: 'golden-reviewer',
        );
        final published = await service.publish(validated);
        final runnable = LabPackage.decode(
          published.publishedVersion!.publishedJson,
        );
        final sessionEngine = LabSessionEngine(
          store: InMemoryLabSessionStore(),
        );
        final session = await sessionEngine.startAttempt(
          package: runnable,
          sessionId: 'golden_runtime_session',
          userId: 'golden_user',
          mode: LabMode.professional,
        );
        final progressed = await sessionEngine.commitDecision(
          package: runnable,
          session: session,
          optionId: 'o1',
          responseTimeMs: 100,
        );
        expect(progressed.currentNodeId, 'decision_two');
      }
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-6 paste import ' + (i + 1).toString(), () {
      final service = buildL2StudioService();
      final workspace = service.pasteJson(buildL2Source());
      expect(workspace.package.nodes, hasLength(2));
      expect(workspace.package.consequences, hasLength(8));
      expect(workspace.report.deterministic, isTrue);
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-6 graph and metadata inspection ' + (i + 1).toString(), () {
      final service = buildL2StudioService();
      final workspace = service.importJson(buildL2Source());
      final inspection = service.inspect(workspace);

      expect(inspection.metadata.id, 'l2_lab');
      expect(inspection.stateVariableIds, contains('risk'));
      expect(inspection.nodeIds, containsAll(<String>[
        'decision_one',
        'decision_two',
      ]));
      expect(inspection.gateIds, contains('complete'));
      expect(inspection.endingIds, contains('safe_end'));
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-6 preview creation ' + (i + 1).toString(), () {
      final service = buildL2StudioService();
      final workspace = service.importJson(buildL2Source());
      final preview = service.createPreview(workspace);

      expect(preview.labId, 'l2_lab');
      expect(preview.versionId, 'v1');
      expect(preview.nodeCount, 2);
      expect(preview.decisionCount, 2);
      expect(preview.gateCount, 3);
      expect(preview.endingCount, 1);
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-6 validation report ' + (i + 1).toString(), () {
      final service = buildL2StudioService();
      final workspace = service.importJson(buildL2Source());
      final checked = service.validate(workspace);

      expect(checked.report.errorCount, 0);
      expect(checked.report.isValid, isTrue);
      expect(checked.report.simulationCount, greaterThan(0));
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-6 draft editing ' + (i + 1).toString(), () {
      final service = buildL2StudioService();
      final workspace = service.importJson(buildL2Source());
      final root = copyL2Root();
      final lab = (root['lab'] as Map).cast<String, Object?>();
      lab['title'] = 'Edited LAB ' + i.toString();
      final edited = service.editRoot(workspace, root);

      expect(edited.package.metadata.title, 'Edited LAB ' + i.toString());
      expect(edited.lifecycle, LabLifecycleStatus.draft);
      expect(edited.report.isValid, isTrue);
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-6 lifecycle DRAFT to REVIEW ' + (i + 1).toString(), () {
      final service = buildL2StudioService();
      final workspace = service.importJson(buildL2Source());
      final review = service.requestReview(workspace);

      expect(review.lifecycle, LabLifecycleStatus.review);
      expect(review.report.isValid, isTrue);
      expect(review.sourceJson, contains('"lifecycle":"REVIEW"'));
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-6 reviewer validation boundary ' + (i + 1).toString(), () {
      final service = buildL2StudioService();
      final draft = service.importJson(buildL2Source());
      final review = service.requestReview(draft);
      final validated = service.approveReview(
        review,
        reviewerId: 'reviewer_' + i.toString(),
      );

      expect(validated.lifecycle, LabLifecycleStatus.validated);
      expect(validated.reviewerId, 'reviewer_' + i.toString());
      expect(validated.report.isValid, isTrue);
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-6 immutable publish ' + (i + 1).toString(), () async {
      final service = buildL2StudioService();
      final review = service.requestReview(
        service.importJson(buildL2Source()),
      );
      final validated = service.approveReview(
        review,
        reviewerId: 'reviewer',
      );
      final published = await service.publish(
        validated,
        publishedAt: DateTime.utc(2026, 9, 18, 15, i),
      );

      expect(published.lifecycle, LabLifecycleStatus.published);
      expect(published.publishedVersion, isNotNull);
      final stored = await service.repository.load('l2_lab', 'v1');
      expect(stored, isNotNull);
      await expectLater(
        service.repository.saveImmutable(stored!),
        throwsA(isA<LabStudioException>()),
      );
    });
  }

  for (var i = 0; i < 10; i++) {
    test('LAB-6 version creation ' + (i + 1).toString(), () async {
      final service = buildL2StudioService();
      final review = service.requestReview(
        service.importJson(buildL2Source()),
      );
      final validated = service.approveReview(
        review,
        reviewerId: 'reviewer',
      );
      final published = await service.publish(validated);
      final revision = service.createRevision(
        published,
        newVersionId: 'v2_' + i.toString(),
      );

      expect(revision.lifecycle, LabLifecycleStatus.draft);
      expect(revision.package.metadata.versionId, 'v2_' + i.toString());
      expect(revision.reviewerId, isNull);
      expect(revision.publishedVersion, isNull);
      expect(
        () => service.editRoot(published, copyL2Root()),
        throwsA(isA<LabStudioException>()),
      );
    });
  }

  final uiContracts = <({String path, String needle})>[
    (
      path: 'lib/screens/admin/lab/lab1000_studio_screen.dart',
      needle: "ValueKey('lab1000-json-editor')",
    ),
    (
      path: 'lib/screens/admin/lab/lab1000_studio_screen.dart',
      needle: "ValueKey('lab1000-import-file')",
    ),
    (
      path: 'lib/screens/admin/lab/lab1000_studio_screen.dart',
      needle: "ValueKey('lab1000-paste-import')",
    ),
    (
      path: 'lib/screens/admin/lab/lab1000_studio_screen.dart',
      needle: "ValueKey('lab1000-validate')",
    ),
    (
      path: 'lib/screens/admin/lab/lab1000_studio_screen.dart',
      needle: "ValueKey('lab1000-review')",
    ),
    (
      path: 'lib/screens/admin/lab/lab1000_studio_screen.dart',
      needle: "ValueKey('lab1000-approve')",
    ),
    (
      path: 'lib/screens/admin/lab/lab1000_studio_screen.dart',
      needle: "ValueKey('lab1000-publish')",
    ),
    (
      path: 'lib/screens/admin/lab/lab1000_studio_screen.dart',
      needle: 'openFile',
    ),
    (
      path: 'lib/screens/admin/admin_home_screen.dart',
      needle: 'Lab1000StudioScreen',
    ),
    (
      path: 'lib/screens/navigation/bottom_navigation.dart',
      needle: "label: 'LAB'",
    ),
  ];

  for (var i = 0; i < uiContracts.length; i++) {
    test('LAB-6 Admin Studio UI contract ' + (i + 1).toString(), () {
      final contract = uiContracts[i];
      final source = File(contract.path).readAsStringSync();
      expect(source, contains(contract.needle));
      if (contract.path.contains('bottom_navigation')) {
        expect(source, isNot(contains('Lab1000StudioScreen')));
      }
    });
  }
}
