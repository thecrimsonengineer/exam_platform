import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/micro_fact_rights_gate_validator.dart';
import 'package:exam_platform/services/micro_learning/rights_evidence_validator.dart';
import 'package:exam_platform/services/micro_learning/rights_provenance_policy_validator.dart';

Future<void> main(List<String> args) async {
  final factPath = args.isNotEmpty
      ? args[0]
      : 'test/fixtures/micro_learning/valid_micro_fact_v1.json';
  final registryPath = args.length > 1
      ? args[1]
      : 'content/micro_learning/authority_registry_v1.json';
  final claimPolicyPath = args.length > 2
      ? args[2]
      : 'content/micro_learning/claim_semantics_policy_v1.json';
  final rightsPolicyPath = args.length > 3
      ? args[3]
      : 'content/micro_learning/rights_provenance_policy_v1.json';
  final evidencePath = args.length > 4
      ? args[4]
      : 'test/fixtures/micro_learning/valid_rights_evidence_v1.json';

  final files = <String, File>{
    'MicroFact': File(factPath),
    'Authority registry': File(registryPath),
    'Claim policy': File(claimPolicyPath),
    'Rights policy': File(rightsPolicyPath),
    'Rights evidence': File(evidencePath),
  };

  for (final entry in files.entries) {
    if (!entry.value.existsSync()) {
      stderr.writeln('ML-5 ${entry.key} not found: ${entry.value.path}');
      exitCode = 2;
      return;
    }
  }

  final fact = await _readObject(files['MicroFact']!, 'MicroFact');
  final registry = await _readObject(
    files['Authority registry']!,
    'authority registry',
  );
  final claimPolicy = await _readObject(files['Claim policy']!, 'claim policy');
  final rightsPolicy = await _readObject(
    files['Rights policy']!,
    'rights policy',
  );
  final evidence = await _readObject(
    files['Rights evidence']!,
    'rights evidence',
  );

  if (exitCode != 0) {
    return;
  }

  final policyResult =
      const RightsProvenancePolicyValidator().validateMap(rightsPolicy);
  if (!policyResult.isValid) {
    stderr.writeln(
      'ML-5 rights policy validation failed with '
      '${policyResult.issues.length} issue(s):',
    );
    for (final issue in policyResult.issues) {
      stderr.writeln(' - $issue');
    }
    exitCode = 1;
    return;
  }

  final evidenceResult = const RightsEvidenceValidator().validateMap(evidence);
  if (!evidenceResult.isValid) {
    stderr.writeln(
      'ML-5 rights evidence validation failed with '
      '${evidenceResult.issues.length} issue(s):',
    );
    for (final issue in evidenceResult.issues) {
      stderr.writeln(' - $issue');
    }
    exitCode = 1;
    return;
  }

  final gateResult = const MicroFactRightsGateValidator().validateMaps(
    microFact: fact,
    authorityRegistry: registry,
    claimPolicy: claimPolicy,
    rightsPolicy: rightsPolicy,
    rightsEvidence: evidence,
  );

  if (!gateResult.isValid) {
    stderr.writeln(
      'ML-5 copyright/provenance validation failed with '
      '${gateResult.issues.length} issue(s):',
    );
    for (final issue in gateResult.issues) {
      stderr.writeln(' - $issue');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('ML-5 COPYRIGHT / PROVENANCE GATES VALID');
  stdout.writeln('MicroFact: $factPath');
  stdout.writeln('Authority registry: $registryPath');
  stdout.writeln('Claim policy: $claimPolicyPath');
  stdout.writeln('Rights policy: $rightsPolicyPath');
  stdout.writeln('Rights evidence: $evidencePath');
  stdout.writeln(
    'Rights policy version: '
    '${RightsProvenancePolicyValidator.requiredPolicyVersion}',
  );
}

Future<Map<String, dynamic>> _readObject(File file, String label) async {
  try {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
  } on FormatException catch (error) {
    stderr.writeln('ML-5 invalid $label JSON: ${error.message}');
    exitCode = 2;
    return <String, dynamic>{};
  }

  stderr.writeln('ML-5 $label must be a JSON object.');
  exitCode = 2;
  return <String, dynamic>{};
}
