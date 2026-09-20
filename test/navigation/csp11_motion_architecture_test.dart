import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PageRouteBuilder stays centralized in Csp11Route', () {
    final violations = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }

      final normalized = entity.path.replaceAll('\\', '/');
      if (normalized == 'lib/navigation/csp11_route.dart') {
        continue;
      }

      if (entity.readAsStringSync().contains('PageRouteBuilder')) {
        violations.add(normalized);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Direct PageRouteBuilder usage bypasses the MOT route system: '
          '${violations.join(', ')}',
    );
  });

  test('shared motion primitives do not animate glass blur or shadows', () {
    final violations = <String>[];

    for (final entity in Directory(
      'lib/widgets/motion',
    ).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }

      final source = entity.readAsStringSync();
      for (final forbidden in <String>[
        'BackdropFilter',
        'ImageFilter.blur',
        'BoxShadow(',
      ]) {
        if (source.contains(forbidden)) {
          violations.add('${entity.path}:$forbidden');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Core motion should remain compositor-friendly and avoid animated '
          'glass/shadow work: ${violations.join(', ')}',
    );
  });

  test('motion foundation stays backend-free', () {
    final violations = <String>[];

    for (final rootPath in <String>[
      'lib/theme/motion',
      'lib/widgets/motion',
      'lib/navigation/csp11_route.dart',
    ]) {
      final root =
          FileSystemEntity.typeSync(rootPath) == FileSystemEntityType.file
          ? <File>[File(rootPath)]
          : Directory(rootPath)
                .listSync(recursive: true)
                .whereType<File>()
                .where((file) => file.path.endsWith('.dart'))
                .toList();

      for (final file in root) {
        final source = file.readAsStringSync();
        for (final forbidden in <String>[
          'cloud_firestore',
          'firebase_',
          'supabase',
        ]) {
          if (source.contains(forbidden)) {
            violations.add('${file.path}:$forbidden');
          }
        }
      }
    }

    expect(violations, isEmpty);
  });
}
