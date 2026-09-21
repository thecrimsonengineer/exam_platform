import 'm1_mechanical_models.dart';

final class M1MechanicalEligibilityClassifier {
  static const Set<String> allowedActionNames = <String>{
    'formatting',
    'imports',
    'simple_analyzer_fixes',
    'safe_test_harness_corrections',
  };

  static const Set<String> forbiddenPathPrefixes = <String>{
    'lib/',
    'content/',
    'firebase/',
    'docs/agentic/v1/',
    '.github/',
  };

  M1EligibilityResult classify(M1MechanicalRequest request) {
    final actionClass = _parseActionClass(request.actionClass);
    if (actionClass == M1MechanicalActionClass.unknown) {
      return _rejected(actionClass, 'Unknown mechanical action class.');
    }
    if (actionClass == M1MechanicalActionClass.testWeakening) {
      return _rejected(
        actionClass,
        'Test weakening is never mechanical automation.',
      );
    }
    if (!_isDoOneClass(actionClass)) {
      return _escalated(
        actionClass,
        'Requested action is outside the M1 DO-1 mechanical scope.',
      );
    }
    if (!_isSha(request.baseSha)) {
      return _rejected(
        actionClass,
        'An exact 40-character base SHA is required.',
      );
    }
    if (request.taskId.trim().isEmpty || request.lineageId.trim().isEmpty) {
      return _rejected(
        actionClass,
        'Task and lineage identities are required.',
      );
    }
    if (request.allowedPaths.isEmpty) {
      return _rejected(actionClass, 'At least one allowed path is required.');
    }
    if (request.plannedCommand.trim().isEmpty) {
      return _rejected(actionClass, 'A planned mechanical action is required.');
    }
    if (request.expectedChangedPaths.isEmpty || request.requiredGates.isEmpty) {
      return _rejected(
        actionClass,
        'Expected changed paths and required gates are required.',
      );
    }
    final forbiddenPath = _firstForbiddenPath(request);
    if (forbiddenPath != null) {
      return _rejected(
        actionClass,
        'Path is outside the mechanical allow-list: ' + forbiddenPath,
      );
    }

    return M1EligibilityResult(
      disposition: M1EligibilityDisposition.accepted,
      actionClass: actionClass,
      reason: 'Eligible for a mechanical action plan only; nothing executed.',
      plan: M1MechanicalActionPlan(
        taskId: request.taskId,
        lineageId: request.lineageId,
        exactBaseSha: request.baseSha,
        allowedPaths: List.unmodifiable(request.allowedPaths),
        actionClass: actionClass,
        plannedCommand: request.plannedCommand,
        expectedChangedPaths: List.unmodifiable(request.expectedChangedPaths),
        requiredGates: List.unmodifiable(request.requiredGates),
      ),
    );
  }

  M1MechanicalActionClass _parseActionClass(String value) {
    switch (value) {
      case 'formatting':
        return M1MechanicalActionClass.formatting;
      case 'imports':
        return M1MechanicalActionClass.imports;
      case 'simple_analyzer_fixes':
        return M1MechanicalActionClass.simpleAnalyzerFixes;
      case 'safe_test_harness_corrections':
        return M1MechanicalActionClass.safeTestHarnessCorrections;
      case 'feature_behavior':
        return M1MechanicalActionClass.featureBehavior;
      case 'architecture':
        return M1MechanicalActionClass.architectureChange;
      case 'security':
        return M1MechanicalActionClass.securityChange;
      case 'backend':
        return M1MechanicalActionClass.backendChange;
      case 'test_weakening':
        return M1MechanicalActionClass.testWeakening;
      default:
        return M1MechanicalActionClass.unknown;
    }
  }

  bool _isDoOneClass(M1MechanicalActionClass actionClass) =>
      actionClass == M1MechanicalActionClass.formatting ||
      actionClass == M1MechanicalActionClass.imports ||
      actionClass == M1MechanicalActionClass.simpleAnalyzerFixes ||
      actionClass == M1MechanicalActionClass.safeTestHarnessCorrections;

  String? _firstForbiddenPath(M1MechanicalRequest request) {
    final paths = <String>[
      ...request.requestedPaths,
      ...request.expectedChangedPaths,
    ];
    for (final path in paths) {
      if (_isForbiddenPath(path) ||
          !_matchesAllowedPath(path, request.allowedPaths)) {
        return path;
      }
    }
    return null;
  }

  bool _isForbiddenPath(String path) =>
      forbiddenPathPrefixes.any(path.startsWith);

  bool _matchesAllowedPath(String path, List<String> allowedPaths) {
    for (final allowed in allowedPaths) {
      if (allowed.endsWith('/**') &&
          path.startsWith(allowed.substring(0, allowed.length - 2))) {
        return true;
      }
      if (path == allowed) {
        return true;
      }
    }
    return false;
  }

  bool _isSha(String value) => RegExp(r'^[0-9a-fA-F]{40}$').hasMatch(value);

  M1EligibilityResult _rejected(
    M1MechanicalActionClass actionClass,
    String reason,
  ) => M1EligibilityResult(
    disposition: M1EligibilityDisposition.rejected,
    actionClass: actionClass,
    reason: reason,
  );

  M1EligibilityResult _escalated(
    M1MechanicalActionClass actionClass,
    String reason,
  ) => M1EligibilityResult(
    disposition: M1EligibilityDisposition.escalated,
    actionClass: actionClass,
    reason: reason,
  );
}
