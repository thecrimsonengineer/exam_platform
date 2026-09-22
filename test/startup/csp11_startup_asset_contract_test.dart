import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SM-1 production Lottie satisfies frozen startup asset contract', () {
    final file = File('assets/startup/csp11_startup_master.json');

    expect(file.existsSync(), isTrue);

    final decoded =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    expect(decoded['w'], 512);
    expect(decoded['h'], 512);
    expect(decoded['fr'], 30);
    expect(decoded['ip'], 0);
    expect(decoded['op'], 144);

    final layers = decoded['layers'] as List<dynamic>;
    expect(layers.length, greaterThanOrEqualTo(20));

    final markers = (decoded['markers'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((marker) => marker['cm'])
        .toList();

    expect(
      markers,
      containsAll(<String>[
        'ignite',
        'learn',
        'practice',
        'lab',
        'remember',
        'converge',
      ]),
    );

    final assets = decoded['assets'] as List<dynamic>;
    expect(assets, isEmpty);

    final textLayers = layers
        .cast<Map<String, dynamic>>()
        .where((layer) => layer['ty'] == 5)
        .toList();
    expect(textLayers, isEmpty);

    final domainNodes = layers
        .cast<Map<String, dynamic>>()
        .where((layer) => (layer['nm'] as String).startsWith('Domain Node D0'))
        .toList();
    expect(domainNodes.length, 7);
  });
}
