import 'dart:io';

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
  const M1DeterministicCheckRunner({
    M1TrustedCommandRunner commandRunner = const M1ProcessCommandRunner(),
  }) : _commandRunner = commandRunner;

  final M1TrustedCommandRunner _commandRunner;

  Future<M1CheckEvidence> run({
    required String checkId,
    required String candidateSha,
    required String expectedSha,
    required M1CheckGate gate,
    required List<String> dirtyPaths,
    required String validatorIdentity,
  }) async {
    final command = _commandFor(gate);
    final started = DateTime.now().toUtc();
    final commandResult = await _commandRunner.run(gate);
    final finished = DateTime.now().toUtc();
    final unexpected = dirtyPaths
        .where((path) => !_isKnownGeneratedSideEffect(path))
        .toList();
    final result =
        candidateSha != expectedSha ||
            unexpected.isNotEmpty ||
            commandResult.exitCode != 0
        ? candidateSha != expectedSha || unexpected.isNotEmpty
              ? M1CheckResult.blocked
              : M1CheckResult.red
        : M1CheckResult.green;
    return M1CheckEvidence(
      checkId: checkId,
      candidateSha: candidateSha,
      gate: gate,
      command: command,
      result: result,
      duration: finished.difference(started),
      evidence:
          'validator=' +
          validatorIdentity +
          ';exit_code=' +
          commandResult.exitCode.toString() +
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

  bool _isKnownGeneratedSideEffect(String path) => <String>{
    'linux/flutter/generated_plugin_registrant.cc',
    'linux/flutter/generated_plugin_registrant.h',
    'linux/flutter/generated_plugins.cmake',
    'macos/Flutter/GeneratedPluginRegistrant.swift',
    'windows/flutter/generated_plugin_registrant.cc',
    'windows/flutter/generated_plugin_registrant.h',
    'windows/flutter/generated_plugins.cmake',
  }.contains(path);
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
  const M1ProcessCommandRunner();

  @override
  Future<M1CommandResult> run(M1CheckGate gate) async {
    final executable = switch (gate) {
      M1CheckGate.format => Platform.resolvedExecutable,
      M1CheckGate.analyze || M1CheckGate.test => 'flutter',
      M1CheckGate.architectureGate => throw UnsupportedError(
        'Architecture gate requires a trusted repository adapter.',
      ),
    };
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
      M1CheckGate.architectureGate => const <String>[],
    };
    final result = await Process.run(executable, arguments, runInShell: false);
    return M1CommandResult(
      exitCode: result.exitCode as int,
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
  static const Set<String> protectedPrefixes = <String>{
    'lib/',
    'content/',
    'firebase/',
    'docs/agentic/v1/',
    '.github/',
  };

  List<M1IntegrityFinding> scan(M1IntegrityInput input) {
    final findings = <M1IntegrityFinding>[];
    if (input.baseSha != input.expectedBaseSha) {
      findings.add(
        const M1IntegrityFinding('WRONG_BASE', 'Base SHA mismatch.'),
      );
    }
    for (final path in input.changedPaths) {
      if (protectedPrefixes.any(path.startsWith) ||
          path == 'pubspec.yaml' ||
          path == 'pubspec.lock') {
        findings.add(M1IntegrityFinding('PROTECTED_PATH', path));
      }
      if (!input.expectedPaths.contains(path)) {
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

final class M1RepairLedger {
  M1RepairLedger({required Map<String, int> budgets})
    : _budgets = Map<String, int>.from(budgets);

  final Map<String, int> _budgets;
  final List<M1RepairLedgerEntry> _entries = [];

  List<M1RepairLedgerEntry> get entries => List.unmodifiable(_entries);

  M1RepairLedgerEntry record({
    required String lineageId,
    required M1FailureClass failureClass,
    required String parentCandidateSha,
    required bool retry,
    required String evidence,
    required DateTime timestamp,
  }) {
    final current = _budgets[lineageId] ?? 0;
    final remaining = retry ? current : current - 1;
    if (remaining < 0) {
      throw StateError('Mechanical repair budget is exhausted.');
    }
    _budgets[lineageId] = remaining;
    final entry = M1RepairLedgerEntry(
      lineageId: lineageId,
      failureClass: failureClass,
      parentCandidateSha: parentCandidateSha,
      attemptType: retry ? 'RETRY' : 'REPAIR',
      remainingBudget: remaining,
      evidence: evidence,
      timestamp: timestamp,
    );
    _entries.add(entry);
    return entry;
  }

  int remaining(String lineageId) => _budgets[lineageId] ?? 0;
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
