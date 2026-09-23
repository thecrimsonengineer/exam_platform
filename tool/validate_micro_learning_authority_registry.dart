import 'dart:io';

import 'package:exam_platform/services/micro_learning/authority_registry_validator.dart';

Future<void> main(List<String> args) async {
  final path = args.isEmpty
      ? 'content/micro_learning/authority_registry_v1.json'
      : args.first;

  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('ML-1 authority registry not found: ' + path);
    exitCode = 2;
    return;
  }

  final result = AuthorityRegistryValidator().validateJson(
    await file.readAsString(),
  );

  if (!result.isValid) {
    stderr.writeln(
      'ML-1 authority registry validation failed with ' +
          result.issues.length.toString() +
          ' issue(s):',
    );
    for (final issue in result.issues) {
      stderr.writeln(' - ' + issue.toString());
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('ML-1 authority registry VALID');
  stdout.writeln('Registry: ' + path);
  stdout.writeln(
    'Approved authority families: ' +
        AuthorityRegistryValidator.requiredAuthorityIds.length.toString(),
  );
}
