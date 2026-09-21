import 'dart:io';
import 'm1_test_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/agentic_pdca/m0_models.dart';
import '../../tool/agentic_pdca/m1_check_act.dart';

final class FakeRunner implements M1TrustedCommandRunner {
  FakeRunner(this.result);

  final M1CommandResult result;
  int calls = 0;
  void Function()? onRun;

  @override
  Future<M1CommandResult> run(M1CheckGate gate) async {
    calls++;
    onRun?.call();
    return result;
  }
}

void main() {
  const sha = '94d060e37358915d03a2375ebc3af54808633e15';

  test(
    'CHECK binds evidence to exact SHA and accepts known generated side effects',
    () async {
      final repository = CheckRepository(
        dirty: ['linux/flutter/generated_plugins.cmake'],
      );
      final runner = M1DeterministicCheckRunner(
        repository: repository,
        expectedCandidateSha: sha,
        approvedBaseSha: sha,
        commandRunner: FakeRunner(
          const M1CommandResult(exitCode: 0, stdout: 'ok', stderr: ''),
        ),
      );
      final result = await runner.run(
        checkId: 'CHECK-1-FORMAT',
        gate: M1CheckGate.format,
        validatorIdentity: 'test-validator',
      );
      expect(result.result, M1CheckResult.green);
    },
  );

  test('caller cannot fake candidate HEAD or clean CHECK state', () async {
    final repository = CheckRepository(
      head: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    );
    final runner = M1DeterministicCheckRunner(
      repository: repository,
      expectedCandidateSha: sha,
      approvedBaseSha: sha,
      commandRunner: FakeRunner(
        const M1CommandResult(exitCode: 0, stdout: 'ok', stderr: ''),
      ),
    );
    final wrongSha = await runner.run(
      checkId: 'CHECK-1-TEST',
      gate: M1CheckGate.test,
      validatorIdentity: 'test-validator',
    );
    repository.head = sha;
    repository.dirty = ['lib/main.dart'];
    final dirty = await runner.run(
      checkId: 'CHECK-1-TEST',
      gate: M1CheckGate.test,
      validatorIdentity: 'test-validator',
    );
    expect(wrongSha.candidateSha, 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
    expect(wrongSha.result, M1CheckResult.blocked);
    expect(dirty.result, M1CheckResult.blocked);
  });

  test(
    'CHECK blocks dirty state and HEAD drift introduced during validation',
    () async {
      for (final driftHead in [false, true]) {
        final repository = CheckRepository();
        final command = FakeRunner(
          const M1CommandResult(exitCode: 0, stdout: '', stderr: ''),
        );
        command.onRun = () {
          if (driftHead) {
            repository.head = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
          } else {
            repository.dirty = ['README.md'];
          }
        };
        final check = M1DeterministicCheckRunner(
          repository: repository,
          expectedCandidateSha: sha,
          approvedBaseSha: sha,
          commandRunner: command,
        );
        expect(
          (await check.run(
            checkId: 'post',
            gate: M1CheckGate.test,
            validatorIdentity: 'trusted',
          )).result,
          M1CheckResult.blocked,
        );
        expect(command.calls, 1);
      }
    },
  );
  test('CHECK ancestry mismatch prevents command execution', () async {
    final command = FakeRunner(
      const M1CommandResult(exitCode: 0, stdout: '', stderr: ''),
    );
    final check = M1DeterministicCheckRunner(
      repository: CheckRepository(base: 'wrong'),
      expectedCandidateSha: sha,
      approvedBaseSha: sha,
      commandRunner: command,
    );
    expect(
      (await check.run(
        checkId: 'base',
        gate: M1CheckGate.test,
        validatorIdentity: 'trusted',
      )).result,
      M1CheckResult.blocked,
    );
    expect(command.calls, 0);
  });

  test('ANALYZE flags are fixed and cannot be altered by callers', () {
    expect(M1ProcessCommandRunner.analyzerArguments, const [
      'analyze',
      '--no-fatal-infos',
      '--fatal-warnings',
    ]);
    expect(
      () => M1ProcessCommandRunner.analyzerArguments.add('--no-fatal-warnings'),
      throwsUnsupportedError,
    );
    final runner = M1ProcessCommandRunner(CheckRepository());
    expect(
      () => Function.apply(
        runner.run,
        [M1CheckGate.analyze],
        {
          #arguments: ['analyze', '--no-fatal-warnings'],
        },
      ),
      throwsNoSuchMethodError,
    );
  });

  test('nonzero trusted ANALYZE exit remains CHECK red', () async {
    final runner = M1DeterministicCheckRunner(
      repository: CheckRepository(),
      expectedCandidateSha: sha,
      approvedBaseSha: sha,
      commandRunner: FakeRunner(
        const M1CommandResult(exitCode: 1, stdout: '', stderr: 'failed'),
      ),
    );
    final result = await runner.run(
      checkId: 'CHECK-1-ANALYZE',
      gate: M1CheckGate.analyze,
      validatorIdentity: 'test-validator',
    );
    expect(result.result, M1CheckResult.red);
    expect(result.command, 'flutter analyze --no-fatal-infos --fatal-warnings');
  });

  test('CHECK executes FORMAT in trusted root without repairing', () async {
    final dir = await Directory.systemTemp.createTemp('m1-check-root-');
    try {
      await Directory(dir.path + '/tool/agentic_pdca').create(recursive: true);
      await Directory(dir.path + '/test/agentic_pdca').create(recursive: true);
      final fixture = File(dir.path + '/tool/agentic_pdca/bad.dart');
      const original = 'void main( ) {print("x");}';
      await fixture.writeAsString(original);
      final result = await M1ProcessCommandRunner(
        CheckRepository(root: dir.path),
      ).run(M1CheckGate.format);
      expect(result.exitCode, 1);
      expect(result.stdout, contains('bad.dart'));
      expect(await fixture.readAsString(), original);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test(
    'CHECK-2 glob accepts descendants and rejects prefix tricks and dirty unrelated files',
    () async {
      final repository = CheckRepository(
        changed: ['tool/agentic_pdca/nested/a.dart'],
      );
      final scanner = M1IntegrityScanner();
      Future<List<M1IntegrityFinding>> scan() => scanner.scanRepository(
        repository: repository,
        approvedBaseSha: sha,
        candidateSha: sha,
        expectedPaths: ['tool/agentic_pdca/**'],
      );
      expect(await scan(), isEmpty);
      for (final path in [
        'tool/agentic_pdca_extra/a.dart',
        'tool/agentic_pdca/../a.dart',
        '/tmp/a.dart',
        r'tool\agentic_pdca\a.dart',
      ]) {
        repository.changed = [path];
        expect((await scan()).map((f) => f.code), contains('ALLOW_LIST'));
      }
      repository.changed = [];
      repository.dirty = ['README.md'];
      expect((await scan()).map((f) => f.code), contains('DIRTY_TRACKED_PATH'));
      repository.dirty = ['windows/flutter/generated_plugins.cmake'];
      expect(await scan(), isEmpty);
      expect(
        scanner.generatedSideEffects(
          await repository.readFacts(approvedBaseSha: sha),
        ),
        repository.dirty,
      );
    },
  );

  test(
    'CHECK-2 detects protected paths, deletion, weakening, secrets, and base drift',
    () {
      final findings = M1IntegrityScanner().scan(
        const M1IntegrityInput(
          baseSha: 'wrong',
          candidateSha: sha,
          expectedBaseSha: sha,
          expectedPaths: ['tool/agentic_pdca/**'],
          changedPaths: ['lib/main.dart', 'pubspec.yaml'],
          deletedTestPaths: ['test/removed_test.dart'],
          fileContents: {
            'test/example.dart': 'expect(value, isNot(true));',
            'docs/example.md': 'token=ghp_example_secret',
          },
        ),
      );
      expect(findings.map((finding) => finding.code), contains('WRONG_BASE'));
      expect(
        findings.map((finding) => finding.code),
        contains('PROTECTED_PATH'),
      );
      expect(
        findings.map((finding) => finding.code),
        contains('TEST_DELETION'),
      );
      expect(
        findings.map((finding) => finding.code),
        contains('ASSERTION_WEAKENING'),
      );
      expect(findings.map((finding) => finding.code), contains('SECRET_LIKE'));
    },
  );

  test(
    'ACT routes only objective mechanical outcomes and escalates ambiguity',
    () {
      const router = M1ActRouter();
      expect(
        router.route(
          const M1ActEvidence(
            failureClass: M1FailureClass.formatting,
            candidateSha: sha,
            evidence: 'formatter red',
          ),
        ),
        M1ActRoute.format,
      );
      expect(
        router.route(
          const M1ActEvidence(
            failureClass: M1FailureClass.simpleAnalyzerIssue,
            candidateSha: sha,
            evidence: 'import issue',
          ),
        ),
        M1ActRoute.simpleAnalyzerFix,
      );
      expect(
        router.route(
          const M1ActEvidence(
            failureClass: M1FailureClass.safeHarness,
            candidateSha: sha,
            evidence: 'safe harness issue',
          ),
        ),
        M1ActRoute.safeTestHarnessFix,
      );
      expect(
        router.route(
          const M1ActEvidence(
            failureClass: M1FailureClass.transientInfrastructure,
            candidateSha: sha,
            evidence: 'transient environment',
          ),
        ),
        M1ActRoute.retry,
      );
      for (final failureClass in [
        M1FailureClass.featureBehavior,
        M1FailureClass.dependency,
        M1FailureClass.ambiguous,
      ]) {
        expect(
          router.route(
            M1ActEvidence(
              failureClass: failureClass,
              candidateSha: sha,
              evidence: 'escalate',
            ),
          ),
          M1ActRoute.escalate,
        );
      }
    },
  );

  test(
    'central budget survives second controller and writer change; retry unchanged, repair consumes one',
    () {
      final store = M1RepairBudgetStore();
      final snapshot = ControlPlaneSnapshot(
        maturity: 'M0_OBSERVATION',
        governanceVersion: 'v1.0',
        governanceSha: sha,
        observedAt: DateTime.utc(2026, 9, 21),
        tasks: const [],
        taskStates: const [],
        taskStateEvidence: const [],
        lineages: const [],
        authoritativeEvents: const [],
        eventEvidence: const [],
        repairBudgets: [
          RepairBudgetSnapshot(
            lineageId: 'LINEAGE-1',
            mechanicalRemaining: 2,
            behavioralRemaining: 0,
            architectureRemaining: 0,
            observedAt: DateTime.utc(2026, 9, 21),
          ),
        ],
        branchHeads: const [],
        writerLeases: const [],
        cancellations: const [],
        evidenceReferences: const [],
        humanApprovals: const [],
        writerLeaseEvidence: const [],
      );
      store.initialize(snapshot, 'LINEAGE-1');
      final ledger = M1RepairLedger(store: store, lineageId: 'LINEAGE-1');
      final retry = ledger.record(
        lineageId: 'LINEAGE-1',
        failureClass: M1FailureClass.transientInfrastructure,
        parentCandidateSha: sha,
        candidateSha: sha,
        retry: true,
        evidence: 'same-SHA retry',
        timestamp: DateTime.utc(2026, 9, 21),
      );
      final repair = ledger.record(
        lineageId: 'LINEAGE-1',
        failureClass: M1FailureClass.formatting,
        parentCandidateSha: sha,
        candidateSha: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        retry: false,
        evidence: 'formatter repair',
        timestamp: DateTime.utc(2026, 9, 21),
      );
      expect(retry.attemptType, 'RETRY');
      expect(repair.attemptType, 'REPAIR');
      expect(retry.remainingBudget, 2);
      expect(repair.remainingBudget, 1);
      expect(ledger.remaining('LINEAGE-1'), 1);
      final secondStore = M1RepairBudgetStore()
        ..initialize(snapshot, 'LINEAGE-1');
      final secondWriter = M1RepairLedger(
        store: secondStore,
        lineageId: 'LINEAGE-1',
      );
      expect(secondWriter.remaining('LINEAGE-1'), 1);
      expect(secondWriter.entries, hasLength(2));
      expect(
        () => M1RepairLedger(store: secondStore, lineageId: 'unknown'),
        throwsStateError,
      );
      expect(
        () => secondWriter.record(
          lineageId: 'LINEAGE-1',
          failureClass: M1FailureClass.formatting,
          parentCandidateSha: sha,
          candidateSha: sha,
          retry: false,
          evidence: 'unchanged repair',
          timestamp: DateTime.utc(2026),
        ),
        throwsStateError,
      );
      expect(secondWriter.remaining('LINEAGE-1'), 1);
    },
  );
}
