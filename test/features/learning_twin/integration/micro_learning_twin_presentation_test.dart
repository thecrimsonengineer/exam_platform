import 'package:exam_platform/features/learning_twin/integration/micro_learning_twin_presentation.dart';
import 'package:exam_platform/features/learning_twin/ui/learning_twin_asset.dart';
import 'package:exam_platform/models/micro_learning/micro_fact.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MicroFact maps to presentation-only Learning Twin descriptor', () {
    const fact = MicroFact(
      schemaVersion: 1,
      microFactId: 'mf_bridge_001',
      contentVersion: 3,
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
      tags: ['hazardous_energy', 'bridge_test'],
    );

    final presentation =
        const MicroLearningTwinPresentationBridge().forFact(fact);

    expect(presentation.asset, LearningTwinAsset.explain);
    expect(presentation.eventKey, 'microfact:mf_bridge_001:v3');
    expect(
      presentation.semanticLabel,
      'Naveed Learning Guide sharing a CSP insight',
    );
  });
}
