import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_decision_quality_gate.dart';
import 'package:exam_platform/features/lab/lab_dqg300_evidence_store.dart';
import 'package:exam_platform/features/lab/lab_learner_presentation.dart';
import 'package:exam_platform/features/lab/lab_scenario_population_manifest.dart';
import 'package:exam_platform/features/lab/lab_scenario_population_publication.dart';
import 'package:exam_platform/features/lab/lab_studio.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _readObject(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! Map) {
    throw StateError('Expected JSON object at ' + path + '.');
  }
  return decoded.cast<String, Object?>();
}

LabScenarioPopulationManifest _batch2Manifest() =>
    LabScenarioPopulationManifest.fromJson(
      _readObject('content/lab_population_batch2/manifest.json'),
    );

Iterable<LabDecisionNode> _decisions(Map<String, Object?> root) =>
    LabPackage.fromJson(root).nodes.whereType<LabDecisionNode>();

String _normalized(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

void main() {
  const bindingValidator = LabScenarioPopulationBindingValidator();
  const qualityGate = LabDecisionQualityGate();

  test('Batch 2 manifest binds exactly ten isolated LAB versions', () {
    final manifest = _batch2Manifest();

    expect(manifest.manifestId, 'phase_l_population_batch2_v1');
    expect(manifest.entries, hasLength(10));
    expect(
      manifest.entries.map((entry) => entry.identityKey).toSet(),
      hasLength(10),
    );
    expect(
      manifest.entries.every(
        (entry) =>
            entry.technicalLabPath.startsWith('content/lab_population_batch2/'),
      ),
      isTrue,
    );
  });

  test(
    'Batch 2 passes binding, strict H0.3 and DQG300 for all 50 Decisions',
    () {
      final manifest = _batch2Manifest();
      var decisionCount = 0;
      var optionCount = 0;
      var atomicRuleEvidenceCount = 0;
      final failures = <String>[];

      for (final entry in manifest.entries) {
        final technicalRoot = _readObject(entry.technicalLabPath);
        final technical = LabPackage.fromJson(technicalRoot);
        final evidence = const LabDqg300EvidenceCodec().decode(
          File(entry.dqg300EvidencePath).readAsStringSync(),
        );
        final presentation = LabLearnerPresentationPackage.fromJson(
          _readObject(entry.learnerPresentationPath),
        );

        final binding = bindingValidator.validate(
          entry: entry,
          technicalPackage: technical,
          dqg300Evidence: evidence,
          presentationPackage: presentation,
        );
        if (!binding.isValid) {
          failures.add(entry.identityKey + ':binding');
        }

        final quality = qualityGate.evaluate(
          package: technical,
          evidenceBundle: evidence,
        );
        if (!quality.isValid) {
          for (final item in quality.decisionResults.where(
            (item) => !item.isPass,
          )) {
            failures.add(
              entry.identityKey +
                  ':' +
                  item.nodeId +
                  ' parse=' +
                  item.canonicalParsePass.toString() +
                  ' h03=' +
                  item.strictH03Pass.toString() +
                  ' errors=' +
                  item.h03ErrorCount.toString() +
                  ' warnings=' +
                  item.h03WarningCount.toString() +
                  ' dqg=' +
                  item.dqg300SemanticPass.toString() +
                  ' dqs=' +
                  (item.dqs?.toString() ?? 'null') +
                  ' passed=' +
                  item.dqg300PassedRuleCount.toString(),
            );
          }
        }

        final decisions = technical.nodes.whereType<LabDecisionNode>().toList();
        decisionCount += decisions.length;
        optionCount += decisions.fold<int>(
          0,
          (count, decision) => count + decision.options.length,
        );
        for (final item in evidence.decisions.values) {
          atomicRuleEvidenceCount += item.evidence.ruleEvidence.length;
        }
      }

      expect(failures, isEmpty, reason: failures.join(' | '));
      expect(decisionCount, 50);
      expect(optionCount, 200);
      expect(atomicRuleEvidenceCount, 14950);
    },
  );

  test(
    'Batch 2 has no exact Decision or option-set duplicates against production',
    () {
      final original = LabScenarioPopulationManifest.fromJson(
        _readObject('content/lab_population/manifest.json'),
      );
      final batch2 = _batch2Manifest();

      final originalPrompts = <String>{};
      final originalOptionSets = <String>{};

      for (final entry in original.entries) {
        for (final decision in _decisions(
          _readObject(entry.technicalLabPath),
        )) {
          originalPrompts.add(_normalized(decision.prompt));
          originalOptionSets.add(
            decision.options.map((item) => _normalized(item.text)).join('||'),
          );
        }
      }

      final batchPrompts = <String>{};
      final batchOptionSets = <String>{};
      for (final entry in batch2.entries) {
        for (final decision in _decisions(
          _readObject(entry.technicalLabPath),
        )) {
          final prompt = _normalized(decision.prompt);
          final options = decision.options
              .map((item) => _normalized(item.text))
              .join('||');

          expect(
            batchPrompts.add(prompt),
            isTrue,
            reason: 'Duplicate Batch 2 prompt: ' + prompt,
          );
          expect(
            batchOptionSets.add(options),
            isTrue,
            reason: 'Duplicate Batch 2 option set for ' + decision.id,
          );
          expect(
            originalPrompts.contains(prompt),
            isFalse,
            reason: 'Prompt duplicates production: ' + prompt,
          );
          expect(
            originalOptionSets.contains(options),
            isFalse,
            reason: 'Option set duplicates production for ' + decision.id,
          );
        }
      }
    },
  );

  test(
    'Batch 2 admits all ten entries through the immutable publication chain',
    () async {
      final manifest = _batch2Manifest();
      final repository = InMemoryLabPublishedRepository();
      final gate = LabScenarioPopulationPublicationGate(
        studio: Lab1000StudioService(repository: repository),
        validationAuthority: 'LSP-BATCH2-AUTO',
      );

      var admitted = 0;
      var decisions = 0;

      for (var index = 0; index < manifest.entries.length; index++) {
        final entry = manifest.entries[index];
        final result = await gate.admit(
          manifest: manifest,
          entryId: entry.entryId,
          technicalRoot: _readObject(entry.technicalLabPath),
          dqg300Evidence: const LabDqg300EvidenceCodec().decode(
            File(entry.dqg300EvidencePath).readAsStringSync(),
          ),
          presentationPackage: LabLearnerPresentationPackage.fromJson(
            _readObject(entry.learnerPresentationPath),
          ),
          validatedAt: DateTime.utc(2026, 9, 24, 14, index),
          publishedAt: DateTime.utc(2026, 9, 24, 15, index),
        );

        expect(result.isAdmitted, isTrue, reason: entry.identityKey);
        expect(result.bindingReport.isValid, isTrue);
        expect(result.decisionQualityReport.isValid, isTrue);
        expect(result.lifecycleResult.gateReport.isPublishable, isTrue);
        expect(result.publishedVersion.validationAuthority, 'LSP-BATCH2-AUTO');

        final stored = await repository.load(entry.labId, entry.versionId);
        expect(stored, isNotNull);
        final package = LabPackage.decode(stored!.publishedJson);
        expect(package.metadata.lifecycle, LabLifecycleStatus.published);
        admitted++;
        decisions += package.nodes.whereType<LabDecisionNode>().length;
      }

      expect(admitted, 10);
      expect(decisions, 50);
    },
  );
}
