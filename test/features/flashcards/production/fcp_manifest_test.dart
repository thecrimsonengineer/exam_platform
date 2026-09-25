import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const manifestPath =
      'assets/flashcards/production/manifest/fcp_corpus_manifest.v1.json';

  test('FCP manifest is anchored to the frozen FC closure', () {
    final file = File(manifestPath);
    expect(file.existsSync(), isTrue);

    final decoded = jsonDecode(file.readAsStringSync());
    expect(decoded, isA<Map>());

    final manifest = Map<String, dynamic>.from(decoded as Map);
    expect(manifest['schemaVersion'], 1);
    expect(manifest['phase'], 'FCP');
    expect(manifest['status'], 'authoring');
    expect(manifest['workingBranch'], 'phase-fcp-flashcard-production');

    final base = Map<String, dynamic>.from(manifest['base'] as Map);
    expect(base['branch'], 'phase-fc-closed');
    expect(base['sha'], 'eeaad1d2d02c3aaf3c09f39ed277185624542c93');
  });

  test('FCP declares exactly twelve ordered runs', () {
    final manifest = Map<String, dynamic>.from(
      jsonDecode(File(manifestPath).readAsStringSync()) as Map,
    );
    final runs = Map<String, dynamic>.from(manifest['runs'] as Map);

    expect(runs.length, 12);
    expect(runs.keys.toList(), <String>[
      'fcp0',
      'fcp1',
      'fcp2',
      'fcp3',
      'fcp4',
      'fcp5',
      'fcp6',
      'fcp7',
      'fcp8',
      'fcp9',
      'fcp10',
      'fcp11',
    ]);
    expect(runs['fcp0'], 'closed');
    expect(runs['fcp1'], 'closed');
    expect(runs['fcp2'], 'closed');
    expect(
      runs.entries.skip(3).every((entry) => entry.value == 'not_started'),
      isTrue,
    );
  });

  test('FCP-2 uses one competency per independently closable run', () {
    final manifest = Map<String, dynamic>.from(
      jsonDecode(File(manifestPath).readAsStringSync()) as Map,
    );
    final model = Map<String, dynamic>.from(
      manifest['productionRunModel'] as Map,
    );
    expect(model['unit'], 'competency');
    expect(model['effectiveFrom'], 'FCP-2');

    final competencyRuns = Map<String, dynamic>.from(
      manifest['competencyRuns'] as Map,
    );
    final d02 = Map<String, dynamic>.from(competencyRuns['d02'] as Map);
    expect(d02.length, 14);

    final statuses = d02.values
        .map(
          (item) => Map<String, dynamic>.from(item as Map)['status'].toString(),
        )
        .toList();
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
    expect(<String>{
      'in_progress',
      'validating',
      'not_started',
    }, contains(tail.first));
    if (tail.first == 'not_started') {
      expect(tail.every((status) => status == 'not_started'), isTrue);
    } else {
      expect(tail.skip(1).every((status) => status == 'not_started'), isTrue);
    }
  });

  test('FCP-2 admits D02 after frozen D01 closure', () {
    final manifest = Map<String, dynamic>.from(
      jsonDecode(File(manifestPath).readAsStringSync()) as Map,
    );
    final domains = Map<String, dynamic>.from(manifest['domains'] as Map);

    expect(domains.keys.toList(), <String>['d01', 'd02']);
    final d01 = Map<String, dynamic>.from(domains['d01'] as Map);
    expect(d01['competencyCount'], 7);
    expect(d01['status'], 'closed');
    expect(d01['cardCount'], 78);

    final d02 = Map<String, dynamic>.from(domains['d02'] as Map);
    expect(d02['competencyCount'], 14);
    expect(d02['status'], 'closed');
    expect(d02['cardCount'], 174);
  });
}
