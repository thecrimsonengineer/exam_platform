import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final apply = args.contains('--apply');

  final validation = await Process.run(
    Platform.resolvedExecutable,
    const ['run', 'tool/validate_ml9f_publication_freeze.dart'],
    runInShell: true,
  );

  stdout.write(validation.stdout);
  stderr.write(validation.stderr);
  if (validation.exitCode != 0) {
    stderr.writeln(
      'ML-9F publication blocked: readiness validation did not pass.',
    );
    exitCode = validation.exitCode;
    return;
  }

  const bankManifestPath =
      'content/micro_learning/curated_bank_manifest_v1.json';
  final bankManifest = await _readObject(bankManifestPath);
  if (exitCode != 0) return;

  final slots = (bankManifest['slots'] as List)
      .whereType<Map>()
      .map(Map<String, dynamic>.from)
      .toList(growable: false);

  if (slots.length != 120) {
    stderr.writeln('ML-9F requires exactly 120 bound slots.');
    exitCode = 1;
    return;
  }

  final updates = <String, Map<String, dynamic>>{};
  final productionFacts = <Map<String, dynamic>>[];

  for (final slot in slots) {
    final path = slot['candidatePath'];
    if (path is! String || path.isEmpty) {
      stderr.writeln('ML-9F missing candidatePath for ${slot['microFactId']}.');
      exitCode = 1;
      return;
    }

    final fact = await _readObject(path);
    if (exitCode != 0) return;

    fact['status'] = 'published';
    final runtime = Map<String, dynamic>.from(fact['runtime'] as Map);
    runtime['startupEligible'] = true;
    fact['runtime'] = runtime;

    updates[path] = fact;

    final provenance = Map<String, dynamic>.from(fact['provenance'] as Map);
    final review = Map<String, dynamic>.from(fact['review'] as Map);
    productionFacts.add({
      'microFactId': fact['microFactId'],
      'contentVersion': fact['contentVersion'],
      'path': path,
      'category': fact['category'],
      'sourceRegistryId': provenance['sourceRegistryId'],
      'sourceVerifiedAt': provenance['sourceVerifiedAt'],
      'reviewedAt': review['reviewedAt'],
      'nextReviewDueAt': review['nextReviewDueAt'],
      'status': 'published',
      'startupEligible': true,
    });
  }

  productionFacts.sort(
    (a, b) => (a['microFactId'] as String).compareTo(
      b['microFactId'] as String,
    ),
  );

  final productionManifest = <String, dynamic>{
    'schemaVersion': 1,
    'phase': 'ML-9F',
    'publicationStatus': 'published',
    'publishedAt': '2026-09-24',
    'sourceHumanReviewRef': 'phase-ml9e-human-review-closed',
    'sourceHumanReviewSha': '4e388ab419f2c93213c5aa01140562de019a6872',
    'factCount': 120,
    'startupEligibleCount': 120,
    'facts': productionFacts,
  };

  if (!apply) {
    stdout.writeln('ML-9F publication application is eligible.');
    stdout.writeln('Dry run only. Re-run with --apply to publish.');
    stdout.writeln('Fact files that would be updated: ${updates.length}');
    return;
  }

  for (final entry in updates.entries) {
    await File(entry.key).writeAsString(
      const JsonEncoder.withIndent('  ').convert(entry.value) + '\n',
    );
  }

  const productionManifestPath =
      'content/micro_learning/ml9f_production_manifest_v1.json';
  await File(productionManifestPath).writeAsString(
    const JsonEncoder.withIndent('  ').convert(productionManifest) + '\n',
  );

  stdout.writeln('ML-9F publication application complete.');
  stdout.writeln('Published facts: 120');
  stdout.writeln('Startup-eligible facts: 120');
  stdout.writeln('Production manifest: $productionManifestPath');
}

Future<Map<String, dynamic>> _readObject(String path) async {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('ML-9F required file not found: $path');
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
