import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_decision_quality_gate.dart';
import 'package:exam_platform/features/lab/lab_dqg300_evidence_store.dart';
import 'package:exam_platform/features/lab/lab_learner_presentation.dart';
import 'package:exam_platform/features/lab/lab_scenario_population_manifest.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _readObject(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! Map) {
    throw StateError('Expected JSON object at ' + path + '.');
  }
  return decoded.cast<String, Object?>();
}

void main() {
  const bindingValidator = LabScenarioPopulationBindingValidator();
  const qualityGate = LabDecisionQualityGate();

  test('Q10 manifest contains the frozen ten-LAB population', () {
    final manifest = LabScenarioPopulationManifest.fromJson(
      _readObject('content/lab_population/manifest.json'),
    );

    expect(manifest.manifestId, 'phase_l_population_v1');
    expect(manifest.entries, hasLength(10));
    expect(
      manifest.entries.map((entry) => entry.labId).toSet(),
      <String>{
        'hot_work_hydrocarbon_simops',
        'mobile_crane_critical_lift',
        'excavation_buried_services',
        'electrical_loto_stored_energy',
        'work_at_height_offshore_module',
        'chemical_transfer_corrosive_solvent',
        'hydrocarbon_line_breaking',
        'flammable_tank_truck_loading',
        'pneumatic_pressure_test',
        'scaffold_erection_overhead_power',
      },
    );
  });

  test('Q10 all real population triplets pass Q9 and Q4-Q7 quality gates', () {
    final manifest = LabScenarioPopulationManifest.fromJson(
      _readObject('content/lab_population/manifest.json'),
    );

    var decisionCount = 0;
    var optionCount = 0;
    var atomicRuleEvidenceCount = 0;

    for (final entry in manifest.entries) {
      final technicalRoot = _readObject(entry.technicalLabPath);
      final technical = LabPackage.fromJson(technicalRoot);
      final dqg300Evidence = const LabDqg300EvidenceCodec().decode(
        File(entry.dqg300EvidencePath).readAsStringSync(),
      );
      final presentation = LabLearnerPresentationPackage.fromJson(
        _readObject(entry.learnerPresentationPath),
      );

      final binding = bindingValidator.validate(
        entry: entry,
        technicalPackage: technical,
        dqg300Evidence: dqg300Evidence,
        presentationPackage: presentation,
      );

      expect(
        binding.isValid,
        isTrue,
        reason: 'Q9 population binding failed for ' + entry.identityKey + '.',
      );

      final quality = qualityGate.evaluate(
        package: technical,
        evidenceBundle: dqg300Evidence,
      );

      expect(
        quality.isValid,
        isTrue,
        reason:
            'Q4-Q7 combined Decision-quality gate failed for ' +
            entry.identityKey +
            '.',
      );

      final decisions = technical.nodes.whereType<LabDecisionNode>().toList();
      decisionCount += decisions.length;
      optionCount += decisions.fold<int>(
        0,
        (count, decision) => count + decision.options.length,
      );

      for (final evidence in dqg300Evidence.decisions.values) {
        atomicRuleEvidenceCount += evidence.evidence.ruleEvidence.length;
      }
    }

    expect(decisionCount, 50);
    expect(optionCount, 200);
    expect(atomicRuleEvidenceCount, 14950);
  });
}
