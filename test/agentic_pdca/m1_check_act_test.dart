import 'package:flutter_test/flutter_test.dart';

import '../../tool/agentic_pdca/m1_check_act.dart';

void main() {
  const sha = '94d060e37358915d03a2375ebc3af54808633e15';

  test(
    'CHECK binds evidence to exact SHA and accepts known generated side effects',
    () {
      const runner = M1DeterministicCheckRunner();
      final result = runner.evaluate(
        checkId: 'CHECK-1-FORMAT',
        candidateSha: sha,
        expectedSha: sha,
        gate: M1CheckGate.format,
        command: 'dart format --output=none --set-exit-if-changed',
        gatePassed: true,
        duration: Duration.zero,
        dirtyPaths: const ['linux/flutter/generated_plugins.cmake'],
      );
      expect(result.result, M1CheckResult.green);
    },
  );

  test('CHECK blocks SHA drift and unrelated dirty paths', () {
    const runner = M1DeterministicCheckRunner();
    final wrongSha = runner.evaluate(
      checkId: 'CHECK-1-TEST',
      candidateSha: 'wrong',
      expectedSha: sha,
      gate: M1CheckGate.test,
      command: 'flutter test',
      gatePassed: true,
      duration: Duration.zero,
      dirtyPaths: const [],
    );
    final dirty = runner.evaluate(
      checkId: 'CHECK-1-TEST',
      candidateSha: sha,
      expectedSha: sha,
      gate: M1CheckGate.test,
      command: 'flutter test',
      gatePassed: true,
      duration: Duration.zero,
      dirtyPaths: const ['lib/main.dart'],
    );
    expect(wrongSha.result, M1CheckResult.blocked);
    expect(dirty.result, M1CheckResult.blocked);
  });

  test('CHECK reports deterministic red results without repairing', () {
    const runner = M1DeterministicCheckRunner();
    final result = runner.evaluate(
      checkId: 'CHECK-1-ANALYZE',
      candidateSha: sha,
      expectedSha: sha,
      gate: M1CheckGate.analyze,
      command: 'flutter analyze',
      gatePassed: false,
      duration: Duration.zero,
      dirtyPaths: const [],
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
      expect(router.route('formatter_red'), M1ActRoute.format);
      expect(router.route('import_issue'), M1ActRoute.importFix);
      expect(
        router.route('simple_analyzer_issue'),
        M1ActRoute.simpleAnalyzerFix,
      );
      expect(router.route('safe_harness_issue'), M1ActRoute.safeTestHarnessFix);
      expect(router.route('transient_environment'), M1ActRoute.retry);
      expect(router.route('feature_defect'), M1ActRoute.escalate);
      expect(router.route('dependency_change'), M1ActRoute.escalate);
    },
  );
}
