import 'dart:io';

import 'm0_models.dart';
import 'm1_mechanical_models.dart';
import 'm1_path_guard.dart';

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

final class M1MechanicalAuthorityRequest {
  const M1MechanicalAuthorityRequest({
    required this.taskId,
    required this.lineageId,
    required this.baseSha,
    required this.expectedHead,
    required this.branch,
    required this.allowedPaths,
    required this.expectedChangedPaths,
    required this.actionClass,
    required this.requiredGates,
    required this.writerLeaseId,
    required this.writerIdentity,
    required this.fencingToken,
  });

  final String taskId;
  final String lineageId;
  final String baseSha;
  final String expectedHead;
  final String branch;
  final List<String> allowedPaths;
  final List<String> expectedChangedPaths;
  final String actionClass;
  final List<String> requiredGates;
  final String writerLeaseId;
  final String writerIdentity;
  final int fencingToken;
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
  M1MechanicalAuthority({
    required this.trustedState,
    required Map<String, String> actualHeads,
    DateTime Function()? trustedClock,
  }) : _actualHeads = Map.unmodifiable(actualHeads),
       _trustedClock = trustedClock ?? (() => DateTime.now().toUtc());

  final ControlPlaneSnapshot trustedState;
  final Map<String, String> _actualHeads;
  final DateTime Function() _trustedClock;
  final M1RepositoryPathGuard _pathGuard = const M1RepositoryPathGuard();

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
    final actualHead = _actualHeads[request.branch];
    if (actualHead == null || request.expectedHead != actualHead) {
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
    final lineages = trustedState.lineages.where(
      (value) => value.lineageId == request.lineageId,
    );
    if (lineages.length != 1 || lineages.single.taskId != request.taskId) {
      return _deny(
        actionClass,
        'Trusted lineage state does not match request.',
      );
    }
    final leases = trustedState.writerLeases.where(
      (value) => value.writerLeaseId == request.writerLeaseId,
    );
    final now = _trustedClock().toUtc();
    if (leases.length != 1 ||
        leases.single.lineageId != request.lineageId ||
        leases.single.branch != request.branch ||
        leases.single.agentPrincipal != request.writerIdentity ||
        leases.single.fencingToken != request.fencingToken ||
        !leases.single.active ||
        !leases.single.expiresAt.toUtc().isAfter(now) ||
        (leases.single.revokedAt != null &&
            !now.isBefore(leases.single.revokedAt!.toUtc())) ||
        leases.single.expectedHead != request.expectedHead) {
      return _deny(
        actionClass,
        'Trusted writer lease identity or fencing state is invalid.',
      );
    }
    for (final path in request.expectedChangedPaths) {
      if (_pathGuard.isProtected(path) ||
          !_pathGuard.isAllowed(path, request.allowedPaths)) {
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

  Future<M1ExecutionRecord> executeFormat({
    required M1MechanicalAuthority authority,
    required M1MechanicalAuthorityRequest request,
    required String actionId,
  }) async {
    final authorization = authority.authorize(request);
    if (!authorization.authorized ||
        authorization.actionClass != M1MechanicalClass.format) {
      throw StateError('FORMAT execution requires valid DO-1 authority.');
    }
    final guard = const M1RepositoryPathGuard();
    final paths = request.expectedChangedPaths
        .map(guard.canonicalize)
        .whereType<String>()
        .toList();
    if (paths.length != request.expectedChangedPaths.length || paths.isEmpty) {
      throw ArgumentError('FORMAT paths must be canonical repository paths.');
    }
    final started = DateTime.now().toUtc();
    final result = await Process.run(_dartExecutable, <String>[
      'format',
      ...paths,
    ], runInShell: false);
    final finished = DateTime.now().toUtc();
    return record(
      taskId: request.taskId,
      actionId: actionId,
      actionClass: authorization.actionClass,
      baseSha: request.baseSha,
      preHead: request.expectedHead,
      postHead: request.expectedHead,
      paths: paths,
      operation: M1StructuredOperation.format,
      exitCode: result.exitCode as int,
      stdoutSummary: _summary(result.stdout),
      stderrSummary: _summary(result.stderr),
      duration: finished.difference(started),
      timestamp: finished,
    );
  }

  String _summary(Object value) {
    final text = value.toString();
    return text.length <= 512 ? text : text.substring(0, 512);
  }

  String get _dartExecutable {
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    if (flutterRoot != null && flutterRoot.isNotEmpty) {
      return '$flutterRoot${Platform.pathSeparator}bin${Platform.pathSeparator}cache'
          '${Platform.pathSeparator}dart-sdk${Platform.pathSeparator}bin'
          '${Platform.pathSeparator}dart${Platform.isWindows ? '.exe' : ''}';
    }
    return Platform.resolvedExecutable;
  }

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
