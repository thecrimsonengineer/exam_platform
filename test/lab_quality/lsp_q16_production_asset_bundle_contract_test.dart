import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const manifestPath = 'content/lab_population/manifest.json';

  test('Q16 production LAB assets are bundled explicitly', () {
    final pubspec = File('pubspec.yaml')
        .readAsStringSync()
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');

    final manifestFile = File(manifestPath);
    expect(manifestFile.existsSync(), isTrue);

    final decoded = jsonDecode(manifestFile.readAsStringSync());
    expect(decoded, isA<Map>());

    final manifest = Map<String, dynamic>.from(decoded as Map);
    final entries = manifest['entries'];
    expect(entries, isA<List>());
    expect((entries as List).length, 10);

    expect(pubspec, contains('    - content/lab_population/\n'));

    for (final rawEntry in entries) {
      final entry = Map<String, dynamic>.from(rawEntry as Map);

      for (final key in <String>[
        'technicalLabPath',
        'dqg300EvidencePath',
        'learnerPresentationPath',
      ]) {
        final path = entry[key]?.toString() ?? '';
        expect(path, isNotEmpty, reason: '$key must be populated.');
        expect(File(path).existsSync(), isTrue, reason: 'Missing LAB asset $path');

        final slash = path.lastIndexOf('/');
        expect(slash, greaterThan(0));
        final directory = path.substring(0, slash + 1);
        expect(
          pubspec,
          contains('    - $directory\n'),
          reason: 'Flutter pubspec must explicitly bundle $directory',
        );
      }
    }
  });
}
