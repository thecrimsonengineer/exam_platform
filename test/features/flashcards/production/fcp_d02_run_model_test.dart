import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const corpusPath =
      'assets/flashcards/production/manifest/fcp_corpus_manifest.v1.json';
  const d02ManifestPath =
      'assets/flashcards/production/d02/d02_production_manifest.v1.json';

  Map<String, dynamic> readObject(String path) => Map<String, dynamic>.from(
    jsonDecode(File(path).readAsStringSync()) as Map,
  );

  void expectSequentialStates(List<dynamic> rawStatuses) {
    final statuses = rawStatuses.map((item) => item.toString()).toList();
    final firstNotClosed = statuses.indexWhere((status) => status != 'closed');

    if (firstNotClosed == -1) {
      expect(statuses.every((status) => status == 'closed'), isTrue);
      return;
    }

    expect(
      statuses.take(firstNotClosed).every((status) => status == 'closed'),
      isTrue,
    );

    final tail = statuses.skip(firstNotClosed).toList();
    expect(<String>{'in_progress', 'validating', 'not_started'}, contains(tail.first));

    if (tail.first == 'not_started') {
      expect(tail.every((status) => status == 'not_started'), isTrue);
    } else {
      expect(
        tail.skip(1).every((status) => status == 'not_started'),
        isTrue,
      );
    }
  }

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
    expectSequentialStates(
      d02.values
          .map((item) => Map<String, dynamic>.from(item as Map)['status'])
          .toList(),
    );
  });

  test('D02 manifest has a closed prefix and at most one active run', () {
    final manifest = readObject(d02ManifestPath);
    final competencies = (manifest['competencies'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    expect(manifest['runModel'], 'one_competency_per_run');
    expectSequentialStates(
      competencies.map((item) => item['status']).toList(),
    );
  });

  test('every closed D02 competency owns a complete evidence bundle', () {
    final manifest = readObject(d02ManifestPath);
    final competencies = (manifest['competencies'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .where((item) => item['status'] == 'closed');

    const suffixes = <String>[
      '_fcq100_report.json',
      '_duplicate_report.json',
      '_source_report.json',
      '_coverage_report.json',
      '_validation_summary.md',
    ];

    for (final competency in competencies) {
      final id = competency['competencyId'] as String;
      final dir = Directory(
        'assets/flashcards/production/reports/competency/$id',
      );
      expect(dir.existsSync(), isTrue, reason: id);

      final names = dir
          .listSync()
          .whereType<File>()
          .map((file) => file.path.split(Platform.pathSeparator).last)
          .toSet();

      for (final suffix in suffixes) {
        expect(names.contains('$id$suffix'), isTrue, reason: '$id $suffix');
      }
    }
  });
}
