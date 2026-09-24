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
    expect(
      runs.entries.skip(2).every((entry) => entry.value == 'not_started'),
      isTrue,
    );
  });

  test('FCP-1 closes only D01 before FCP-2 begins', () {
    final manifest = Map<String, dynamic>.from(
      jsonDecode(File(manifestPath).readAsStringSync()) as Map,
    );
    final domains = Map<String, dynamic>.from(manifest['domains'] as Map);

    expect(domains.keys.toList(), <String>['d01']);
    final d01 = Map<String, dynamic>.from(domains['d01'] as Map);
    expect(d01['competencyCount'], 7);
    expect(d01['status'], 'closed');
    expect(d01['cardCount'], 78);
  });
}
