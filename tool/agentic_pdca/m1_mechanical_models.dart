import 'dart:convert';

enum M1EligibilityDisposition { accepted, rejected, escalated }

enum M1MechanicalActionClass {
  formatting,
  imports,
  simpleAnalyzerFixes,
  safeTestHarnessCorrections,
  featureBehavior,
  architectureChange,
  securityChange,
  backendChange,
  testWeakening,
  unknown,
}

final class M1MechanicalRequest {
  const M1MechanicalRequest({
    required this.taskId,
    required this.lineageId,
    required this.baseSha,
    required this.allowedPaths,
    required this.requestedPaths,
    required this.actionClass,
    required this.plannedCommand,
    required this.expectedChangedPaths,
    required this.requiredGates,
  });

  final String taskId;
  final String lineageId;
  final String baseSha;
  final List<String> allowedPaths;
  final List<String> requestedPaths;
  final String actionClass;
  final String plannedCommand;
  final List<String> expectedChangedPaths;
  final List<String> requiredGates;
}

final class M1MechanicalActionPlan {
  const M1MechanicalActionPlan({
    required this.taskId,
    required this.lineageId,
    required this.exactBaseSha,
    required this.allowedPaths,
    required this.actionClass,
    required this.plannedCommand,
    required this.expectedChangedPaths,
    required this.requiredGates,
  });

  final String taskId;
  final String lineageId;
  final String exactBaseSha;
  final List<String> allowedPaths;
  final M1MechanicalActionClass actionClass;
  final String plannedCommand;
  final List<String> expectedChangedPaths;
  final List<String> requiredGates;

  Map<String, Object?> toJson() => <String, Object?>{
    'task_id': taskId,
    'lineage_id': lineageId,
    'exact_base_sha': exactBaseSha,
    'allowed_paths': allowedPaths,
    'action_class': actionClass.name,
    'planned_command': plannedCommand,
    'expected_changed_paths': expectedChangedPaths,
    'required_gates': requiredGates,
    'execution_planned_only': true,
  };
}

final class M1EligibilityResult {
  const M1EligibilityResult({
    required this.disposition,
    required this.actionClass,
    required this.reason,
    this.plan,
  });

  final M1EligibilityDisposition disposition;
  final M1MechanicalActionClass actionClass;
  final String reason;
  final M1MechanicalActionPlan? plan;

  bool get accepted => disposition == M1EligibilityDisposition.accepted;

  Map<String, Object?> toJson() => <String, Object?>{
    'disposition': disposition.name,
    'action_class': actionClass.name,
    'reason': reason,
    if (plan != null) 'plan': plan!.toJson(),
  };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}
