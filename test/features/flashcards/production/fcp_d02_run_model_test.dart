import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const corpusPath =
      'assets/flashcards/production/manifest/fcp_corpus_manifest.v1.json';
  const d02ManifestPath =
      'assets/flashcards/production/d02/d02_production_manifest.v1.json';
  const reportRoot = 'assets/flashcards/production/reports/competency/d02_c01';

  Map<String, dynamic> readObject(String path) => Map<String, dynamic>.from(
    jsonDecode(File(path).readAsStringSync()) as Map,
  );

  test('FCP-2 executes one independently closable run per competency', () {
    final corpus = readObject(corpusPath);
    final model = Map<String, dynamic>.from(
      corpus['productionRunModel'] as Map,
    );
    expect(model['unit'], 'competency');
    expect(model['effectiveFrom'], 'FCP-2');

    final allRuns = Map<String, dynamic>.from(corpus['competencyRuns'] as Map);
    final d02 = Map<String, dynamic>.from(allRuns['d02'] as Map);
    expect(d02.length, 14);
  });

  test('D02 manifest closes C01 before C02 starts', () {
    final manifest = readObject(d02ManifestPath);
    final competencies = (manifest['competencies'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    expect(manifest['runModel'], 'one_competency_per_run');
    expect(competencies.first['status'], 'closed');
    expect(
      competencies.skip(1).every((item) => item['status'] == 'not_started'),
      isTrue,
    );
  });

  test('FCP-2A owns a complete evidence bundle', () {
    const suffixes = <String>[
      '_fcq100_report.json',
      '_duplicate_report.json',
      '_source_report.json',
      '_coverage_report.json',
      '_validation_summary.md',
    ];
    final dir = Directory(reportRoot);
    expect(dir.existsSync(), isTrue);

    final names = dir
        .listSync()
        .whereType<File>()
        .map((file) => file.path.split(Platform.pathSeparator).last)
        .toSet();

    for (final suffix in suffixes) {
      expect(names.contains('d02_c01$suffix'), isTrue, reason: suffix);
    }
  });
}
