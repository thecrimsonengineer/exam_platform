import 'package:flutter_test/flutter_test.dart';

import '../../tool/agentic_pdca/m1_mechanical_authority.dart';

void main() {
  const sha = '94d060e37358915d03a2375ebc3af54808633e15';
  const paths = ['tool/agentic_pdca/**', 'test/agentic_pdca/**'];

  M1MechanicalAuthorityRequest request({
    String actionClass = 'FORMAT',
    String expectedHead = sha,
    String actualHead = sha,
    String writerIdentity = 'agent-1',
    int fencingToken = 7,
    String leaseWriterIdentity = 'agent-1',
    int leaseFencingToken = 7,
    String path = 'tool/agentic_pdca/example.dart',
  }) => M1MechanicalAuthorityRequest(
    taskId: 'TASK-M1-002',
    lineageId: 'LINEAGE-M1-001',
    baseSha: sha,
    expectedHead: expectedHead,
    actualHead: actualHead,
    allowedPaths: paths,
    expectedChangedPaths: [path],
    actionClass: actionClass,
    requiredGates: const ['FORMAT', 'ANALYZE'],
    writerLeaseId: 'LEASE-1',
    writerIdentity: writerIdentity,
    fencingToken: fencingToken,
    lease: M1WriterLeaseState(
      writerLeaseId: 'LEASE-1',
      writerIdentity: leaseWriterIdentity,
      fencingToken: leaseFencingToken,
      active: true,
    ),
  );

  test('authorizes each DO-1 class with matching lease fencing', () {
    final authority = M1MechanicalAuthority();
    for (final actionClass in [
      'FORMAT',
      'IMPORT_FIX',
      'SIMPLE_ANALYZER_FIX',
      'SAFE_TEST_HARNESS_FIX',
    ]) {
      expect(
        authority.authorize(request(actionClass: actionClass)).authorized,
        isTrue,
      );
    }
  });

  test(
    'rejects HEAD drift, stale lease, identity mismatch, and stale token',
    () {
      final authority = M1MechanicalAuthority();
      expect(
        authority.authorize(request(expectedHead: 'wrong')).authorized,
        isFalse,
      );
      expect(
        authority.authorize(request(actualHead: 'wrong')).authorized,
        isFalse,
      );
      expect(
        authority.authorize(request(leaseWriterIdentity: 'other')).authorized,
        isFalse,
      );
      expect(
        authority.authorize(request(leaseFencingToken: 8)).authorized,
        isFalse,
      );
    },
  );

  test('rejects protected paths and non-mechanical classes', () {
    final authority = M1MechanicalAuthority();
    expect(
      authority.authorize(request(path: 'lib/main.dart')).authorized,
      isFalse,
    );
    for (final actionClass in [
      'FEATURE_BEHAVIOR',
      'ARCHITECTURE',
      'SECURITY',
      'AUTH',
      'BACKEND',
      'DATABASE',
      'DEPENDENCY_CHANGE',
      'GOVERNANCE_CHANGE',
      'TEST_WEAKENING',
      'UNKNOWN',
    ]) {
      expect(
        authority.authorize(request(actionClass: actionClass)).authorized,
        isFalse,
      );
    }
  });

  test('structured executor exposes no arbitrary shell operation', () {
    const executor = M1MechanicalExecutor();
    expect(
      executor.commandFor(M1StructuredOperation.format, [
        'tool/agentic_pdca/a.dart',
      ]),
      contains('dart format'),
    );
    expect(
      () => executor.commandFor(M1StructuredOperation.format, ['pubspec.yaml']),
      throwsArgumentError,
    );
    expect(
      () => executor.commandFor(M1StructuredOperation.importFix, [
        'tool/agentic_pdca/a.dart',
      ]),
      throwsUnsupportedError,
    );
    final record = executor.record(
      taskId: 'TASK-M1-003',
      actionId: 'ACTION-1',
      actionClass: M1MechanicalClass.format,
      baseSha: sha,
      preHead: sha,
      postHead: sha,
      paths: const ['tool/agentic_pdca/a.dart'],
      operation: M1StructuredOperation.format,
      exitCode: 0,
      stdoutSummary: 'formatted',
      stderrSummary: '',
      duration: Duration.zero,
      timestamp: DateTime.utc(2026, 9, 21),
    );
    expect(record.actionId, 'ACTION-1');
    expect(record.baseSha, sha);
  });
}
