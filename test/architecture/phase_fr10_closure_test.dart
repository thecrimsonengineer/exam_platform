import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const planPath =
      'docs/firestore/PHASE_FR10_STUDY_CONTENT_DELIVERY_CUTOVER.md';
  const proofWorkflowPath =
      '.github/workflows/phase_fr10_authorized_content_proof.yml';
  const mainWorkflowPath =
      '.github/workflows/phase_fr_firestore_read_reduction.yml';
  const loaderPath = 'lib/services/study_content_loader.dart';
  const deliveryPath =
      'lib/services/study_content/learner_content_package_delivery_service.dart';

  late String plan;
  late String proofWorkflow;
  late String mainWorkflow;
  late String loader;
  late String delivery;

  setUpAll(() {
    plan = File(planPath).readAsStringSync();
    proofWorkflow = File(proofWorkflowPath).readAsStringSync();
    mainWorkflow = File(mainWorkflowPath).readAsStringSync();
    loader = File(loaderPath).readAsStringSync();
    delivery = File(deliveryPath).readAsStringSync();
  });

  test('FR10F keeps the frozen production proof requirements executable', () {
    expect(proofWorkflow, contains('missing-token fail-closed'));
    expect(proofWorkflow, contains('malformed-token fail-closed'));
    expect(proofWorkflow, contains('invalid_firebase_token'));
    expect(proofWorkflow, contains('signedUrlTtlSeconds == 60'));
    expect(proofWorkflow, contains('sha256sum'));
    expect(proofWorkflow, contains('gzip -t'));
    expect(
      proofWorkflow,
      contains('fr10_content_package_production_decode_test.dart'),
    );
    expect(proofWorkflow, contains('package_downloads=1'));
    expect(proofWorkflow, contains('unchangedRequestRequiredAdditionalDownload'));
  });

  test('FR10F protected bytes remain authorization gated', () {
    expect(
      delivery,
      contains('LearnerOnlineAccessRuntime.requireBoundaryFor(userId)'),
    );
    expect(delivery, contains('if (!boundary.isAuthorizedFor(userId))'));
    expect(
      delivery.indexOf('LearnerOnlineAccessRuntime.requireBoundaryFor(userId)'),
      lessThan(delivery.indexOf('SharedPreferences.getInstance()')),
    );
  });

  test('FR10F learner broad StudyContent reads remain fail closed', () {
    expect(
      loader,
      contains('Broad learner StudyContent reads were retired in FR10E'),
    );
    expect(
      loader,
      contains('Broad learner StudyContent domain reads were retired in FR10E'),
    );
    expect(
      loader,
      isNot(contains('repository ?? CloudPublishedContentRepository()')),
    );
  });

  test('FR10F proof never persists learner token or signed URL', () {
    expect(proofWorkflow, contains('sensitiveValuesPersisted:false'));
    expect(
      proofWorkflow,
      isNot(contains('FR9_FIREBASE_LEARNER_ID_TOKEN >>')),
    );
    expect(proofWorkflow, isNot(contains('signed_url >>')));
  });

  test('FR10F closure gate is mandatory in main exact-SHA CI', () {
    expect(mainWorkflow, contains('FR10 final closure architecture gate'));
    expect(
      mainWorkflow,
      contains(
        'flutter test test/architecture/phase_fr10_closure_test.dart',
      ),
    );
    expect(
      mainWorkflow,
      contains(
        'flutter test test/services/study_content/'
        'uid_scoped_content_package_cache_test.dart',
      ),
    );
    expect(
      mainWorkflow,
      contains(
        'flutter test test/services/study_content/'
        'learner_content_package_delivery_service_test.dart',
      ),
    );
  });

  test('FR10F plan preserves exact-green-SHA closure rule', () {
    expect(
      plan,
      contains(
        'Freeze `phase-fr10-closed` only at the exact green evidence SHA.',
      ),
    );
  });
}
