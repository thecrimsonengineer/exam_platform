import 'dart:convert';

import 'package:exam_platform/services/micro_learning/local_micro_fact_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> fact(int index) => <String, dynamic>{
    'schemaVersion': 1,
    'microFactId': 'mf_test_fact_${index.toString().padLeft(3, '0')}',
    'contentVersion': 1,
    'status': 'published',
    'category': 'safety_insight',
    'display': {
      'displayText':
          'A startup-safe test fact about hazardous-energy control number $index.',
      'shortVariant': 'Hazardous-energy control test fact $index.',
      'estimatedReadSeconds': 8,
    },
    'curriculum': {
      'scope': 'general',
      'domainId': null,
      'competencyId': null,
      'topicId': null,
      'subtopicId': null,
      'conceptIds': ['hazardous_energy'],
    },
    'provenance': {
      'sourceRegistryId': 'SRC-01',
      'sourceClass': 'federal_regulation',
      'sourceTitle': 'OSHA hazardous-energy test source',
      'officialUrl':
          'https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.147',
      'sourceLocator': '29 CFR 1910.147',
      'editionOrRevision': '29 CFR 1910.147',
      'sourceSection': '1910.147',
      'sourcePage': null,
      'sourcePublishedAt': null,
      'sourceVerifiedAt': '2026-09-23',
      'rightsTreatment': 'original_paraphrase',
    },
    'claim': {
      'legalStatus': 'binding_requirement',
      'jurisdiction': 'US Federal OSHA',
      'numericalClaim': false,
      'safetyCritical': false,
      'simplificationRisk': 'low',
    },
    'assessment': {
      'sensitivity': 'none',
      'linkedQuestionConcepts': <String>[],
    },
    'review': {
      'technicalStatus': 'pass',
      'sourceStatus': 'pass',
      'pedagogyStatus': 'pass',
      'copyrightStatus': 'pass',
      'uiStatus': 'pass',
      'humanTechnicalStatus': 'pass',
      'reviewedAt': '2026-09-24',
      'nextReviewDueAt': '2027-09-24',
    },
    'runtime': {'startupEligible': true},
    'supersession': {
      'supersedesMicroFactId': null,
      'supersededByMicroFactId': null,
    },
    'tags': ['hazardous_energy', 'lockout_tagout'],
  };

  String bundle({void Function(List<Map<String, dynamic>> facts)? mutate}) {
    final facts = List<Map<String, dynamic>>.generate(
      120,
      (index) => fact(index + 1),
    );
    mutate?.call(facts);
    return jsonEncode({
      'schemaVersion': 1,
      'bundleId': LocalMicroFactRepository.requiredBundleId,
      'bundleVersion': LocalMicroFactRepository.requiredBundleVersion,
      'generatedAt': '2026-09-24',
      'sourcePublicationSha':
          LocalMicroFactRepository.requiredSourcePublicationSha,
      'sourceProductionManifest':
          'content/micro_learning/ml9f_production_manifest_v1.json',
      'factCount': 120,
      'facts': facts,
    });
  }

  test('loads all current published startup-eligible facts locally', () async {
    var calls = 0;
    final repository = LocalMicroFactRepository(
      assetLoader: (path) async {
        calls++;
        expect(path, LocalMicroFactRepository.bundleAssetPath);
        return bundle();
      },
    );

    final snapshot = await repository.load(
      now: DateTime(2026, 9, 24),
    );

    expect(calls, 1);
    expect(snapshot.bundleValid, isTrue);
    expect(snapshot.bundleFactCount, 120);
    expect(snapshot.eligibleFacts, hasLength(120));
    expect(snapshot.staleFactCount, 0);
    expect(snapshot.diagnostics, isEmpty);
  });

  test('excludes review-due facts without invalidating the bundle', () async {
    final repository = LocalMicroFactRepository(
      assetLoader: (_) async => bundle(
        mutate: (facts) {
          final review = Map<String, dynamic>.from(
            facts.first['review'] as Map,
          );
          review['reviewedAt'] = '2026-09-22';
          review['reviewedAt'] = '2026-09-01';
          review['nextReviewDueAt'] = '2026-09-23';
          facts.first['review'] = review;
          final provenance = Map<String, dynamic>.from(
            facts.first['provenance'] as Map,
          );
          provenance['sourceVerifiedAt'] = '2026-09-22';
          facts.first['provenance'] = provenance;
        },
      ),
    );

    final snapshot = await repository.load(
      now: DateTime(2026, 9, 24),
    );

    expect(snapshot.bundleValid, isTrue);
    expect(snapshot.eligibleFacts, hasLength(119));
    expect(snapshot.staleFactCount, 1);
  });

  test('fails closed when a bundled fact is not published', () async {
    final repository = LocalMicroFactRepository(
      assetLoader: (_) async => bundle(
        mutate: (facts) {
          facts.first['status'] = 'validated';
          final runtime = Map<String, dynamic>.from(
            facts.first['runtime'] as Map,
          );
          runtime['startupEligible'] = false;
          facts.first['runtime'] = runtime;
        },
      ),
    );

    final snapshot = await repository.load(
      now: DateTime(2026, 9, 24),
    );

    expect(snapshot.bundleValid, isFalse);
    expect(snapshot.eligibleFacts, isEmpty);
    expect(
      snapshot.diagnostics.any(
        (entry) => entry.startsWith('ML10_FACT_NOT_PUBLISHED'),
      ),
      isTrue,
    );
  });

  test('asset failure collapses to a no-fact snapshot', () async {
    final repository = LocalMicroFactRepository(
      assetLoader: (_) async => throw StateError('asset unavailable'),
    );

    final snapshot = await repository.load(
      now: DateTime(2026, 9, 24),
    );

    expect(snapshot.bundleValid, isFalse);
    expect(snapshot.eligibleFacts, isEmpty);
    expect(snapshot.diagnostics, ['ML10_BUNDLE_LOAD_FAILED']);
  });
}
