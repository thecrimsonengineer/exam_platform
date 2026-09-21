import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/agentic_pdca/m0_models.dart';
import '../../tool/agentic_pdca/m1_mechanical_authority.dart';
import '../../tool/agentic_pdca/m1_repository.dart';

final class FakeRepository implements M1TrustedRepository {
  FakeRepository(this.facts);

  final M1RepositoryFacts facts;

  @override
  String get root => '.';

  @override
  Future<M1RepositoryFacts> readFacts({
    required String approvedBaseSha,
  }) async => facts;
}

void main() {
  const sha = '94d060e37358915d03a2375ebc3af54808633e15';
  const paths = ['tool/agentic_pdca/**', 'test/agentic_pdca/**'];

  final now = DateTime.utc(2026, 9, 21);

  M1MechanicalAuthority authority({
    String ref = 'agentic-pdca-m1-001',
    String lineageSha = sha,
  }) => M1MechanicalAuthority(
    trustedState: ControlPlaneSnapshot(
      maturity: 'M0_OBSERVATION',
      governanceVersion: 'v1.0',
      governanceSha: '43b2b3cc99839ae9de4092b4e2b7058d1964bff7',
      observedAt: now,
      tasks: const [],
      taskStates: const [],
      taskStateEvidence: const [],
      lineages: [
        LineageSnapshot(
          taskId: 'TASK-M1-002',
          lineageId: 'LINEAGE-M1-001',
          currentSha: lineageSha,
          lineageGeneration: 1,
          candidateSequence: 1,
          governanceVersion: 'v1.0',
          observedAt: now,
        ),
      ],
      authoritativeEvents: const [],
      eventEvidence: const [],
      repairBudgets: const [],
      branchHeads: const [],
      writerLeases: [
        WriterLeaseSnapshot(
          writerLeaseId: 'LEASE-1',
          lineageId: 'LINEAGE-M1-001',
          branch: 'agentic-pdca-m1-001',
          agentPrincipal: 'agent-1',
          fencingToken: 7,
          expectedHead: sha,
          active: true,
          expiresAt: now.add(const Duration(hours: 1)),
          observedAt: now,
        ),
      ],
      cancellations: const [],
      evidenceReferences: const [],
      humanApprovals: const [],
      writerLeaseEvidence: const [],
    ),
    repository: FakeRepository(
      M1RepositoryFacts(
        root: '.',
        head: sha,
        ref: ref,
        mergeBase: sha,
        changedPaths: const [],
        deletedTestPaths: const [],
        dirtyTrackedPaths: const [],
        fileContents: const {},
        binaryPaths: const [],
      ),
    ),
    approvedBaseSha: sha,
    trustedClock: () => now,
  );

  M1MechanicalAuthorityRequest request({
    String actionClass = 'FORMAT',
    String expectedHead = sha,
    String branch = 'agentic-pdca-m1-001',
    String writerIdentity = 'agent-1',
    int fencingToken = 7,
    String path = 'tool/agentic_pdca/example.dart',
  }) => M1MechanicalAuthorityRequest(
    taskId: 'TASK-M1-002',
    lineageId: 'LINEAGE-M1-001',
    baseSha: sha,
    expectedHead: expectedHead,
    branch: branch,
    allowedPaths: paths,
    expectedChangedPaths: [path],
    actionClass: actionClass,
    requiredGates: const ['FORMAT', 'ANALYZE'],
    writerLeaseId: 'LEASE-1',
    writerIdentity: writerIdentity,
    fencingToken: fencingToken,
  );

  test('wrong branch, detached and unexpected ref deny mutation', () async {
    for (final ref in ['', 'HEAD', 'other-branch']) {
      expect(
        (await authority(ref: ref).authorize(request())).authorized,
        isFalse,
      );
    }
  });
  test('stale lineage currentSha denies mutation', () async {
    expect(
      (await authority(
        lineageSha: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      ).authorize(request())).authorized,
      isFalse,
    );
  });
  test('FORMAT requires authority before any process execution', () async {
    await expectLater(
      const M1MechanicalExecutor().executeFormat(
        authority: authority(ref: ''),
        request: request(),
        actionId: 'denied',
      ),
      throwsStateError,
    );
  });

  test('authorizes each DO-1 class with matching lease fencing', () async {
    final controlAuthority = authority();
    for (final actionClass in [
      'FORMAT',
      'IMPORT_FIX',
      'SIMPLE_ANALYZER_FIX',
      'SAFE_TEST_HARNESS_FIX',
    ]) {
      final result = await controlAuthority.authorize(
        request(actionClass: actionClass),
      );
      expect(result.authorized, isTrue, reason: result.reason);
    }
  });

  test(
    'rejects HEAD drift, stale lease, identity mismatch, and stale token',
    () async {
      final controlAuthority = authority();
      expect(
        (await controlAuthority.authorize(
          request(expectedHead: 'wrong'),
        )).authorized,
        isFalse,
      );
      expect(
        (await controlAuthority.authorize(
          request(branch: 'other-branch'),
        )).authorized,
        isFalse,
      );
      expect(
        (await controlAuthority.authorize(
          request(writerIdentity: 'other'),
        )).authorized,
        isFalse,
      );
      expect(
        (await controlAuthority.authorize(request(fencingToken: 8))).authorized,
        isFalse,
      );
    },
  );

  test('rejects protected paths and non-mechanical classes', () async {
    final controlAuthority = authority();
    expect(
      (await controlAuthority.authorize(
        request(path: 'lib/main.dart'),
      )).authorized,
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
        (await controlAuthority.authorize(
          request(actionClass: actionClass),
        )).authorized,
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

  test('executes FORMAT directly only after trusted authority', () async {
    final fixture = File(
      'test/agentic_pdca/.m1_format_fixture_' +
          DateTime.now().microsecondsSinceEpoch.toString() +
          '.dart',
    );
    await fixture.writeAsString('void main( ) {print("x");}\n');
    try {
      final record = await const M1MechanicalExecutor().executeFormat(
        authority: authority(),
        request: request(
          path: fixture.path.replaceAll(Platform.pathSeparator, "/"),
        ),
        actionId: 'ACTION-FORMAT-1',
      );
      expect(record.exitCode, 0);
      expect(await fixture.readAsString(), contains('void main()'));
      expect(record.preHead, sha);
      expect(record.postHead, sha);
    } finally {
      if (await fixture.exists()) {
        await fixture.delete();
      }
    }
  });
}
