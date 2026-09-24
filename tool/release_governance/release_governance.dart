import 'dart:convert';
import 'dart:io';

import 'release_evidence.dart';

Future<int> runReleaseGovernanceCli(
  List<String> arguments, {
  void Function(String message)? out,
  void Function(String message)? err,
}) async {
  final writeOut = out ?? stdout.writeln;
  final writeErr = err ?? stderr.writeln;

  if (arguments.isEmpty ||
      arguments.first == 'help' ||
      arguments.first == '--help' ||
      arguments.first == '-h') {
    writeOut(_usage);
    return 0;
  }

  try {
    switch (arguments.first) {
      case 'generate':
        final inputPath = _option(arguments, '--input');
        final outputPath = _option(arguments, '--output');
        final raw = await File(inputPath).readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is! Map) {
          throw const FormatException(
            'REL-GOV evidence input must be a JSON object.',
          );
        }
        final json = <String, Object?>{};
        for (final entry in decoded.entries) {
          if (entry.key is! String) {
            throw const FormatException(
              'REL-GOV evidence input keys must be strings.',
            );
          }
          json[entry.key as String] = entry.value;
        }

        final request = ReleaseEvidenceRequest.fromJson(json);
        const generator = ReleaseEvidenceGenerator();
        final result = await generator.generate(
          request: request,
          outputDirectory: outputPath,
        );
        final verification = await generator.verify(directory: outputPath);
        if (!verification.pass) {
          writeErr(
            'REL-GOV evidence verification failed: '
            '${verification.issues.join(', ')}',
          );
          return 2;
        }

        writeOut('releaseEvidence=PASS');
        writeOut('decision=${result.admission.decision.wireValue}');
        writeOut(
          'evidenceIdentitySha256=${result.evidenceIdentitySha256}',
        );
        writeOut('outputDirectory=${result.outputDirectory}');
        return 0;

      case 'verify':
        final directory = _option(arguments, '--directory');
        const generator = ReleaseEvidenceGenerator();
        final result = await generator.verify(directory: directory);
        if (!result.pass) {
          writeErr(
            'releaseEvidence=FAIL '
            '${result.issues.join(', ')}',
          );
          return 2;
        }

        writeOut('releaseEvidence=PASS');
        writeOut(
          'evidenceIdentitySha256=${result.evidenceIdentitySha256}',
        );
        return 0;

      default:
        writeErr('Unknown REL-GOV command: ${arguments.first}');
        writeErr(_usage);
        return 64;
    }
  } on Object catch (error) {
    writeErr('REL-GOV command failed: $error');
    return 2;
  }
}

String _option(List<String> arguments, String name) {
  final index = arguments.indexOf(name);
  if (index < 0 || index + 1 >= arguments.length) {
    throw FormatException('Missing required option $name.');
  }
  final value = arguments[index + 1].trim();
  if (value.isEmpty || value.startsWith('--')) {
    throw FormatException('Missing value for option $name.');
  }
  return value;
}

const String _usage = '''
CSP11 REL-GOV Evidence CLI

Generate:
  dart run tool/release_governance/release_governance.dart generate \\
    --input <evidence-input.json> \\
    --output <release-evidence-directory>

Verify:
  dart run tool/release_governance/release_governance.dart verify \\
    --directory <release-evidence-directory>
''';

Future<void> main(List<String> arguments) async {
  exitCode = await runReleaseGovernanceCli(arguments);
}
