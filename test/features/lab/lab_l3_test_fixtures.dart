import 'dart:io';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_session.dart';
import 'package:exam_platform/features/lab/lab_studio.dart';

String l3ReferenceSource() => File(
  'test/fixtures/lab/l3_reference_confined_space_h2s.json',
).readAsStringSync();

LabPackage l3ReferenceDraftPackage() => LabPackage.decode(l3ReferenceSource());

Future<
  ({
    Lab1000StudioService service,
    LabStudioWorkspace published,
    LabPackage package,
  })
>
publishL3Reference() async {
  final service = Lab1000StudioService(
    repository: InMemoryLabPublishedRepository(),
  );
  final draft = service.importJson(l3ReferenceSource());
  final review = service.requestReview(draft);
  final validated = service.approveReview(
    review,
    reviewerId: 'l3_reference_reviewer',
  );
  final published = await service.publish(
    validated,
    publishedAt: DateTime.utc(2026, 9, 19, 1),
  );
  return (
    service: service,
    published: published,
    package: LabPackage.decode(published.publishedVersion!.publishedJson),
  );
}

Future<LabSession> runL3Route({
  required LabPackage package,
  required List<String> optionIds,
  String sessionId = 'l3_session',
  String userId = 'l3_user',
  int responseTimeBaseMs = 250,
  double? confidence,
}) async {
  final store = InMemoryLabSessionStore();
  final engine = LabSessionEngine(store: store);
  var session = await engine.startAttempt(
    package: package,
    sessionId: sessionId,
    userId: userId,
    mode: LabMode.professional,
    startedAt: DateTime.utc(2026, 9, 19),
  );

  for (var i = 0; i < optionIds.length; i++) {
    session = await engine.commitDecision(
      package: package,
      session: session,
      optionId: optionIds[i],
      responseTimeMs: responseTimeBaseMs + i,
      confidence: confidence,
      timestamp: DateTime.utc(2026, 9, 19, 0, i + 1),
    );
  }
  return session;
}

Future<LabSession> runL3SafeRoute(
  LabPackage package, {
  String sessionId = 'safe_session',
}) => runL3Route(
  package: package,
  optionIds: const <String>['p1', 'g1', 'c1'],
  sessionId: sessionId,
);

Future<LabSession> runL3WeakRoute(
  LabPackage package, {
  String sessionId = 'weak_session',
}) => runL3Route(
  package: package,
  optionIds: const <String>['p3', 'g3', 'c3'],
  sessionId: sessionId,
);

Future<LabSession> runL3CriticalFailureRoute(
  LabPackage package, {
  String sessionId = 'critical_session',
}) => runL3Route(
  package: package,
  optionIds: const <String>['p4', 'e4'],
  sessionId: sessionId,
);

Future<LabSession> runL3RecoveryRoute(
  LabPackage package, {
  String sessionId = 'recovery_session',
}) => runL3Route(
  package: package,
  optionIds: const <String>['p4', 'e1', 'c2'],
  sessionId: sessionId,
);

Future<LabSession> runL3ContainedRoute(
  LabPackage package, {
  String sessionId = 'contained_session',
}) => runL3Route(
  package: package,
  optionIds: const <String>['p1', 'g1', 'c3'],
  sessionId: sessionId,
);

Future<LabSession> runL3MajorRoute(
  LabPackage package, {
  String sessionId = 'major_session',
}) => runL3Route(
  package: package,
  optionIds: const <String>['p4', 'e1', 'c4'],
  sessionId: sessionId,
);
