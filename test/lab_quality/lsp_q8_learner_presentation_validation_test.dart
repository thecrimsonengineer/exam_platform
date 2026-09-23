import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_learner_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _technicalJson() {
  final source =
      File('test/fixtures/lab/l2_valid_lab.json').readAsStringSync();
  return (jsonDecode(source) as Map).cast<String, Object?>();
}

LabPackage _technicalPackage() => LabPackage.fromJson(_technicalJson());

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
          'observable': 'The learner observes the result of $id.',
          'guidedInsight': 'Consider what this outcome means for risk control.',
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

void main() {
  const validator = LabLearnerPresentationValidator();

  test('Q8 accepts complete exact-ID learner presentation mapping', () {
    final technical = _technicalPackage();
    final presentation = LabLearnerPresentationPackage.fromJson(
      _presentationJson(),
    );

    final report = validator.validate(
      technicalPackage: technical,
      presentationPackage: presentation,
    );

    expect(report.isValid, isTrue);
    expect(report.identityMatches, isTrue);
    expect(report.missingDecisionIds, isEmpty);
    expect(report.unexpectedDecisionIds, isEmpty);
    expect(report.missingConsequenceIds, isEmpty);
    expect(report.unexpectedConsequenceIds, isEmpty);
    expect(report.missingEvidenceIds, isEmpty);
    expect(report.unexpectedEvidenceIds, isEmpty);
    expect(report.missingEndingIds, isEmpty);
    expect(report.unexpectedEndingIds, isEmpty);
    expect(report.technicalMappingIssues, isEmpty);
  });

  test('Q8 fails closed on LAB or version identity mismatch', () {
    final technical = _technicalPackage();
    final presentation = LabLearnerPresentationPackage.fromJson(
      _presentationJson(versionId: 'v2'),
    );

    final report = validator.validate(
      technicalPackage: technical,
      presentationPackage: presentation,
    );

    expect(report.identityMatches, isFalse);
    expect(report.isValid, isFalse);
  });

  test('Q8 reports missing and unexpected Decision mappings', () {
    final json = _presentationJson();
    final decisions =
        (json['decisionPresentation'] as Map).cast<String, Object?>();
    decisions.remove('decision_two');
    decisions['decision_unknown'] = <String, Object?>{'title': 'Unknown'};
    json['decisionPresentation'] = decisions;

    final report = validator.validate(
      technicalPackage: _technicalPackage(),
      presentationPackage: LabLearnerPresentationPackage.fromJson(json),
    );

    expect(report.missingDecisionIds, contains('decision_two'));
    expect(report.unexpectedDecisionIds, contains('decision_unknown'));
    expect(report.isValid, isFalse);
  });

  test('Q8 requires complete consequence, evidence and ending mappings', () {
    final json = _presentationJson();
    final consequences =
        (json['consequencePresentation'] as Map).cast<String, Object?>();
    final evidence =
        (json['evidencePresentation'] as Map).cast<String, Object?>();
    final endings =
        (json['endingPresentation'] as Map).cast<String, Object?>();

    consequences.remove('c_critical');
    evidence.remove('permit');
    endings.remove('safe_end');

    json['consequencePresentation'] = consequences;
    json['evidencePresentation'] = evidence;
    json['endingPresentation'] = endings;

    final report = validator.validate(
      technicalPackage: _technicalPackage(),
      presentationPackage: LabLearnerPresentationPackage.fromJson(json),
    );

    expect(report.missingConsequenceIds, contains('c_critical'));
    expect(report.missingEvidenceIds, contains('permit'));
    expect(report.missingEndingIds, contains('safe_end'));
    expect(report.isValid, isFalse);
  });

  test('Q8 rejects presentation attempts to override Decision truth', () {
    final json = _presentationJson();
    final decisions =
        (json['decisionPresentation'] as Map).cast<String, Object?>();
    decisions['decision_one'] = <String, Object?>{
      'title': 'Immediate control',
      'prompt': 'Replacement prompt must never be accepted.',
      'options': <String>['A', 'B', 'C', 'D'],
      'bestAnswer': 2,
      'quality': 'OPTIMAL',
    };
    json['decisionPresentation'] = decisions;

    expect(
      () => LabLearnerPresentationPackage.fromJson(json),
      throwsA(isA<LabLearnerPresentationContractException>()),
    );
  });

  test('Q8 rejects presentation attempts to override consequence mechanics', () {
    final json = _presentationJson();
    final consequences =
        (json['consequencePresentation'] as Map).cast<String, Object?>();
    consequences['c_safe'] = <String, Object?>{
      'observable': 'Visible learner-facing outcome.',
      'guidedInsight': 'Learner-facing reflection.',
      'mutations': <Object?>[],
      'evidenceUnlocks': <String>[],
      'simulatedMinutes': 999,
    };
    json['consequencePresentation'] = consequences;

    expect(
      () => LabLearnerPresentationPackage.fromJson(json),
      throwsA(isA<LabLearnerPresentationContractException>()),
    );
  });

  test('Q8 rejects Story Gate, ending-mechanics and source overrides', () {
    final json = _presentationJson();
    json['gates'] = <Object?>[];
    json['sources'] = <String>['Unapproved replacement source'];
    json['dqgEvidence'] = <String, Object?>{};

    expect(
      () => LabLearnerPresentationPackage.fromJson(json),
      throwsA(isA<LabLearnerPresentationContractException>()),
    );

    final endingJson = _presentationJson();
    final endings =
        (endingJson['endingPresentation'] as Map).cast<String, Object?>();
    endings['safe_end'] = <String, Object?>{
      'title': 'Safe completion',
      'narrative': 'Learner-facing ending.',
      'keyTurningPoint': 'A learner-facing turning point.',
      'family': 'CRITICAL_FAILURE',
      'condition': <String, Object?>{'op': 'ALWAYS'},
    };
    endingJson['endingPresentation'] = endings;

    expect(
      () => LabLearnerPresentationPackage.fromJson(endingJson),
      throwsA(isA<LabLearnerPresentationContractException>()),
    );
  });

  test('Q8 rejects evidence truth overrides inside display records', () {
    final json = _presentationJson();
    final evidence =
        (json['evidencePresentation'] as Map).cast<String, Object?>();
    evidence['permit'] = <String, Object?>{
      'title': 'Work permit',
      'summary': 'Learner-facing summary.',
      'details': 'Learner-facing details.',
      'required': true,
      'type': 'replacement_type',
      'source': 'replacement_source',
    };
    json['evidencePresentation'] = evidence;

    expect(
      () => LabLearnerPresentationPackage.fromJson(json),
      throwsA(isA<LabLearnerPresentationContractException>()),
    );
  });

  test('Q8 validation is read-only over authoritative technical LAB', () {
    final technical = _technicalPackage();
    final firstDecision =
        technical.nodes.whereType<LabDecisionNode>().first;
    final beforePrompt = firstDecision.prompt;
    final beforeOptions =
        firstDecision.options.map((option) => option.text).toList();
    final beforeBest = firstDecision.options.indexWhere((option) => option.isBest);
    final beforeGate = Map<String, Object?>.from(technical.gates.first);
    final beforeEnding = Map<String, Object?>.from(technical.endings.first);

    final report = validator.validate(
      technicalPackage: technical,
      presentationPackage: LabLearnerPresentationPackage.fromJson(
        _presentationJson(),
      ),
    );

    expect(report.isValid, isTrue);
    expect(firstDecision.prompt, beforePrompt);
    expect(
      firstDecision.options.map((option) => option.text).toList(),
      beforeOptions,
    );
    expect(
      firstDecision.options.indexWhere((option) => option.isBest),
      beforeBest,
    );
    expect(technical.gates.first, beforeGate);
    expect(technical.endings.first, beforeEnding);
  });
}
