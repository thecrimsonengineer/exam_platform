import 'package:exam_platform/features/learning_twin/ui/learning_twin_avatar.dart';
import 'package:exam_platform/models/micro_learning/micro_fact.dart';
import 'package:exam_platform/screens/startup/startup_micro_fact_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('startup MicroFact card renders canonical LearningTwinAvatar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: StartupMicroFactCard(fact: _fact()),
        ),
      ),
    );

    expect(find.byType(LearningTwinAvatar), findsOneWidget);
    expect(
      find.byKey(const ValueKey('microfact:mf_integration_001:v1')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.lightbulb_outline_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

MicroFact _fact() {
  return const MicroFact(
    schemaVersion: 1,
    microFactId: 'mf_integration_001',
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
      sourceTitle: 'Test source',
      officialUrl: 'https://example.test',
      sourceLocator: 'section',
      editionOrRevision: null,
      sourceSection: null,
      sourcePage: null,
      sourcePublishedAt: null,
      sourceVerifiedAt: '2026-09-23',
      rightsTreatment: 'original_paraphrase',
    ),
    claim: MicroFactClaim(
      legalStatus: 'recommendation',
      jurisdiction: null,
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
    tags: ['hazardous_energy', 'integration_test'],
  );
}
