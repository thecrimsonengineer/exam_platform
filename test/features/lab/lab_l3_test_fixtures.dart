import 'dart:io';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_learner_loader.dart';
import 'package:exam_platform/features/lab/lab_session.dart';
import 'package:exam_platform/features/lab/lab_studio.dart';

const String referenceLabFixturePath =
    'test/fixtures/lab/l3_reference_confined_space_h2s.json';

String referenceLabSource() =>
    File(referenceLabFixturePath).readAsStringSync();

LabPackage referenceLabPackage() =>
    LabPackage.decode(referenceLabSource());

Lab1000StudioService referenceStudioService() =>
    Lab1000StudioService(repository: InMemoryLabPublishedRepository());

class PublishedReferenceLab {
  const PublishedReferenceLab({
    required this.service,
    required this.workspace,
    required this.package,
  });

  final Lab1000StudioService service;
  final LabStudioWorkspace workspace;
  final LabPackage package;
}

Future<PublishedReferenceLab> publishReferenceLab({
  String reviewerId = 'phase_l3_reviewer',
}) async {
  final service = referenceStudioService();
  final draft = service.importJson(referenceLabSource());
  final review = service.requestReview(draft);
  final validated = service.approveReview(
    review,
    reviewerId: reviewerId,
  );
  final published = await service.publish(
    validated,
    publishedAt: DateTime.utc(2026, 9, 19, 1, 0),
  );
  final loader = LabLearnerPackageLoader(repository: service.repository);
  final package = await loader.loadPublished(
    labId: 'confined_space_h2s_simops',
    versionId: 'v1',
  );
  return PublishedReferenceLab(
    service: service,
    workspace: published,
    package: package,
  );
}

class ReferenceRun {
  const ReferenceRun({
    required this.package,
    required this.store,
    required this.engine,
    required this.session,
  });

  final LabPackage package;
  final InMemoryLabSessionStore store;
  final LabSessionEngine engine;
  final LabSession session;
}

Future<ReferenceRun> runReferencePath(
  List<String> optionIds, {
  String sessionId = 'l3_session',
  double? confidence,
}) async {
  final package = referenceLabPackage();
  final store = InMemoryLabSessionStore();
  final engine = LabSessionEngine(store: store);
  var session = await engine.startAttempt(
    package: package,
    sessionId: sessionId,
    userId: 'l3_user',
    mode: LabMode.professional,
    startedAt: DateTime.utc(2026, 9, 19, 1, 0),
  );

  for (var index = 0; index < optionIds.length; index++) {
    session = await engine.commitDecision(
      package: package,
      session: session,
      optionId: optionIds[index],
      responseTimeMs: 500 + index * 125,
      confidence: confidence,
      timestamp: DateTime.utc(2026, 9, 19, 1, index + 1),
    );
  }

  return ReferenceRun(
    package: package,
    store: store,
    engine: engine,
    session: session,
  );
}

Future<ReferenceRun> safeReferenceRun({
  String sessionId = 'safe_session',
  double? confidence,
}) =>
    runReferencePath(
      const <String>['p1', 'g1', 'c1'],
      sessionId: sessionId,
      confidence: confidence,
    );

Future<ReferenceRun> weakReferenceRun({
  String sessionId = 'weak_session',
}) =>
    runReferencePath(
      const <String>['p3', 'g3', 'c3'],
      sessionId: sessionId,
    );

Future<ReferenceRun> criticalReferenceRun({
  String sessionId = 'critical_session',
}) =>
    runReferencePath(
      const <String>['p4', 'e4'],
      sessionId: sessionId,
    );

Future<ReferenceRun> recoveryReferenceRun({
  String sessionId = 'recovery_session',
}) =>
    runReferencePath(
      const <String>['p4', 'e1', 'c2'],
      sessionId: sessionId,
    );
