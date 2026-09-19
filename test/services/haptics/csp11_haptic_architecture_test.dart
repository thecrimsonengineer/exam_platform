import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('direct Flutter HapticFeedback calls stay inside haptic driver layer', () {
    final violations = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }

      final normalized = entity.path.replaceAll('\\', '/');
      if (normalized.startsWith('lib/services/haptics/')) {
        continue;
      }

      if (entity.readAsStringSync().contains('HapticFeedback.')) {
        violations.add(normalized);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Learner/admin UI must request semantic haptics through '
          'Csp11Haptics. Direct HapticFeedback calls found in: ' +
          violations.toString(),
    );
  });
}
