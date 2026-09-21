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
  const M1DeterministicCheckRunner();

  M1CheckEvidence evaluate({
    required String checkId,
    required String candidateSha,
    required String expectedSha,
    required M1CheckGate gate,
    required String command,
    required bool gatePassed,
    required Duration duration,
    required List<String> dirtyPaths,
  }) {
    final unexpected = dirtyPaths
        .where((path) => !_isKnownGeneratedSideEffect(path))
        .toList();
    final result = candidateSha != expectedSha || unexpected.isNotEmpty
        ? M1CheckResult.blocked
        : gatePassed
        ? M1CheckResult.green
        : M1CheckResult.red;
    final evidence = candidateSha != expectedSha
        ? 'Candidate SHA does not match the bound SHA.'
        : unexpected.isNotEmpty
        ? 'Unexpected dirty paths: ' + unexpected.join(', ')
        : gatePassed
        ? 'Deterministic gate passed.'
        : 'Deterministic gate failed.';
    return M1CheckEvidence(
      checkId: checkId,
      candidateSha: candidateSha,
      gate: gate,
      command: command,
      result: result,
      duration: duration,
      evidence: evidence,
    );
  }

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

enum M1ActRoute {
  format,
  importFix,
  simpleAnalyzerFix,
  safeTestHarnessFix,
  retry,
  escalate,
}

final class M1ActRouter {
  const M1ActRouter();

  M1ActRoute route(String outcome) {
    switch (outcome) {
      case 'formatter_red':
        return M1ActRoute.format;
      case 'import_issue':
        return M1ActRoute.importFix;
      case 'simple_analyzer_issue':
        return M1ActRoute.simpleAnalyzerFix;
      case 'safe_harness_issue':
        return M1ActRoute.safeTestHarnessFix;
      case 'transient_environment':
        return M1ActRoute.retry;
      default:
        return M1ActRoute.escalate;
    }
  }
}
