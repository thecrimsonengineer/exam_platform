import 'package:flutter_test/flutter_test.dart';

import '../../tool/agentic_pdca/m1_path_guard.dart';

void main() {
  const guard = M1RepositoryPathGuard();
  const allowed = <String>[
    'tool/agentic_pdca/**',
    'test/agentic_pdca/**',
    'docs/agentic/implementation/**',
  ];

  test('accepts canonical paths under mechanical allow-list roots', () {
    expect(guard.isAllowed('tool/agentic_pdca/example.dart', allowed), isTrue);
    expect(
      guard.isAllowed('test/agentic_pdca/example_test.dart', allowed),
      isTrue,
    );
    expect(
      guard.isAllowed('docs/agentic/implementation/M1_STATUS.md', allowed),
      isTrue,
    );
  });

  test('rejects traversal, absolute, drive-qualified, and backslash paths', () {
    for (final path in <String>[
      'tool/agentic_pdca/../../lib/main.dart',
      'test/agentic_pdca/../../../pubspec.yaml',
      r'C:\temp\x.dart',
      '/tmp/x.dart',
      r'tool\agentic_pdca\x.dart',
      'tool/./agentic_pdca/x.dart',
      'tool//agentic_pdca/x.dart',
    ]) {
      expect(guard.canonicalize(path), isNull, reason: path);
      expect(guard.isAllowed(path, allowed), isFalse, reason: path);
    }
  });
}
