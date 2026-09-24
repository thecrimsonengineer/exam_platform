import 'dart:async';

import 'package:exam_platform/models/micro_learning/micro_fact.dart';
import 'package:exam_platform/screens/startup/csp11_startup_screen.dart';
import 'package:exam_platform/screens/startup/startup_motion_policy.dart';
import 'package:exam_platform/services/micro_learning/local_micro_fact_repository.dart';
import 'package:exam_platform/services/micro_learning/startup_micro_fact_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const destinationKey = ValueKey('ml12-destination');

  testWidgets('selected fact appears without delaying startup handoff', (
    tester,
  ) async {
    final service = _FakeStartupMicroFactService(_fact());

    await tester.pumpWidget(
      MaterialApp(
        home: Csp11StartupScreen(
          motionPolicyOverride: StartupMotionPolicy.full,
          microFactService: service,
          microFactRotationOrdinalOverride: 17,
          child: const SizedBox(
            key: destinationKey,
            child: Text('Destination'),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(
      find.byKey(const ValueKey('startup-microfact-card')),
      findsOneWidget,
    );
    expect(find.text('Control energy before work begins.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));

    expect(find.byKey(const ValueKey('csp11-startup-overlay')), findsNothing);
    expect(find.byKey(destinationKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no-fact result leaves existing startup behavior intact', (
    tester,
  ) async {
    final service = _FakeStartupMicroFactService(null);

    await tester.pumpWidget(
      MaterialApp(
        home: Csp11StartupScreen(
          motionPolicyOverride: StartupMotionPolicy.full,
          microFactService: service,
          child: const SizedBox(
            key: destinationKey,
            child: Text('Destination'),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.byKey(const ValueKey('startup-microfact-card')), findsNothing);
    expect(find.byKey(const ValueKey('csp11-startup-overlay')), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));

    expect(find.byKey(const ValueKey('csp11-startup-overlay')), findsNothing);
    expect(find.byKey(destinationKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unfinished MicroFact load cannot extend startup duration', (
    tester,
  ) async {
    final pendingAsset = Completer<String>();
    final service = StartupMicroFactService(
      repository: LocalMicroFactRepository(
        assetLoader: (_) => pendingAsset.future,
      ),
      clock: () => DateTime(2026, 9, 24),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Csp11StartupScreen(
          motionPolicyOverride: StartupMotionPolicy.full,
          microFactService: service,
          child: const SizedBox(
            key: destinationKey,
            child: Text('Destination'),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.byKey(const ValueKey('csp11-startup-overlay')), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));

    expect(find.byKey(const ValueKey('csp11-startup-overlay')), findsNothing);
    expect(find.byKey(destinationKey), findsOneWidget);
    expect(find.byKey(const ValueKey('startup-microfact-card')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _FakeStartupMicroFactService extends StartupMicroFactService {
  _FakeStartupMicroFactService(this.value);

  final MicroFact? value;

  @override
  Future<MicroFact?> load({
    int? rotationOrdinal,
    List<String> recentMicroFactIds = const <String>[],
    Set<String> activeAssessmentConceptIds = const <String>{},
  }) async {
    return value;
  }
}

MicroFact _fact() {
  return const MicroFact(
    schemaVersion: 1,
    microFactId: 'mf_ml12_test_001',
    contentVersion: 1,
    status: 'published',
    category: 'safety_insight',
    display: MicroFactDisplay(
      displayText: 'Control hazardous energy before work begins.',
      shortVariant: 'Control energy before work begins.',
      estimatedReadSeconds: 6,
    ),
    curriculum: MicroFactCurriculum(
      scope: 'general',
      domainId: null,
      competencyId: null,
      topicId: null,
      subtopicId: null,
      conceptIds: ['hazardous_energy'],
    ),
    provenance: MicroFactProvenance(
      sourceRegistryId: 'SRC-01',
      sourceClass: 'federal_regulation',
      sourceTitle: 'OSHA hazardous energy',
      officialUrl:
          'https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.147',
      sourceLocator: '29 CFR 1910.147',
      editionOrRevision: '29 CFR 1910.147',
      sourceSection: '1910.147',
      sourcePage: null,
      sourcePublishedAt: null,
      sourceVerifiedAt: '2026-09-23',
      rightsTreatment: 'original_paraphrase',
    ),
    claim: MicroFactClaim(
      legalStatus: 'binding_requirement',
      jurisdiction: 'US Federal OSHA',
      numericalClaim: false,
      safetyCritical: false,
      simplificationRisk: 'low',
    ),
    assessment: MicroFactAssessment(
      sensitivity: 'none',
      linkedQuestionConcepts: [],
    ),
    review: MicroFactReview(
      technicalStatus: 'pass',
      sourceStatus: 'pass',
      pedagogyStatus: 'pass',
      copyrightStatus: 'pass',
      uiStatus: 'pass',
      humanTechnicalStatus: 'pass',
      reviewedAt: '2026-09-24',
      nextReviewDueAt: '2027-09-24',
    ),
    runtime: MicroFactRuntime(startupEligible: true),
    supersession: MicroFactSupersession(
      supersedesMicroFactId: null,
      supersededByMicroFactId: null,
    ),
    tags: ['hazardous_energy', 'startup_fact'],
  );
}
