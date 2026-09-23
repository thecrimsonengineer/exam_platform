import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_dqg300.dart';
import 'package:exam_platform/features/lab/lab_learner_presentation.dart';
import 'package:exam_platform/features/lab/lab_scenario_population_manifest.dart';
import 'package:flutter_test/flutter_test.dart';

import '../quality_validator_contract/dqg300/_support/dqg300_fixture.dart';

LabPackage _technicalPackage() {
  final source =
      File('test/fixtures/lab/l2_valid_lab.json').readAsStringSync();
  return LabPackage.fromJson(
    (jsonDecode(source) as Map).cast<String, Object?>(),
  );
}

Map<String, Object?> _manifestJson() => <String, Object?>{
  'schemaVersion': kLabScenarioPopulationManifestSchemaVersion,
  'manifestId': 'lsp_q9_population',
  'entries': <Object?>[
    <String, Object?>{
      'entryId': 'l2_entry',
      'labId': 'l2_lab',
      'versionId': 'v1',
      'technicalLabPath': 'content/lab_population/l2_lab/v1/technical.json',
      'dqg300EvidencePath':
          'content/lab_population/l2_lab/v1/dqg300_evidence.json',
      'learnerPresentationPath':
          'content/lab_population/l2_lab/v1/learner_presentation.json',
    },
  ],
};

Map<String, Object?> _presentationJson({
  String labId = 'l2_lab',
  String versionId = 'v1',
}) {
  return <String, Object?>{
    'schemaVersion': kLabPresentationSchemaVersion,
    'labId': labId,
    'versionId': versionId,
    'presentation': <String, Object?>{
      'summary': 'A concise learner-facing scenario summary.',
      'estimatedTime': '8-12 min',
      'decisionCountLabel': '2 decisions',
      'role': 'Act as the safety professional responsible for the operation.',
      'situation': 'The operation is active and conditions are changing.',
      'objective': 'Control the risk and reach a defensible safe outcome.',
      'peopleInvolved': <String>['Supervisor', 'Technician'],
      'knownFacts': <String>['The permit is available for review.'],
      'focusTags': <String>['isolation', 'risk control'],
    },
    'evidencePresentation': <String, Object?>{
      'permit': <String, Object?>{
        'title': 'Work permit',
        'summary': 'Current permit information.',
        'details': 'Review the permit details before deciding.',
      },
    },
    'decisionPresentation': <String, Object?>{
      'decision_one': <String, Object?>{'title': 'Immediate control'},
      'decision_two': <String, Object?>{'title': 'Close-out decision'},
    },
    'consequencePresentation': <String, Object?>{
      for (final id in <String>[
        'c_safe',
        'c_defensible',
        'c_weak',
        'c_critical',
        'c_end_best',
        'c_end_defensible',
        'c_end_weak',
        'c_end_critical',
      ])
        id: <String, Object?>{
          'observable': 'The learner observes the result of ' + id + '.',
          'guidedInsight':
              'Consider what this outcome means for risk control.',
        },
    },
    'endingPresentation': <String, Object?>{
      'safe_end': <String, Object?>{
        'title': 'Safe completion',
        'narrative': 'The operation reaches a controlled conclusion.',
        'keyTurningPoint': 'The critical decisions controlled the final risk.',
      },
    },
  };
}

LabDqg300EvidenceBundle _dqgBundle(
  LabPackage technical, {
  String? labId,
  String? versionId,
  String? omitNodeId,
  String? staleNodeId,
  bool addUnexpected = false,
}) {
  final decisions = <LabDqg300DecisionEvidence>[
    for (final node in technical.nodes.whereType<LabDecisionNode>())
      if (node.id != omitNodeId)
        LabDqg300DecisionEvidence(
          nodeId: node.id,
          decisionSignature: node.id == staleNodeId
              ? 'stale-signature'
              : LabDqg300Validator.decisionSignature(node),
          evidence: perfectDqg300Evidence(),
        ),
  ];

  if (addUnexpected) {
    decisions.add(
      LabDqg300DecisionEvidence(
        nodeId: 'decision_unknown',
        decisionSignature: 'unexpected-signature',
        evidence: perfectDqg300Evidence(),
      ),
    );
  }

  return LabDqg300EvidenceBundle(
    labId: labId ?? technical.metadata.id,
    versionId: versionId ?? technical.metadata.versionId,
    decisions: decisions,
  );
}

void main() {
  const validator = LabScenarioPopulationBindingValidator();

  test('Q9 parses a strict manifest and resolves one LAB/version entry', () {
    final manifest = LabScenarioPopulationManifest.fromJson(_manifestJson());

    expect(manifest.manifestId, 'lsp_q9_population');
    expect(manifest.entries, hasLength(1));

    final entry = manifest.requireEntry('l2_entry');
    expect(entry.identityKey, 'l2_lab@v1');
    expect(
      manifest.entryFor(labId: 'l2_lab', versionId: 'v1'),
      same(entry),
    );
  });

  test('Q9 rejects unknown manifest and entry fields', () {
    final root = _manifestJson();
    root['technicalTruth'] = 'forbidden';

    expect(
      () => LabScenarioPopulationManifest.fromJson(root),
      throwsA(isA<LabScenarioPopulationManifestException>()),
    );

    final nested = _manifestJson();
    final entry = ((nested['entries'] as List).first as Map)
        .cast<String, Object?>();
    entry['bestAnswer'] = 2;

    expect(
      () => LabScenarioPopulationManifest.fromJson(nested),
      throwsA(isA<LabScenarioPopulationManifestException>()),
    );
  });

  test('Q9 rejects duplicate identity bindings and shared artifact paths', () {
    final duplicateIdentity = _manifestJson();
    final entries = (duplicateIdentity['entries'] as List).cast<Object?>();
    entries.add(<String, Object?>{
      'entryId': 'l2_entry_2',
      'labId': 'l2_lab',
      'versionId': 'v1',
      'technicalLabPath': 'content/other/technical.json',
      'dqg300EvidencePath': 'content/other/dqg300.json',
      'learnerPresentationPath': 'content/other/presentation.json',
    });

    expect(
      () => LabScenarioPopulationManifest.fromJson(duplicateIdentity),
      throwsA(isA<LabScenarioPopulationManifestException>()),
    );

    final sharedPath = _manifestJson();
    final sharedEntries = (sharedPath['entries'] as List).cast<Object?>();
    sharedEntries.add(<String, Object?>{
      'entryId': 'other_entry',
      'labId': 'other_lab',
      'versionId': 'v1',
      'technicalLabPath': 'content/lab_population/l2_lab/v1/technical.json',
      'dqg300EvidencePath': 'content/other/dqg300.json',
      'learnerPresentationPath': 'content/other/presentation.json',
    });

    expect(
      () => LabScenarioPopulationManifest.fromJson(sharedPath),
      throwsA(isA<LabScenarioPopulationManifestException>()),
    );
  });

  test('Q9 rejects traversal, URL syntax and non-JSON artifact paths', () {
    for (final invalidPath in <String>[
      '../technical.json',
      'https://example.com/technical.json',
      'content/lab/technical.yaml',
    ]) {
      final json = _manifestJson();
      final entry = ((json['entries'] as List).first as Map)
          .cast<String, Object?>();
      entry['technicalLabPath'] = invalidPath;

      expect(
        () => LabScenarioPopulationManifest.fromJson(json),
        throwsA(isA<LabScenarioPopulationManifestException>()),
      );
    }
  });

  test('Q9 accepts an exact three-artifact population binding', () {
    final technical = _technicalPackage();
    final manifest = LabScenarioPopulationManifest.fromJson(_manifestJson());
    final presentation = LabLearnerPresentationPackage.fromJson(
      _presentationJson(),
    );

    final report = validator.validate(
      entry: manifest.requireEntry('l2_entry'),
      technicalPackage: technical,
      dqg300Evidence: _dqgBundle(technical),
      presentationPackage: presentation,
    );

    expect(report.isValid, isTrue);
    expect(report.technicalIdentityMatches, isTrue);
    expect(report.dqgIdentityMatches, isTrue);
    expect(report.presentationIdentityMatches, isTrue);
    expect(report.missingDqgDecisionIds, isEmpty);
    expect(report.unexpectedDqgDecisionIds, isEmpty);
    expect(report.staleDqgDecisionIds, isEmpty);
    expect(report.presentationReport.isValid, isTrue);
  });

  test('Q9 fails closed when the DQG bundle identity is not pinned', () {
    final technical = _technicalPackage();
    final manifest = LabScenarioPopulationManifest.fromJson(_manifestJson());

    final report = validator.validate(
      entry: manifest.requireEntry('l2_entry'),
      technicalPackage: technical,
      dqg300Evidence: _dqgBundle(technical, versionId: 'v2'),
      presentationPackage: LabLearnerPresentationPackage.fromJson(
        _presentationJson(),
      ),
    );

    expect(report.dqgIdentityMatches, isFalse);
    expect(report.isValid, isFalse);
  });

  test('Q9 fails on missing, unexpected or stale DQG Decision bindings', () {
    final technical = _technicalPackage();
    final manifest = LabScenarioPopulationManifest.fromJson(_manifestJson());
    final entry = manifest.requireEntry('l2_entry');
    final presentation = LabLearnerPresentationPackage.fromJson(
      _presentationJson(),
    );
    final decisions = technical.nodes.whereType<LabDecisionNode>().toList();

    final missing = validator.validate(
      entry: entry,
      technicalPackage: technical,
      dqg300Evidence: _dqgBundle(technical, omitNodeId: decisions.first.id),
      presentationPackage: presentation,
    );
    expect(missing.missingDqgDecisionIds, contains(decisions.first.id));
    expect(missing.isValid, isFalse);

    final unexpected = validator.validate(
      entry: entry,
      technicalPackage: technical,
      dqg300Evidence: _dqgBundle(technical, addUnexpected: true),
      presentationPackage: presentation,
    );
    expect(unexpected.unexpectedDqgDecisionIds, contains('decision_unknown'));
    expect(unexpected.isValid, isFalse);

    final stale = validator.validate(
      entry: entry,
      technicalPackage: technical,
      dqg300Evidence: _dqgBundle(technical, staleNodeId: decisions.last.id),
      presentationPackage: presentation,
    );
    expect(stale.staleDqgDecisionIds, contains(decisions.last.id));
    expect(stale.isValid, isFalse);
  });

  test('Q9 composes the frozen Q8 learner presentation mapping gate', () {
    final technical = _technicalPackage();
    final manifest = LabScenarioPopulationManifest.fromJson(_manifestJson());
    final presentationJson = _presentationJson();
    final decisionMap =
        (presentationJson['decisionPresentation'] as Map)
            .cast<String, Object?>();
    decisionMap.remove('decision_two');

    final report = validator.validate(
      entry: manifest.requireEntry('l2_entry'),
      technicalPackage: technical,
      dqg300Evidence: _dqgBundle(technical),
      presentationPackage: LabLearnerPresentationPackage.fromJson(
        presentationJson,
      ),
    );

    expect(
      report.presentationReport.missingDecisionIds,
      contains('decision_two'),
    );
    expect(report.isValid, isFalse);
  });
}
