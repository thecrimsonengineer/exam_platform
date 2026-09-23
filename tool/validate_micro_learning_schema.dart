import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/models/micro_learning/micro_fact.dart';
import 'package:exam_platform/services/micro_learning/micro_fact_schema_validator.dart';

Future<void> main(List<String> args) async {
  final fixturePath = args.isEmpty
      ? 'test/fixtures/micro_learning/valid_micro_fact_v1.json'
      : args.first;

  final fixtureFile = File(fixturePath);
  if (!fixtureFile.existsSync()) {
    stderr.writeln('ML-2 fixture not found: ' + fixturePath);
    exitCode = 2;
    return;
  }

  final raw = await fixtureFile.readAsString();
  final validator = MicroFactSchemaValidator();
  final result = validator.validateJson(raw);

  if (!result.isValid) {
    stderr.writeln(
      'ML-2 MicroFact validation failed with ' +
          result.issues.length.toString() +
          ' issue(s):',
    );
    for (final issue in result.issues) {
      stderr.writeln(' - ' + issue.toString());
    }
    exitCode = 1;
    return;
  }

  final json = jsonDecode(raw) as Map<String, dynamic>;
  final fact = MicroFact.fromValidatedJson(json);

  stdout.writeln('ML-2 MicroFact v1 VALID');
  stdout.writeln('microFactId: ' + fact.microFactId);
  stdout.writeln('schemaVersion: ' + fact.schemaVersion.toString());
  stdout.writeln('status: ' + fact.status);
  stdout.writeln('sourceRegistryId: ' + fact.provenance.sourceRegistryId);
}
