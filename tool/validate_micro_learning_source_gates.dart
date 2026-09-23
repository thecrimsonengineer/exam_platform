import 'dart:io';

import 'package:exam_platform/services/micro_learning/micro_fact_source_gate_validator.dart';

Future<void> main(List<String> args) async {
  final factPath = args.isNotEmpty
      ? args[0]
      : 'test/fixtures/micro_learning/valid_micro_fact_v1.json';
  final registryPath = args.length > 1
      ? args[1]
      : 'content/micro_learning/authority_registry_v1.json';

  final factFile = File(factPath);
  final registryFile = File(registryPath);

  if (!factFile.existsSync()) {
    stderr.writeln('ML-3 MicroFact not found: ' + factPath);
    exitCode = 2;
    return;
  }

  if (!registryFile.existsSync()) {
    stderr.writeln('ML-3 authority registry not found: ' + registryPath);
    exitCode = 2;
    return;
  }

  const validator = MicroFactSourceGateValidator();
  final result = validator.validateJson(
    microFactJson: await factFile.readAsString(),
    authorityRegistryJson: await registryFile.readAsString(),
  );

  if (!result.isValid) {
    stderr.writeln(
      'ML-3 source-gate validation failed with ' +
          result.issues.length.toString() +
          ' issue(s):',
    );
    for (final issue in result.issues) {
      stderr.writeln(' - ' + issue.toString());
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('ML-3 SOURCE GATES VALID');
  stdout.writeln('MicroFact: ' + factPath);
  stdout.writeln('Authority registry: ' + registryPath);
  stdout.writeln(
    'Registry binding: ' + MicroFactSourceGateValidator.requiredRegistryVersion,
  );
}
