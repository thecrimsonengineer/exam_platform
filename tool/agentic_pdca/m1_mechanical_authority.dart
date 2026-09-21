import 'm1_mechanical_models.dart';

enum M1MechanicalClass {
  format,
  importFix,
  simpleAnalyzerFix,
  safeTestHarnessFix,
  featureBehavior,
  architecture,
  security,
  auth,
  backend,
  database,
  dependencyChange,
  governanceChange,
  testWeakening,
  unknown,
}

final class M1WriterLeaseState {
  const M1WriterLeaseState({
    required this.writerLeaseId,
    required this.writerIdentity,
    required this.fencingToken,
    required this.active,
  });

  final String writerLeaseId;
  final String writerIdentity;
  final int fencingToken;
  final bool active;
}

final class M1MechanicalAuthorityRequest {
  const M1MechanicalAuthorityRequest({
    required this.taskId,
    required this.lineageId,
    required this.baseSha,
    required this.expectedHead,
    required this.actualHead,
    required this.allowedPaths,
    required this.expectedChangedPaths,
    required this.actionClass,
    required this.requiredGates,
    required this.writerLeaseId,
    required this.writerIdentity,
    required this.fencingToken,
    required this.lease,
  });

  final String taskId;
  final String lineageId;
  final String baseSha;
  final String expectedHead;
  final String actualHead;
  final List<String> allowedPaths;
  final List<String> expectedChangedPaths;
  final String actionClass;
  final List<String> requiredGates;
  final String writerLeaseId;
  final String writerIdentity;
  final int fencingToken;
  final M1WriterLeaseState lease;
}

final class M1MechanicalAuthorityResult {
  const M1MechanicalAuthorityResult({
    required this.authorized,
    required this.actionClass,
    required this.reason,
  });

  final bool authorized;
  final M1MechanicalClass actionClass;
  final String reason;
}

final class M1MechanicalAuthority {
  M1MechanicalAuthorityResult authorize(M1MechanicalAuthorityRequest request) {
    final actionClass = _parse(request.actionClass);
    if (!_isAllowed(actionClass)) {
      return M1MechanicalAuthorityResult(
        authorized: false,
        actionClass: actionClass,
        reason: 'Action class is not authorized for DO-1.',
      );
    }
    if (!_isSha(request.baseSha) || request.expectedHead.isEmpty) {
      return _deny(
        actionClass,
        'Exact base SHA and expected HEAD are required.',
      );
    }
    if (request.expectedHead != request.actualHead) {
      return _deny(actionClass, 'Expected HEAD does not match actual HEAD.');
    }
    if (request.taskId.isEmpty ||
        request.lineageId.isEmpty ||
        request.requiredGates.isEmpty) {
      return _deny(
        actionClass,
        'Task, lineage and required gates are required.',
      );
    }
    if (request.writerLeaseId != request.lease.writerLeaseId ||
        request.writerIdentity != request.lease.writerIdentity ||
        request.fencingToken != request.lease.fencingToken ||
        !request.lease.active) {
      return _deny(
        actionClass,
        'Active writer identity or fencing state is invalid.',
      );
    }
    for (final path in request.expectedChangedPaths) {
      if (!_allowedPath(path, request.allowedPaths)) {
        return _deny(
          actionClass,
          'Changed path is outside the allow-list: ' + path,
        );
      }
    }
    return M1MechanicalAuthorityResult(
      authorized: true,
      actionClass: actionClass,
      reason: 'DO-1 authority is valid. No operation was executed.',
    );
  }

  M1MechanicalClass _parse(String value) {
    switch (value) {
      case 'FORMAT':
        return M1MechanicalClass.format;
      case 'IMPORT_FIX':
        return M1MechanicalClass.importFix;
      case 'SIMPLE_ANALYZER_FIX':
        return M1MechanicalClass.simpleAnalyzerFix;
      case 'SAFE_TEST_HARNESS_FIX':
        return M1MechanicalClass.safeTestHarnessFix;
      case 'FEATURE_BEHAVIOR':
        return M1MechanicalClass.featureBehavior;
      case 'ARCHITECTURE':
        return M1MechanicalClass.architecture;
      case 'SECURITY':
        return M1MechanicalClass.security;
      case 'AUTH':
        return M1MechanicalClass.auth;
      case 'BACKEND':
        return M1MechanicalClass.backend;
      case 'DATABASE':
        return M1MechanicalClass.database;
      case 'DEPENDENCY_CHANGE':
        return M1MechanicalClass.dependencyChange;
      case 'GOVERNANCE_CHANGE':
        return M1MechanicalClass.governanceChange;
      case 'TEST_WEAKENING':
        return M1MechanicalClass.testWeakening;
      default:
        return M1MechanicalClass.unknown;
    }
  }

  bool _isAllowed(M1MechanicalClass value) =>
      value == M1MechanicalClass.format ||
      value == M1MechanicalClass.importFix ||
      value == M1MechanicalClass.simpleAnalyzerFix ||
      value == M1MechanicalClass.safeTestHarnessFix;

  bool _allowedPath(String path, List<String> allowedPaths) {
    if (path.startsWith('lib/') ||
        path.startsWith('content/') ||
        path.startsWith('firebase/') ||
        path.startsWith('docs/agentic/v1/') ||
        path.startsWith('.github/') ||
        path == 'pubspec.yaml' ||
        path == 'pubspec.lock') {
      return false;
    }
    return allowedPaths.any(
      (allowed) =>
          (allowed.endsWith('/**') &&
              path.startsWith(allowed.substring(0, allowed.length - 2))) ||
          path == allowed,
    );
  }

  bool _isSha(String value) => RegExp(r'^[0-9a-fA-F]{40}$').hasMatch(value);

  M1MechanicalAuthorityResult _deny(
    M1MechanicalClass actionClass,
    String reason,
  ) => M1MechanicalAuthorityResult(
    authorized: false,
    actionClass: actionClass,
    reason: reason,
  );
}

enum M1StructuredOperation {
  format,
  importFix,
  simpleAnalyzerFix,
  safeTestHarnessFix,
}

final class M1ExecutionRecord {
  const M1ExecutionRecord({
    required this.taskId,
    required this.actionId,
    required this.actionClass,
    required this.baseSha,
    required this.preHead,
    required this.postHead,
    required this.paths,
    required this.operation,
    required this.exitCode,
    required this.stdoutSummary,
    required this.stderrSummary,
    required this.duration,
    required this.timestamp,
  });

  final String taskId;
  final String actionId;
  final M1MechanicalClass actionClass;
  final String baseSha;
  final String preHead;
  final String postHead;
  final List<String> paths;
  final M1StructuredOperation operation;
  final int exitCode;
  final String stdoutSummary;
  final String stderrSummary;
  final Duration duration;
  final DateTime timestamp;
}

final class M1MechanicalExecutor {
  const M1MechanicalExecutor();

  String commandFor(
    M1StructuredOperation operation,
    List<String> explicitPaths,
  ) {
    if (explicitPaths.isEmpty) {
      throw ArgumentError('Explicit paths are required.');
    }
    final paths = explicitPaths.map(_quotePath).join(' ');
    switch (operation) {
      case M1StructuredOperation.format:
        return 'dart format ' + paths;
      case M1StructuredOperation.importFix:
      case M1StructuredOperation.simpleAnalyzerFix:
      case M1StructuredOperation.safeTestHarnessFix:
        throw UnsupportedError(
          'Operation requires a reviewed structured fixer.',
        );
    }
  }

  M1ExecutionRecord record({
    required String taskId,
    required String actionId,
    required M1MechanicalClass actionClass,
    required String baseSha,
    required String preHead,
    required String postHead,
    required List<String> paths,
    required M1StructuredOperation operation,
    required int exitCode,
    required String stdoutSummary,
    required String stderrSummary,
    required Duration duration,
    required DateTime timestamp,
  }) => M1ExecutionRecord(
    taskId: taskId,
    actionId: actionId,
    actionClass: actionClass,
    baseSha: baseSha,
    preHead: preHead,
    postHead: postHead,
    paths: List.unmodifiable(paths),
    operation: operation,
    exitCode: exitCode,
    stdoutSummary: stdoutSummary,
    stderrSummary: stderrSummary,
    duration: duration,
    timestamp: timestamp,
  );

  String _quotePath(String path) {
    if (path.startsWith('lib/') ||
        path.startsWith('content/') ||
        path.startsWith('firebase/') ||
        path.startsWith('.github/') ||
        path == 'pubspec.yaml' ||
        path == 'pubspec.lock') {
      throw ArgumentError('Protected path cannot be executed: ' + path);
    }
    if (path.contains('"') || path.contains('\n')) {
      throw ArgumentError('Unsafe path cannot be executed.');
    }
    return '"' + path + '"';
  }
}
