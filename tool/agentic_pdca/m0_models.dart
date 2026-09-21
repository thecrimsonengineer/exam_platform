import 'dart:convert';

enum ObservationDisposition {
  accepted,
  duplicateEventId,
  duplicateSemanticEvent,
  rejectedUntrustedIssuer,
  rejectedGovernanceMismatch,
  rejectedUnknownTask,
  rejectedUnknownLineage,
  ignoredStaleEvent,
  invalidObservedState,
  invalidObservedTransition,
}

enum ControlPlaneCapability {
  dispatchWriter,
  mutateRepository,
  issueWriterLease,
  routeRepair,
  approveWaiver,
  closePhase,
  judgeCodeQuality,
}

final class ObservationResult {
  const ObservationResult({
    required this.disposition,
    required this.reason,
    this.eventId,
    this.semanticKey,
  });

  final ObservationDisposition disposition;
  final String reason;
  final String? eventId;
  final String? semanticKey;

  bool get accepted => disposition == ObservationDisposition.accepted;

  Map<String, Object?> toJson() => <String, Object?>{
    'disposition': disposition.name,
    'reason': reason,
    if (eventId != null) 'event_id': eventId,
    if (semanticKey != null) 'semantic_key': semanticKey,
  };
}

final class PlanTaskSnapshot {
  const PlanTaskSnapshot({
    required this.taskId,
    required this.phaseId,
    required this.baseBranch,
    required this.baseSha,
    required this.riskClass,
    required this.allowedPaths,
    required this.forbiddenPaths,
    required this.requiredTests,
    required this.stopConditions,
    required this.governanceVersion,
    required this.observedAt,
  });

  final String taskId;
  final String phaseId;
  final String baseBranch;
  final String baseSha;
  final String riskClass;
  final List<String> allowedPaths;
  final List<String> forbiddenPaths;
  final List<String> requiredTests;
  final List<String> stopConditions;
  final String governanceVersion;
  final DateTime observedAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'task_id': taskId,
    'phase_id': phaseId,
    'base_branch': baseBranch,
    'base_sha': baseSha,
    'risk_class': riskClass,
    'allowed_paths': allowedPaths,
    'forbidden_paths': forbiddenPaths,
    'required_tests': requiredTests,
    'stop_conditions': stopConditions,
    'governance_version': governanceVersion,
    'observed_at': observedAt.toUtc().toIso8601String(),
  };
}

final class TaskStateSnapshot {
  const TaskStateSnapshot({
    required this.taskId,
    required this.state,
    required this.observedAt,
  });

  final String taskId;
  final String state;
  final DateTime observedAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'task_id': taskId,
    'state': state,
    'observed_at': observedAt.toUtc().toIso8601String(),
  };
}

final class LineageSnapshot {
  const LineageSnapshot({
    required this.taskId,
    required this.lineageId,
    required this.currentSha,
    required this.lineageGeneration,
    required this.candidateSequence,
    required this.governanceVersion,
    required this.observedAt,
  });

  final String taskId;
  final String lineageId;
  final String currentSha;
  final int lineageGeneration;
  final int candidateSequence;
  final String governanceVersion;
  final DateTime observedAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'task_id': taskId,
    'lineage_id': lineageId,
    'current_sha': currentSha,
    'lineage_generation': lineageGeneration,
    'candidate_sequence': candidateSequence,
    'governance_version': governanceVersion,
    'observed_at': observedAt.toUtc().toIso8601String(),
  };
}

final class AuthoritativeEvent {
  const AuthoritativeEvent({
    required this.eventId,
    required this.eventType,
    required this.sourceSystem,
    required this.taskId,
    required this.lineageId,
    required this.candidateSha,
    required this.validationScope,
    required this.checkAttempt,
    required this.lineageGeneration,
    required this.candidateSequence,
    required this.state,
    required this.riskClass,
    required this.evidenceBundleRef,
    required this.governanceVersion,
    required this.timestamp,
    this.workflowRunId,
  });

  final String eventId;
  final String eventType;
  final String sourceSystem;
  final String taskId;
  final String lineageId;
  final String candidateSha;
  final String validationScope;
  final String? workflowRunId;
  final int checkAttempt;
  final int lineageGeneration;
  final int candidateSequence;
  final String state;
  final String riskClass;
  final String evidenceBundleRef;
  final String governanceVersion;
  final DateTime timestamp;

  String semanticMaterial() => <Object?>[
    sourceSystem,
    taskId,
    lineageId,
    candidateSha,
    validationScope,
    workflowRunId ?? '',
    checkAttempt,
  ].join('\u001f');

  Map<String, Object?> toJson() => <String, Object?>{
    'event_id': eventId,
    'event_type': eventType,
    'source_system': sourceSystem,
    'task_id': taskId,
    'lineage_id': lineageId,
    'candidate_sha': candidateSha,
    'validation_scope': validationScope,
    if (workflowRunId != null) 'workflow_run_id': workflowRunId,
    'check_attempt': checkAttempt,
    'lineage_generation': lineageGeneration,
    'candidate_sequence': candidateSequence,
    'state': state,
    'risk_class': riskClass,
    'evidence_bundle_ref': evidenceBundleRef,
    'governance_version': governanceVersion,
    'timestamp': timestamp.toUtc().toIso8601String(),
  };
}

final class RepairBudgetSnapshot {
  const RepairBudgetSnapshot({
    required this.lineageId,
    required this.mechanicalRemaining,
    required this.behavioralRemaining,
    required this.architectureRemaining,
    required this.observedAt,
  });

  final String lineageId;
  final int mechanicalRemaining;
  final int behavioralRemaining;
  final int architectureRemaining;
  final DateTime observedAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'lineage_id': lineageId,
    'mechanical_remaining': mechanicalRemaining,
    'behavioral_remaining': behavioralRemaining,
    'architecture_remaining': architectureRemaining,
    'observed_at': observedAt.toUtc().toIso8601String(),
  };
}

final class BranchHeadSnapshot {
  const BranchHeadSnapshot({
    required this.branch,
    required this.expectedHead,
    required this.observedHead,
    required this.observedAt,
    this.ownerTaskId,
  });

  final String branch;
  final String expectedHead;
  final String observedHead;
  final String? ownerTaskId;
  final DateTime observedAt;

  bool get matchesExpected => expectedHead == observedHead;

  Map<String, Object?> toJson() => <String, Object?>{
    'branch': branch,
    'expected_head': expectedHead,
    'observed_head': observedHead,
    'matches_expected': matchesExpected,
    if (ownerTaskId != null) 'owner_task_id': ownerTaskId,
    'observed_at': observedAt.toUtc().toIso8601String(),
  };
}

final class WriterLeaseSnapshot {
  const WriterLeaseSnapshot({
    required this.writerLeaseId,
    required this.lineageId,
    required this.branch,
    required this.agentPrincipal,
    required this.fencingToken,
    required this.expectedHead,
    required this.active,
    required this.expiresAt,
    required this.observedAt,
  });

  final String writerLeaseId;
  final String lineageId;
  final String branch;
  final String agentPrincipal;
  final int fencingToken;
  final String expectedHead;
  final bool active;
  final DateTime expiresAt;
  final DateTime observedAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'writer_lease_id': writerLeaseId,
    'lineage_id': lineageId,
    'branch': branch,
    'agent_principal': agentPrincipal,
    'fencing_token': fencingToken,
    'expected_head': expectedHead,
    'active': active,
    'expires_at': expiresAt.toUtc().toIso8601String(),
    'observed_at': observedAt.toUtc().toIso8601String(),
  };
}

final class CancellationSnapshot {
  const CancellationSnapshot({
    required this.lineageId,
    required this.mode,
    required this.reason,
    required this.observedAt,
  });

  final String lineageId;
  final String mode;
  final String reason;
  final DateTime observedAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'lineage_id': lineageId,
    'mode': mode,
    'reason': reason,
    'observed_at': observedAt.toUtc().toIso8601String(),
  };
}

final class EvidenceReferenceSnapshot {
  const EvidenceReferenceSnapshot({
    required this.referenceId,
    required this.uri,
    required this.contentHash,
    required this.observedAt,
  });

  final String referenceId;
  final String uri;
  final String contentHash;
  final DateTime observedAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'reference_id': referenceId,
    'uri': uri,
    'content_hash': contentHash,
    'observed_at': observedAt.toUtc().toIso8601String(),
  };
}

final class HumanApprovalSnapshot {
  const HumanApprovalSnapshot({
    required this.approvalId,
    required this.approvalType,
    required this.subjectId,
    required this.exactShaOrObject,
    required this.planRevision,
    required this.governanceVersion,
    required this.issuer,
    required this.issuedAt,
    required this.status,
    this.expiresAt,
    this.revokedAt,
  });

  final String approvalId;
  final String approvalType;
  final String subjectId;
  final String exactShaOrObject;
  final String planRevision;
  final String governanceVersion;
  final String issuer;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final String status;

  bool isValidAt(DateTime trustedNow, {String? expectedGovernanceVersion}) {
    final now = trustedNow.toUtc();
    return status == 'ACTIVE' &&
        (expectedGovernanceVersion == null ||
            governanceVersion == expectedGovernanceVersion) &&
        (expiresAt == null || now.isBefore(expiresAt!.toUtc())) &&
        (revokedAt == null || now.isBefore(revokedAt!.toUtc()));
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'approval_id': approvalId,
    'approval_type': approvalType,
    'subject_id': subjectId,
    'exact_sha_or_object': exactShaOrObject,
    'plan_revision': planRevision,
    'governance_version': governanceVersion,
    'issuer': issuer,
    'issued_at': issuedAt.toUtc().toIso8601String(),
    if (expiresAt != null) 'expires_at': expiresAt!.toUtc().toIso8601String(),
    if (revokedAt != null) 'revoked_at': revokedAt!.toUtc().toIso8601String(),
    'status': status,
  };
}

final class ControlPlaneSnapshot {
  const ControlPlaneSnapshot({
    required this.maturity,
    required this.governanceVersion,
    required this.governanceSha,
    required this.observedAt,
    required this.tasks,
    required this.taskStates,
    required this.taskStateEvidence,
    required this.lineages,
    required this.authoritativeEvents,
    required this.eventEvidence,
    required this.repairBudgets,
    required this.branchHeads,
    required this.writerLeases,
    required this.cancellations,
    required this.evidenceReferences,
    required this.humanApprovals,
    required this.writerLeaseEvidence,
  });

  final String maturity;
  final String governanceVersion;
  final String governanceSha;
  final DateTime observedAt;
  final List<PlanTaskSnapshot> tasks;
  final List<TaskStateSnapshot> taskStates;
  final List<TaskStateSnapshot> taskStateEvidence;
  final List<LineageSnapshot> lineages;
  final List<AuthoritativeEvent> authoritativeEvents;
  final List<AuthoritativeEvent> eventEvidence;
  final List<RepairBudgetSnapshot> repairBudgets;
  final List<BranchHeadSnapshot> branchHeads;
  final List<WriterLeaseSnapshot> writerLeases;
  final List<CancellationSnapshot> cancellations;
  final List<EvidenceReferenceSnapshot> evidenceReferences;
  final List<HumanApprovalSnapshot> humanApprovals;
  final List<WriterLeaseSnapshot> writerLeaseEvidence;

  Map<String, Object?> toJson() => <String, Object?>{
    'maturity': maturity,
    'governance_version': governanceVersion,
    'governance_sha': governanceSha,
    'observation_only': true,
    'observed_at': observedAt.toUtc().toIso8601String(),
    'tasks': tasks.map((value) => value.toJson()).toList(),
    'task_states': taskStates.map((value) => value.toJson()).toList(),
    'task_state_evidence': taskStateEvidence
        .map((value) => value.toJson())
        .toList(),
    'lineages': lineages.map((value) => value.toJson()).toList(),
    'authoritative_events': authoritativeEvents
        .map((value) => value.toJson())
        .toList(),
    'event_evidence': eventEvidence.map((value) => value.toJson()).toList(),
    'repair_budgets': repairBudgets.map((value) => value.toJson()).toList(),
    'branch_heads': branchHeads.map((value) => value.toJson()).toList(),
    'writer_leases': writerLeases.map((value) => value.toJson()).toList(),
    'cancellations': cancellations.map((value) => value.toJson()).toList(),
    'evidence_references': evidenceReferences
        .map((value) => value.toJson())
        .toList(),
    'human_approvals': humanApprovals.map((value) => value.toJson()).toList(),
    'writer_lease_evidence': writerLeaseEvidence
        .map((value) => value.toJson())
        .toList(),
  };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}
