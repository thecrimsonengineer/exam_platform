import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_l4n_certificate.dart';
import 'package:exam_platform/features/lab/lab_publish_evidence_validator.dart';
import 'package:exam_platform/features/lab/lab_reachable_route_explorer.dart';
import 'package:flutter_test/flutter_test.dart';

LabPackage _referenceV2() => LabPackage.decode(
  File('content/lab_reference_confined_space_h2s_v2.json').readAsStringSync(),
);

LabPackage _l2() => LabPackage.decode(
  File('test/fixtures/lab/l2_valid_lab.json').readAsStringSync(),
);

Map<String, Object?> _referenceRoot() {
  final decoded = jsonDecode(
    File(
      'content/lab_reference_confined_space_h2s_v2.json',
    ).readAsStringSync(),
  );
  return (decoded as Map).cast<String, Object?>();
}

void main() {
  const explorer = LabReachableRouteExplorer();
  const validator = LabPublishEvidenceValidator();

  test('L4N validates debrief and Learning Twin evidence on every reference route', () {
    final package = _referenceV2();
    final routes = explorer.explore(package);
    final report = validator.validate(
      package: package,
      routeExplorationReport: routes,
    );

    expect(routes.isExhaustive, isTrue);
    expect(routes.selectedRouteCount, 196);
    expect(report.selectedRouteCount, 196);
    expect(report.debriefCount, 196);
    expect(report.decisionEventCount, 848);
    expect(report.learningEvidenceCount, 848);
    expect(report.alternateTimelineReferencesValid, isTrue);
    expect(report.recoverySignalReferencesValid, isTrue);
    expect(report.privacyBoundaryValid, isTrue);
    expect(report.routeEvidenceValid, isTrue);
    expect(report.deterministic, isTrue);
    expect(report.issues, isEmpty);
    expect(report.isValid, isTrue);
  });

  test('L4N validates only the deterministic L4M representative matrix', () {
    final package = _referenceV2();
    final routes = explorer.explore(package, routeBudget: 32);
    final report = validator.validate(
      package: package,
      routeExplorationReport: routes,
    );

    expect(routes.isRepresentative, isTrue);
    expect(routes.selectedRouteCount, 32);
    expect(report.selectedRouteCount, 32);
    expect(report.debriefCount, 32);
    expect(report.decisionEventCount, greaterThan(0));
    expect(report.learningEvidenceCount, report.decisionEventCount);
    expect(report.isValid, isTrue);
  });

  test('L4N keeps minimal legacy LAB authoring compatible', () {
    final package = _l2();
    final routes = explorer.explore(package);
    final report = validator.validate(
      package: package,
      routeExplorationReport: routes,
    );

    expect(package.debrief, isEmpty);
    expect(package.learningSignals, isEmpty);
    expect(report.alternateTimelineReferencesValid, isTrue);
    expect(report.recoverySignalReferencesValid, isTrue);
    expect(report.privacyBoundaryValid, isTrue);
    expect(report.isValid, isTrue);
  });

  test('L4N blocks an unknown debrief Decision Node reference', () {
    final root = _referenceRoot();
    final debrief = (root['debrief'] as Map).cast<String, Object?>();
    final alternates = debrief['alternateTimelineOptions'] as List;
    final first = (alternates.first as Map).cast<String, Object?>();
    first['nodeId'] = 'ghost_decision';

    final package = LabPackage.fromJson(root);
    final report = validator.validate(
      package: package,
      routeExplorationReport: explorer.explore(package),
    );

    expect(report.alternateTimelineReferencesValid, isFalse);
    expect(report.isValid, isFalse);
    expect(
      report.issues.any(
        (issue) => issue.contains('unknown Decision Node or empty option'),
      ),
      isTrue,
    );
  });

  test('L4N blocks an unknown debrief alternate option', () {
    final root = _referenceRoot();
    final debrief = (root['debrief'] as Map).cast<String, Object?>();
    final alternates = debrief['alternateTimelineOptions'] as List;
    final first = (alternates.first as Map).cast<String, Object?>();
    first['alternateOptionId'] = 'ghost_option';

    final package = LabPackage.fromJson(root);
    final report = validator.validate(
      package: package,
      routeExplorationReport: explorer.explore(package),
    );

    expect(report.alternateTimelineReferencesValid, isFalse);
    expect(report.isValid, isFalse);
    expect(
      report.issues.any(
        (issue) => issue.contains('unknown option permit_decision::ghost_option'),
      ),
      isTrue,
    );
  });

  test('L4N blocks an unknown recovery signal Decision Node', () {
    final root = _referenceRoot();
    final signals = (root['learningSignals'] as Map).cast<String, Object?>();
    signals['recoveryDecisionNodeIds'] = <String>[
      'emergency_decision',
      'ghost_recovery',
    ];

    final package = LabPackage.fromJson(root);
    final report = validator.validate(
      package: package,
      routeExplorationReport: explorer.explore(package),
    );

    expect(report.recoverySignalReferencesValid, isFalse);
    expect(report.isValid, isFalse);
    expect(
      report.issues.any((issue) => issue.contains('ghost_recovery')),
      isTrue,
    );
  });

  test('L4N blocks an unsafe Learning Twin privacy declaration', () {
    final root = _referenceRoot();
    final signals = (root['learningSignals'] as Map).cast<String, Object?>();
    signals['privacy'] = 'full_session_state';

    final package = LabPackage.fromJson(root);
    final report = validator.validate(
      package: package,
      routeExplorationReport: explorer.explore(package),
    );

    expect(report.privacyBoundaryValid, isFalse);
    expect(report.isValid, isFalse);
    expect(
      report.issues,
      contains(
        'L4N Learning Twin privacy must remain sanitized_decision_evidence_only.',
      ),
    );
  });

  test('L4N fails closed when L4M route exploration is invalid', () {
    final package = _referenceV2();
    final invalidRoutes = explorer.explore(package, routeBudget: 2);
    final report = validator.validate(
      package: package,
      routeExplorationReport: invalidRoutes,
    );

    expect(invalidRoutes.isValid, isFalse);
    expect(report.routeEvidenceValid, isFalse);
    expect(report.deterministic, isFalse);
    expect(report.isValid, isFalse);
    expect(
      report.issues,
      contains(
        'L4N publish evidence requires a valid L4M route exploration report.',
      ),
    );
  });


  test('L4N certificate round-trips exact route and publish evidence', () {
    final package = _referenceV2();
    final routes = explorer.explore(package, routeBudget: 32);
    final report = validator.validate(
      package: package,
      routeExplorationReport: routes,
    );
    final certificate = LabL4nPublishEvidenceCertificate.fromReport(
      package: package,
      report: report,
      validationAuthority: 'DQG300-LAB-AUTO',
      validatedAt: DateTime.utc(2026, 9, 19, 8),
    );

    final encoded = certificate.encode();
    final restored = LabL4nPublishEvidenceCertificate.decode(encoded);

    expect(restored.labId, package.metadata.id);
    expect(restored.versionId, package.metadata.versionId);
    expect(restored.validationAuthority, 'DQG300-LAB-AUTO');
    expect(restored.validatedAtIso, '2026-09-19T08:00:00.000Z');
    expect(restored.routeExplorationEvidence['isValid'], isTrue);
    expect(restored.publishEvidence['isValid'], isTrue);
    expect(restored.isPass, isTrue);
    expect(restored.encode(), encoded);
  });

  test('L4N certificate refuses invalid publish evidence', () {
    final package = _referenceV2();
    final invalidRoutes = explorer.explore(package, routeBudget: 2);
    final invalidReport = validator.validate(
      package: package,
      routeExplorationReport: invalidRoutes,
    );

    expect(invalidReport.isValid, isFalse);
    expect(
      () => LabL4nPublishEvidenceCertificate.fromReport(
        package: package,
        report: invalidReport,
        validationAuthority: 'DQG300-LAB-AUTO',
        validatedAt: DateTime.utc(2026, 9, 19, 8),
      ),
      throwsA(isA<LabContractException>()),
    );
  });

  test('L4N publish evidence is byte-stable across repeated validation', () {
    final package = _referenceV2();
    final routes = explorer.explore(package, routeBudget: 32);
    final first = validator.validate(
      package: package,
      routeExplorationReport: routes,
    );
    final second = validator.validate(
      package: package,
      routeExplorationReport: routes,
    );

    expect(first.fingerprint, second.fingerprint);
    expect(first.isValid, isTrue);
    expect(second.isValid, isTrue);
    expect(
      jsonEncode(first.toEvidenceJson()),
      jsonEncode(second.toEvidenceJson()),
    );
  });
}
