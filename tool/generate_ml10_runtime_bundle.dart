import 'dart:convert';
import 'dart:io';

const _manifestPath = 'content/micro_learning/ml9f_production_manifest_v1.json';
const _outputPath = 'content/micro_learning/ml10_runtime_bundle_v1.json';
const _sourcePublicationSha = 'b9915db98fc644edaee8ed51e707dd24b120104f';

Future<void> main(List<String> args) async {
  final checkOnly = args.contains('--check');
  final manifest = await _readObject(_manifestPath);

  if (manifest['schemaVersion'] != 1 ||
      manifest['publicationStatus'] != 'published' ||
      manifest['factCount'] != 120 ||
      manifest['startupEligibleCount'] != 120) {
    stderr.writeln(
      'ML-10 requires the frozen 120-fact ML-9F production manifest.',
    );
    exitCode = 1;
    return;
  }

  final entries = (manifest['facts'] as List)
      .whereType<Map>()
      .map(Map<String, dynamic>.from)
      .toList(growable: false);
  if (entries.length != 120) {
    stderr.writeln(
      'ML-10 production manifest must contain exactly 120 entries.',
    );
    exitCode = 1;
    return;
  }

  final facts = <Map<String, dynamic>>[];
  final ids = <String>{};
  for (final entry in entries) {
    final id = entry['microFactId'];
    final path = entry['path'];
    if (id is! String || !ids.add(id) || path is! String || path.isEmpty) {
      stderr.writeln('ML-10 invalid or duplicate production manifest entry.');
      exitCode = 1;
      return;
    }

    final fact = await _readObject(path);
    if (fact['microFactId'] != id ||
        fact['contentVersion'] != entry['contentVersion'] ||
        fact['status'] != 'published' ||
        (fact['runtime'] as Map)['startupEligible'] != true) {
      stderr.writeln('ML-10 production fact binding failed for $id.');
      exitCode = 1;
      return;
    }
    facts.add(fact);
  }

  facts.sort(
    (a, b) =>
        (a['microFactId'] as String).compareTo(b['microFactId'] as String),
  );

  final bundle = <String, dynamic>{
    'schemaVersion': 1,
    'bundleId': 'csp11_micro_learning_runtime_v1',
    'bundleVersion': 1,
    'generatedAt': manifest['publishedAt'],
    'sourcePublicationSha': _sourcePublicationSha,
    'sourceProductionManifest': _manifestPath,
    'factCount': facts.length,
    'facts': facts,
  };
  final encoded = const JsonEncoder.withIndent('  ').convert(bundle) + '\n';

  final output = File(_outputPath);
  if (checkOnly) {
    if (!output.existsSync()) {
      stderr.writeln('ML-10 runtime bundle missing: $_outputPath');
      exitCode = 1;
      return;
    }
    final existing = await output.readAsString();
    if (existing != encoded) {
      stderr.writeln(
        'ML-10 runtime bundle is not byte-stable with production facts.',
      );
      exitCode = 1;
      return;
    }
    stdout.writeln('ML-10 RUNTIME BUNDLE BYTE-STABLE');
    stdout.writeln('Facts: ${facts.length}');
    return;
  }

  await output.writeAsString(encoded);
  stdout.writeln('ML-10 RUNTIME BUNDLE GENERATED');
  stdout.writeln('Facts: ${facts.length}');
  stdout.writeln('Output: $_outputPath');
}

Future<Map<String, dynamic>> _readObject(String path) async {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('ML-10 required file not found: $path');
    exitCode = 2;
    return <String, dynamic>{};
  }
  try {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is Map<String, dynamic>) return decoded;
  } on FormatException catch (error) {
    stderr.writeln('Invalid JSON in $path: ${error.message}');
    exitCode = 2;
    return <String, dynamic>{};
  }
  stderr.writeln('JSON root must be an object: $path');
  exitCode = 2;
  return <String, dynamic>{};
}
