import 'package:flutter_test/flutter_test.dart';

import '../../tool/agentic_pdca/m0_models.dart';
import '../../tool/agentic_pdca/m1_check_act.dart';

final class FakeRunner implements M1TrustedCommandRunner {
  FakeRunner(this.result);

  final M1CommandResult result;

  @override
  Future<M1CommandResult> run(M1CheckGate gate) async => result;
}

void main() {
  const sha = '94d060e37358915d03a2375ebc3af54808633e15';

  test(
    'CHECK binds evidence to exact SHA and accepts known generated side effects',
    () async {
      final runner = M1DeterministicCheckRunner(
        commandRunner: FakeRunner(
          const M1CommandResult(exitCode: 0, stdout: 'ok', stderr: ''),
        ),
      );
      final result = await runner.run(
        checkId: 'CHECK-1-FORMAT',
        candidateSha: sha,
        expectedSha: sha,
        gate: M1CheckGate.format,
        dirtyPaths: const ['linux/flutter/generated_plugins.cmake'],
        validatorIdentity: 'test-validator',
      );
      expect(result.result, M1CheckResult.green);
    },
  );

  test('CHECK blocks SHA drift and unrelated dirty paths', () async {
    final runner = M1DeterministicCheckRunner(
      commandRunner: FakeRunner(
        const M1CommandResult(exitCode: 0, stdout: 'ok', stderr: ''),
      ),
    );
    final wrongSha = await runner.run(
      checkId: 'CHECK-1-TEST',
      candidateSha: 'wrong',
      expectedSha: sha,
      gate: M1CheckGate.test,
      dirtyPaths: const [],
      validatorIdentity: 'test-validator',
    );
    final dirty = await runner.run(
      checkId: 'CHECK-1-TEST',
      candidateSha: sha,
      expectedSha: sha,
      gate: M1CheckGate.test,
      dirtyPaths: const ['lib/main.dart'],
      validatorIdentity: 'test-validator',
    );
    expect(wrongSha.result, M1CheckResult.blocked);
    expect(dirty.result, M1CheckResult.blocked);
  });

  test('CHECK reports deterministic red results without repairing', () async {
    final runner = M1DeterministicCheckRunner(
      commandRunner: FakeRunner(
        const M1CommandResult(exitCode: 1, stdout: '', stderr: 'failed'),
      ),
    );
    final result = await runner.run(
      checkId: 'CHECK-1-ANALYZE',
      candidateSha: sha,
      expectedSha: sha,
      gate: M1CheckGate.analyze,
      dirtyPaths: const [],
      validatorIdentity: 'test-validator',
    );
    expect(result.result, M1CheckResult.red);
  });

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

  test('ACT ledger does not consume budget for retry', () {
    final ledger = M1RepairLedger(
      trustedState: ControlPlaneSnapshot(
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
      ),
      lineageId: 'LINEAGE-1',
    );
    final retry = ledger.record(
      lineageId: 'LINEAGE-1',
      failureClass: M1FailureClass.transientInfrastructure,
      parentCandidateSha: sha,
      retry: true,
      evidence: 'same-SHA retry',
      timestamp: DateTime.utc(2026, 9, 21),
    );
    final repair = ledger.record(
      lineageId: 'LINEAGE-1',
      failureClass: M1FailureClass.formatting,
      parentCandidateSha: sha,
      retry: false,
      evidence: 'formatter repair',
      timestamp: DateTime.utc(2026, 9, 21),
    );
    expect(retry.attemptType, 'RETRY');
    expect(repair.attemptType, 'REPAIR');
    expect(ledger.remaining('LINEAGE-1'), 1);
  });
}
