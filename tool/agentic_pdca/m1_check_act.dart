import 'dart:io';

import 'm0_models.dart';
import 'm1_path_guard.dart';
import 'm1_repository.dart';

enum M1CheckGate { format, analyze, test, architectureGate }

enum M1CheckResult { green, red, blocked }

final class M1CheckEvidence {
  const M1CheckEvidence({
    required this.checkId,
    required this.candidateSha,
    required this.gate,
    required this.command,
    required this.result,
    required this.duration,
    required this.evidence,
  });

  final String checkId;
  final String candidateSha;
  final M1CheckGate gate;
  final String command;
  final M1CheckResult result;
  final Duration duration;
  final String evidence;
}

final class M1DeterministicCheckRunner {
  M1DeterministicCheckRunner({
    required this.repository,
    required this.expectedCandidateSha,
    required this.approvedBaseSha,
    M1TrustedCommandRunner? commandRunner,
  }) : _commandRunner = commandRunner ?? M1ProcessCommandRunner(repository);
  final M1TrustedRepository repository;
  final String expectedCandidateSha;
  final String approvedBaseSha;
  final M1TrustedCommandRunner _commandRunner;
  Future<M1CheckEvidence> run({
    required String checkId,
    required M1CheckGate gate,
    required String validatorIdentity,
  }) async {
    final started = DateTime.now().toUtc();
    final before = await repository.readFacts(approvedBaseSha: approvedBaseSha);
    bool valid(M1RepositoryFacts facts) =>
        RegExp(r'^[0-9a-f]{40}$').hasMatch(expectedCandidateSha) &&
        RegExp(r'^[0-9a-f]{40}$').hasMatch(approvedBaseSha) &&
        facts.head == expectedCandidateSha &&
        facts.mergeBase == approvedBaseSha &&
        facts.dirtyTrackedPaths.every(
          const M1RepositoryPathGuard().isKnownGeneratedSideEffect,
        );
    final commandResult = valid(before)
        ? await _commandRunner.run(gate)
        : const M1CommandResult(
            exitCode: -1,
            stdout: '',
            stderr: 'Trusted repository precondition failed',
          );
    final after = await repository.readFacts(approvedBaseSha: approvedBaseSha);
    final generated = {
      ...before.dirtyTrackedPaths,
      ...after.dirtyTrackedPaths,
    }.where(const M1RepositoryPathGuard().isKnownGeneratedSideEffect).toList();
    return M1CheckEvidence(
      checkId: checkId,
      candidateSha: before.head,
      gate: gate,
      command: _commandFor(gate),
      result: !valid(before) || !valid(after)
          ? M1CheckResult.blocked
          : commandResult.exitCode == 0
          ? M1CheckResult.green
          : M1CheckResult.red,
      duration: DateTime.now().toUtc().difference(started),
      evidence:
          'validator=' +
          validatorIdentity +
          ';exit_code=' +
          commandResult.exitCode.toString() +
          ';generated_side_effects=' +
          generated.toString() +
          ';stdout=' +
          _summary(commandResult.stdout) +
          ';stderr=' +
          _summary(commandResult.stderr),
    );
  }

  String _commandFor(M1CheckGate gate) => switch (gate) {
    M1CheckGate.format => 'dart format --output=none --set-exit-if-changed',
    M1CheckGate.analyze => 'flutter analyze',
    M1CheckGate.test => 'flutter test test/agentic_pdca/',
    M1CheckGate.architectureGate => 'architecture gate',
  };

  String _summary(String value) =>
      value.length <= 512 ? value : value.substring(0, 512);
}

final class M1CommandResult {
  const M1CommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

abstract interface class M1TrustedCommandRunner {
  Future<M1CommandResult> run(M1CheckGate gate);
}

final class M1ProcessCommandRunner implements M1TrustedCommandRunner {
  const M1ProcessCommandRunner(this.repository);

  final M1TrustedRepository repository;

  @override
  Future<M1CommandResult> run(M1CheckGate gate) async {
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    final dart = flutterRoot == null
        ? Platform.resolvedExecutable
        : '$flutterRoot/bin/cache/dart-sdk/bin/dart' +
              (Platform.isWindows ? '.exe' : '');
    final executable = dart;
    final arguments = switch (gate) {
      M1CheckGate.format => const [
        'format',
        '--output=none',
        '--set-exit-if-changed',
        'tool/agentic_pdca',
        'test/agentic_pdca',
      ],
      M1CheckGate.analyze => const ['analyze'],
      M1CheckGate.test => const ['test', 'test/agentic_pdca/'],
      M1CheckGate.architectureGate => const [
        'test',
        'test/agentic_pdca/m1_architecture_gate_test.dart',
      ],
    };
    if (gate != M1CheckGate.format && flutterRoot == null) {
      throw StateError('Trusted Flutter SDK root is unavailable.');
    }
    final result = await Process.run(
      executable,
      gate == M1CheckGate.format
          ? arguments
          : <String>[
              '$flutterRoot/bin/cache/flutter_tools.snapshot',
              ...arguments,
            ],
      workingDirectory: repository.root,
      runInShell: false,
    );
    return M1CommandResult(
      exitCode: result.exitCode,
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
    );
  }
}

final class M1IntegrityInput {
  const M1IntegrityInput({
    required this.baseSha,
    required this.candidateSha,
    required this.expectedBaseSha,
    required this.expectedPaths,
    required this.changedPaths,
    required this.deletedTestPaths,
    required this.fileContents,
  });

  final String baseSha;
  final String candidateSha;
  final String expectedBaseSha;
  final List<String> expectedPaths;
  final List<String> changedPaths;
  final List<String> deletedTestPaths;
  final Map<String, String> fileContents;
}

final class M1IntegrityFinding {
  const M1IntegrityFinding(this.code, this.detail);
  final String code;
  final String detail;
}

final class M1IntegrityScanner {
  List<String> generatedSideEffects(M1RepositoryFacts facts) =>
      List.unmodifiable(
        facts.dirtyTrackedPaths.where(
          const M1RepositoryPathGuard().isKnownGeneratedSideEffect,
        ),
      );

  List<M1IntegrityFinding> scan(M1IntegrityInput input) {
    final findings = <M1IntegrityFinding>[];
    if (input.baseSha != input.expectedBaseSha) {
      findings.add(
        const M1IntegrityFinding('WRONG_BASE', 'Base SHA mismatch.'),
      );
    }
    for (final path in input.changedPaths) {
      if (const M1RepositoryPathGuard().isProtected(path)) {
        findings.add(M1IntegrityFinding('PROTECTED_PATH', path));
      }
      if (!const M1RepositoryPathGuard().isAllowed(path, input.expectedPaths)) {
        findings.add(M1IntegrityFinding('ALLOW_LIST', path));
      }
    }
    for (final path in input.deletedTestPaths) {
      findings.add(M1IntegrityFinding('TEST_DELETION', path));
    }
    for (final entry in input.fileContents.entries) {
      if (RegExp(
        r'(ghp_|github_pat_|AIza[0-9A-Za-z_-]{20,})',
        caseSensitive: false,
      ).hasMatch(entry.value)) {
        findings.add(M1IntegrityFinding('SECRET_LIKE', entry.key));
      }
      if (RegExp(
        r'expect\s*\([^\n]+\bisNot\s*\(true\)',
        caseSensitive: false,
      ).hasMatch(entry.value)) {
        findings.add(M1IntegrityFinding('ASSERTION_WEAKENING', entry.key));
      }
    }
    return List.unmodifiable(findings);
  }

  Future<List<M1IntegrityFinding>> scanRepository({
    required M1TrustedRepository repository,
    required String approvedBaseSha,
    required String candidateSha,
    required List<String> expectedPaths,
  }) async {
    final facts = await repository.readFacts(approvedBaseSha: approvedBaseSha);
    final findings = <M1IntegrityFinding>[];
    if (!_isSha(approvedBaseSha) || facts.mergeBase != approvedBaseSha) {
      findings.add(
        const M1IntegrityFinding(
          'WRONG_ANCESTRY',
          'Trusted merge-base mismatch.',
        ),
      );
    }
    if (!_isSha(candidateSha) || facts.head != candidateSha) {
      findings.add(
        const M1IntegrityFinding(
          'CANDIDATE_MISMATCH',
          'Trusted candidate HEAD mismatch.',
        ),
      );
    }
    for (final path in facts.dirtyTrackedPaths) {
      if (!const M1RepositoryPathGuard().isKnownGeneratedSideEffect(path)) {
        findings.add(M1IntegrityFinding('DIRTY_TRACKED_PATH', path));
      }
    }
    for (final path in facts.binaryPaths) {
      findings.add(M1IntegrityFinding('UNEXPECTED_BINARY', path));
    }
    findings.addAll(
      scan(
        M1IntegrityInput(
          baseSha: approvedBaseSha,
          candidateSha: candidateSha,
          expectedBaseSha: approvedBaseSha,
          expectedPaths: expectedPaths,
          changedPaths: facts.changedPaths,
          deletedTestPaths: facts.deletedTestPaths,
          fileContents: facts.fileContents,
        ),
      ),
    );
    return List.unmodifiable(findings);
  }

  bool _isSha(String value) => RegExp(r'^[0-9a-fA-F]{40}$').hasMatch(value);
}

enum M1FailureClass {
  formatting,
  importIssue,
  simpleAnalyzerIssue,
  safeHarness,
  transientInfrastructure,
  featureBehavior,
  architecture,
  security,
  dependency,
  testWeakening,
  ambiguous,
}

final class M1ActEvidence {
  const M1ActEvidence({
    required this.failureClass,
    required this.candidateSha,
    required this.evidence,
  });

  final M1FailureClass failureClass;
  final String candidateSha;
  final String evidence;
}

enum M1ActRoute {
  format,
  importFix,
  simpleAnalyzerFix,
  safeTestHarnessFix,
  retry,
  escalate,
}

final class M1RepairLedgerEntry {
  const M1RepairLedgerEntry({
    required this.lineageId,
    required this.failureClass,
    required this.parentCandidateSha,
    required this.attemptType,
    required this.remainingBudget,
    required this.evidence,
    required this.timestamp,
  });

  final String lineageId;
  final M1FailureClass failureClass;
  final String parentCandidateSha;
  final String attemptType;
  final int remainingBudget;
  final String evidence;
  final DateTime timestamp;
}

/// Trusted process-lifetime budget authority shared by all controllers.
/// Cross-process persistence is outside this M1 boundary.
final class M1RepairBudgetStore {
  M1RepairBudgetStore();
  static final Map<String, int> _balances = {};
  static final Map<String, List<M1RepairLedgerEntry>> _history = {};
  void initialize(ControlPlaneSnapshot trustedState, String lineageId) {
    final budgets = trustedState.repairBudgets.where(
      (b) => b.lineageId == lineageId,
    );
    if (budgets.length != 1 || budgets.single.mechanicalRemaining < 0) {
      throw StateError('Trusted repair budget is unavailable for lineage.');
    }
    _balances.putIfAbsent(lineageId, () => budgets.single.mechanicalRemaining);
    _history.putIfAbsent(lineageId, () => []);
  }

  int remaining(String lineageId) =>
      _balances[lineageId] ?? (throw StateError('Unknown repair lineage.'));
}

final class M1RepairLedger {
  M1RepairLedger({required M1RepairBudgetStore store, required this.lineageId})
    : _store = store {
    store.remaining(lineageId);
  }
  final M1RepairBudgetStore _store;
  final String lineageId;
  List<M1RepairLedgerEntry> get entries =>
      List.unmodifiable(M1RepairBudgetStore._history[lineageId]!);
  M1RepairLedgerEntry record({
    required String lineageId,
    required M1FailureClass failureClass,
    required String parentCandidateSha,
    required String candidateSha,
    required bool retry,
    required String evidence,
    required DateTime timestamp,
  }) {
    if (lineageId != this.lineageId) throw StateError('Wrong repair lineage.');
    final sha = RegExp(r'^[0-9a-f]{40}$');
    if (!sha.hasMatch(parentCandidateSha) ||
        !sha.hasMatch(candidateSha) ||
        (retry
            ? candidateSha != parentCandidateSha
            : candidateSha == parentCandidateSha)) {
      throw StateError(
        'RETRY requires same SHA; REPAIR requires a new candidate SHA.',
      );
    }
    final route = const M1ActRouter().route(
      M1ActEvidence(
        failureClass: failureClass,
        candidateSha: parentCandidateSha,
        evidence: evidence,
      ),
    );
    if (route == M1ActRoute.escalate ||
        (retry != (route == M1ActRoute.retry))) {
      throw StateError('Failure class does not authorize this attempt.');
    }
    final current = _store.remaining(lineageId);
    final remaining = retry ? current : current - 1;
    if (remaining < 0)
      throw StateError('Mechanical repair budget is exhausted.');
    M1RepairBudgetStore._balances[lineageId] = remaining;
    final entry = M1RepairLedgerEntry(
      lineageId: lineageId,
      failureClass: failureClass,
      parentCandidateSha: parentCandidateSha,
      attemptType: retry ? 'RETRY' : 'REPAIR',
      remainingBudget: remaining,
      evidence: evidence,
      timestamp: timestamp,
    );
    M1RepairBudgetStore._history[lineageId]!.add(entry);
    return entry;
  }

  int remaining(String lineageId) => _store.remaining(lineageId);
}

final class M1ActRouter {
  const M1ActRouter();

  M1ActRoute route(M1ActEvidence evidence) {
    switch (evidence.failureClass) {
      case M1FailureClass.formatting:
        return M1ActRoute.format;
      case M1FailureClass.importIssue:
        return M1ActRoute.importFix;
      case M1FailureClass.simpleAnalyzerIssue:
        return M1ActRoute.simpleAnalyzerFix;
      case M1FailureClass.safeHarness:
        return M1ActRoute.safeTestHarnessFix;
      case M1FailureClass.transientInfrastructure:
        return M1ActRoute.retry;
      case M1FailureClass.featureBehavior:
      case M1FailureClass.architecture:
      case M1FailureClass.security:
      case M1FailureClass.dependency:
      case M1FailureClass.testWeakening:
      case M1FailureClass.ambiguous:
        return M1ActRoute.escalate;
    }
  }
}
