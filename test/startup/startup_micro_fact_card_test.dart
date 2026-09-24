import 'package:exam_platform/models/micro_learning/micro_fact.dart';
import 'package:exam_platform/screens/startup/startup_micro_fact_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MicroFact fact({String? shortVariant}) {
    return MicroFact(
      schemaVersion: 1,
      microFactId: 'mf_card_test_001',
      contentVersion: 1,
      status: 'published',
      category: 'process_safety_insight',
      display: MicroFactDisplay(
        displayText:
            'Process safety barriers should be treated as a system rather than isolated controls.',
        shortVariant: shortVariant,
        estimatedReadSeconds: 8,
      ),
      curriculum: const MicroFactCurriculum(
        scope: 'general',
        domainId: null,
        competencyId: null,
        topicId: null,
        subtopicId: null,
        conceptIds: ['process_safety'],
      ),
      provenance: const MicroFactProvenance(
        sourceRegistryId: 'SRC-01',
        sourceClass: 'government_recommendation',
        sourceTitle: 'Test authority',
        officialUrl: 'https://example.test',
        sourceLocator: 'section',
        editionOrRevision: null,
        sourceSection: null,
        sourcePage: null,
        sourcePublishedAt: null,
        sourceVerifiedAt: '2026-09-23',
        rightsTreatment: 'original_paraphrase',
      ),
      claim: const MicroFactClaim(
        legalStatus: 'recommendation',
        jurisdiction: null,
        numericalClaim: false,
        safetyCritical: false,
        simplificationRisk: 'low',
      ),
      assessment: const MicroFactAssessment(
        sensitivity: 'none',
        linkedQuestionConcepts: [],
      ),
      review: const MicroFactReview(
        technicalStatus: 'pass',
        sourceStatus: 'pass',
        pedagogyStatus: 'pass',
        copyrightStatus: 'pass',
        uiStatus: 'pass',
        humanTechnicalStatus: 'pass',
        reviewedAt: '2026-09-24',
        nextReviewDueAt: '2027-09-24',
      ),
      runtime: const MicroFactRuntime(startupEligible: true),
      supersession: const MicroFactSupersession(
        supersedesMicroFactId: null,
        supersededByMicroFactId: null,
      ),
      tags: const ['process_safety', 'startup_fact'],
    );
  }

  testWidgets('renders short variant in a narrow responsive surface', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: StartupMicroFactCard(
              fact: fact(shortVariant: 'Think in layers of protection.'),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('QUICK INSIGHT'), findsOneWidget);
    expect(find.text('Think in layers of protection.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('falls back to full display text when short variant is absent', (
    tester,
  ) async {
    final value = fact();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: StartupMicroFactCard(fact: value),
        ),
      ),
    );

    expect(find.text(value.display.displayText), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
