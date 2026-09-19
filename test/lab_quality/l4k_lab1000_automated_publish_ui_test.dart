import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LAB1000 exposes automated test-and-publish as the primary new path', () {
    final source = File(
      'lib/screens/admin/lab/lab1000_studio_screen.dart',
    ).readAsStringSync();

    expect(source, contains('LabAutomatedLifecycleService'));
    expect(source, contains('InMemoryLabDqg300EvidenceRepository'));
    expect(source, contains("ValueKey('lab1000-dqg300-evidence-editor')"));
    expect(source, contains("ValueKey('lab1000-save-dqg300-evidence')"));
    expect(source, contains("ValueKey('lab1000-auto-publish')"));
    expect(source, contains('RUN TESTS & PUBLISH'));
    expect(source, contains('validateAndPublishStored'));
    expect(source, contains('Human approval is not required on this path.'));
  });

  test('legacy manual lifecycle remains only as compatibility UI', () {
    final source = File(
      'lib/screens/admin/lab/lab1000_studio_screen.dart',
    ).readAsStringSync();

    expect(source, contains("ValueKey('lab1000-legacy-lifecycle')"));
    expect(source, contains('Legacy manual lifecycle'));
    expect(source, contains("ValueKey('lab1000-review')"));
    expect(source, contains("ValueKey('lab1000-approve')"));
    expect(source, contains("ValueKey('lab1000-publish')"));
  });
}
