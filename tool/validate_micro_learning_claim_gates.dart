import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/services/micro_learning/claim_semantics_policy_validator.dart';
import 'package:exam_platform/services/micro_learning/micro_fact_claim_gate_validator.dart';

Future<void> main(List<String> args) async {
  final factPath = args.isNotEmpty
      ? args[0]
      : 'test/fixtures/micro_learning/valid_micro_fact_v1.json';
  final registryPath = args.length > 1
      ? args[1]
      : 'content/micro_learning/authority_registry_v1.json';
  final policyPath = args.length > 2
      ? args[2]
      : 'content/micro_learning/claim_semantics_policy_v1.json';

  final factFile = File(factPath);
  final registryFile = File(registryPath);
  final policyFile = File(policyPath);

  for (final entry in {
    'MicroFact': factFile,
    'Authority registry': registryFile,
    'Claim policy': policyFile,
  }.entries) {
    if (!entry.value.existsSync()) {
      stderr.writeln('ML-4 ' + entry.key + ' not found: ' + entry.value.path);
      exitCode = 2;
      return;
    }
  }

  final policyJson = await policyFile.readAsString();
  final policyResult = const ClaimSemanticsPolicyValidator().validateMap(
    await _decodeObject(policyJson, 'claim policy'),
  );

  if (!policyResult.isValid) {
    stderr.writeln(
      'ML-4 claim policy validation failed with ' +
          policyResult.issues.length.toString() +
          ' issue(s):',
    );
    for (final issue in policyResult.issues) {
      stderr.writeln(' - ' + issue.toString());
    }
    exitCode = 1;
    return;
  }

  final result = const MicroFactClaimGateValidator().validateJson(
    microFactJson: await factFile.readAsString(),
    authorityRegistryJson: await registryFile.readAsString(),
    claimPolicyJson: policyJson,
  );

  if (!result.isValid) {
    stderr.writeln(
      'ML-4 factual/legal-status validation failed with ' +
          result.issues.length.toString() +
          ' issue(s):',
    );
    for (final issue in result.issues) {
      stderr.writeln(' - ' + issue.toString());
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('ML-4 FACTUAL / LEGAL-STATUS GATES VALID');
  stdout.writeln('MicroFact: ' + factPath);
  stdout.writeln('Authority registry: ' + registryPath);
  stdout.writeln('Claim policy: ' + policyPath);
  stdout.writeln(
    'Policy version: ' + ClaimSemanticsPolicyValidator.requiredPolicyVersion,
  );
}

Future<Map<String, dynamic>> _decodeObject(
  String raw,
  String label,
) async {
  try {
    final dynamic decoded =
        await Future<dynamic>.value(_jsonDecode(raw));
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
  } catch (_) {
    // The claim validator will provide the detailed fail-closed message.
  }

  stderr.writeln('ML-4 ' + label + ' must be a JSON object.');
  exitCode = 2;
  return <String, dynamic>{};
}

dynamic _jsonDecode(String raw) {
  return const JsonDecoder().convert(raw);
}
