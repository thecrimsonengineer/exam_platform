import 'package:exam_platform/models/micro_learning/micro_fact.dart';
import 'package:exam_platform/services/micro_learning/micro_fact_selector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const selector = MicroFactSelector();

  MicroFact fact(
    String id, {
    String category = 'safety_insight',
    String source = 'SRC-01',
    List<String> concepts = const ['concept_a'],
    String assessmentSensitivity = 'none',
    List<String> linkedAssessmentConcepts = const [],
    String status = 'published',
    bool startupEligible = true,
  }) {
    return MicroFact(
      schemaVersion: 1,
      microFactId: id,
      contentVersion: 1,
      status: status,
      category: category,
      display: const MicroFactDisplay(
        displayText: 'A deterministic startup learning fact.',
        shortVariant: 'Deterministic startup fact.',
        estimatedReadSeconds: 6,
      ),
      curriculum: MicroFactCurriculum(
        scope: 'general',
        domainId: null,
        competencyId: null,
        topicId: null,
        subtopicId: null,
        conceptIds: concepts,
      ),
      provenance: MicroFactProvenance(
        sourceRegistryId: source,
        sourceClass: 'government_recommendation',
        sourceTitle: 'Test source',
        officialUrl: 'https://example.test/source',
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
      assessment: MicroFactAssessment(
        sensitivity: assessmentSensitivity,
        linkedQuestionConcepts: linkedAssessmentConcepts,
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
      runtime: MicroFactRuntime(startupEligible: startupEligible),
      supersession: const MicroFactSupersession(
        supersedesMicroFactId: null,
        supersededByMicroFactId: null,
      ),
      tags: const ['startup_fact', 'selector_test'],
    );
  }

  List<MicroFact> corpus(int count) {
    const categories = [
      'safety_insight',
      'ih_insight',
      'process_safety_insight',
      'fire_electrical_insight',
    ];
    const sources = ['SRC-01', 'SRC-02', 'SRC-03'];

    return List<MicroFact>.generate(count, (index) {
      return fact(
        'mf_selector_${(index + 1).toString().padLeft(3, '0')}',
        category: categories[index % categories.length],
        source: sources[index % sources.length],
        concepts: ['concept_${index % 6}'],
      );
    });
  }

  test('same corpus and context always select the same fact', () {
    final facts = corpus(24);
    const context = MicroFactSelectionContext(rotationOrdinal: 7);

    final first = selector.select(facts, context: context);
    final second = selector.select(facts, context: context);

    expect(first.fact?.microFactId, second.fact?.microFactId);
    expect(first.diagnostics, second.diagnostics);
  });

  test('rotation ordinals cover every candidate exactly once per cycle', () {
    final facts = corpus(24);
    final selected = <String>{};

    for (var ordinal = 0; ordinal < facts.length; ordinal++) {
      final result = selector.select(
        facts,
        context: MicroFactSelectionContext(rotationOrdinal: ordinal),
      );
      expect(result.hasFact, isTrue);
      selected.add(result.fact!.microFactId);
    }

    expect(selected, hasLength(facts.length));
  });

  test('recent fact IDs are suppressed when alternatives exist', () {
    final facts = corpus(8);
    final baseline = selector.select(facts).fact!;

    final result = selector.select(
      facts,
      context: MicroFactSelectionContext(
        recentMicroFactIds: [baseline.microFactId],
      ),
    );

    expect(result.fact, isNotNull);
    expect(result.fact!.microFactId, isNot(baseline.microFactId));
    expect(result.repetitionExcludedCount, 1);
  });

  test('recent category and source are deprioritized deterministically', () {
    final recent = fact(
      'mf_recent_001',
      category: 'safety_insight',
      source: 'SRC-01',
      concepts: const ['shared_concept'],
    );
    final sameCategory = fact(
      'mf_candidate_001',
      category: 'safety_insight',
      source: 'SRC-02',
    );
    final sameSource = fact(
      'mf_candidate_002',
      category: 'ih_insight',
      source: 'SRC-01',
    );
    final diverse = fact(
      'mf_candidate_003',
      category: 'process_safety_insight',
      source: 'SRC-03',
    );

    final result = selector.select(
      [recent, sameCategory, sameSource, diverse],
      context: const MicroFactSelectionContext(
        recentMicroFactIds: ['mf_recent_001'],
      ),
    );

    expect(result.fact?.microFactId, 'mf_candidate_003');
  });

  test('linked assessment concepts fail closed for sensitive facts', () {
    final blocked = fact(
      'mf_sensitive_001',
      assessmentSensitivity: 'high',
      linkedAssessmentConcepts: const ['hot_work'],
    );
    final safe = fact(
      'mf_safe_001',
      category: 'ih_insight',
      source: 'SRC-02',
      concepts: const ['noise'],
    );

    final result = selector.select(
      [blocked, safe],
      context: const MicroFactSelectionContext(
        activeAssessmentConceptIds: {'hot_work'},
      ),
    );

    expect(result.fact?.microFactId, 'mf_safe_001');
    expect(result.assessmentExcludedCount, 1);
  });

  test('all assessment-overlapping sensitive facts yield no fact', () {
    final first = fact(
      'mf_sensitive_001',
      assessmentSensitivity: 'block_during_linked_assessment',
      linkedAssessmentConcepts: const ['confined_space'],
    );
    final second = fact(
      'mf_sensitive_002',
      assessmentSensitivity: 'medium',
      linkedAssessmentConcepts: const ['confined_space'],
    );

    final result = selector.select(
      [first, second],
      context: const MicroFactSelectionContext(
        activeAssessmentConceptIds: {'confined_space'},
      ),
    );

    expect(result.fact, isNull);
    expect(result.diagnostics, contains('ML11_NO_ASSESSMENT_SAFE_FACT'));
  });

  test('recency exclusion falls back only when every fact is recent', () {
    final facts = corpus(3);

    final result = selector.select(
      facts,
      context: MicroFactSelectionContext(
        recentMicroFactIds: facts.map((fact) => fact.microFactId).toList(),
      ),
    );

    expect(result.fact, isNotNull);
    expect(result.diagnostics, contains('ML11_RECENCY_FALLBACK'));
  });

  test('non-published or non-startup facts never enter selection', () {
    final validated = fact(
      'mf_invalid_001',
      status: 'validated',
      startupEligible: false,
    );
    final publishedDisabled = fact('mf_invalid_002', startupEligible: false);

    final result = selector.select([validated, publishedDisabled]);

    expect(result.fact, isNull);
    expect(result.runtimeEligibleCount, 0);
    expect(result.diagnostics, contains('ML11_NO_RUNTIME_ELIGIBLE_FACT'));
  });
}
