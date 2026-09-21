import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'm0_models.dart';

final class M0ObservationControlPlane {
  M0ObservationControlPlane({
    required this.governanceVersion,
    required this.governanceSha,
    required Set<String> trustedIssuers,
    DateTime Function()? trustedClock,
  }) : _trustedIssuers = Set.unmodifiable(trustedIssuers),
       _trustedClock = trustedClock ?? (() => DateTime.now().toUtc());

  static const String maturity = 'M0_OBSERVATION';

  static const Set<String> taskStates = <String>{
    'TASK_QUEUED',
    'TASK_READY',
    'TASK_RUNNING',
    'TASK_BLOCKED',
    'TASK_HANDOFF_READY',
    'TASK_FAILED_SAFE',
    'TASK_CANCELLED',
  };

  static const Set<String> checkStates = <String>{
    'CHECK_NOT_READY',
    'CHECK_RED',
    'CHECK_REPAIRABLE',
    'CHECK_ESCALATE',
    'CHECK_CANDIDATE_GREEN',
    'CHECK_REVIEW_ACCEPTED',
    'CHECK_FINAL_GREEN',
  };

  final String governanceVersion;
  final String governanceSha;
  final Set<String> _trustedIssuers;
  final DateTime Function() _trustedClock;

  final Map<String, PlanTaskSnapshot> _tasks = {};
  final Map<String, TaskStateSnapshot> _taskStates = {};
  final List<TaskStateSnapshot> _taskStateEvidence = [];
  final Map<String, LineageSnapshot> _lineages = {};
  final Map<String, AuthoritativeEvent> _events = {};
  final Map<String, String> _semanticEvents = {};
  final List<AuthoritativeEvent> _eventEvidence = [];
  final Map<String, RepairBudgetSnapshot> _budgets = {};
  final Map<String, BranchHeadSnapshot> _branchHeads = {};
  final Map<String, WriterLeaseSnapshot> _leases = {};
  final List<WriterLeaseSnapshot> _leaseEvidence = [];
  final Map<String, CancellationSnapshot> _cancellations = {};
  final Map<String, EvidenceReferenceSnapshot> _evidence = {};
  final Map<String, HumanApprovalSnapshot> _approvals = {};

  bool permits(ControlPlaneCapability capability) => false;

  void observeTask(PlanTaskSnapshot task, {String state = 'TASK_QUEUED'}) {
    _requireGovernance(task.governanceVersion);
    if (!taskStates.contains(state)) {
      throw ArgumentError.value(state, 'state', 'Unknown TASK state');
    }
    _tasks[task.taskId] = task;
    final initialState = TaskStateSnapshot(
      taskId: task.taskId,
      state: state,
      observedAt: _trustedClock(),
    );
    _taskStates[task.taskId] = initialState;
    _taskStateEvidence.add(initialState);
  }

  ObservationResult observeTaskState({
    required String taskId,
    required String state,
  }) {
    if (!_tasks.containsKey(taskId)) {
      return const ObservationResult(
        disposition: ObservationDisposition.rejectedUnknownTask,
        reason: 'Task is not present in the M0 observed task registry.',
      );
    }
    if (!taskStates.contains(state)) {
      _taskStateEvidence.add(
        TaskStateSnapshot(
          taskId: taskId,
          state: state,
          observedAt: _trustedClock(),
        ),
      );
      return ObservationResult(
        disposition: ObservationDisposition.invalidObservedState,
        reason: 'Unknown TASK state: ' + state,
      );
    }
    final previous = _taskStates[taskId]!;
    final observed = TaskStateSnapshot(
      taskId: taskId,
      state: state,
      observedAt: _trustedClock(),
    );
    _taskStateEvidence.add(observed);
    if (!_validTaskTransition(previous.state, state)) {
      return ObservationResult(
        disposition: ObservationDisposition.invalidObservedTransition,
        reason:
            'Impossible observed TASK transition: ' +
            previous.state +
            ' -> ' +
            state +
            '.',
      );
    }
    _taskStates[taskId] = observed;
    return const ObservationResult(
      disposition: ObservationDisposition.accepted,
      reason: 'TASK state observed. No transition was executed.',
    );
  }

  void observeLineage(LineageSnapshot lineage) {
    _requireGovernance(lineage.governanceVersion);
    if (!_tasks.containsKey(lineage.taskId)) {
      throw StateError(
        'Cannot observe lineage for unknown task: ' + lineage.taskId,
      );
    }
    final existing = _lineages[lineage.lineageId];
    if (existing != null &&
        _isOlder(
          lineage.lineageGeneration,
          lineage.candidateSequence,
          existing.lineageGeneration,
          existing.candidateSequence,
        )) {
      throw StateError('Cannot replace newer lineage state with older state.');
    }
    _lineages[lineage.lineageId] = lineage;
  }

  void observeRepairBudget(RepairBudgetSnapshot budget) {
    _requireKnownLineage(budget.lineageId);
    _budgets[budget.lineageId] = budget;
  }

  void observeBranchHead(BranchHeadSnapshot branchHead) {
    _branchHeads[branchHead.branch] = branchHead;
  }

  void observeWriterLease(WriterLeaseSnapshot lease) {
    _requireKnownLineage(lease.lineageId);
    _leases[lease.writerLeaseId] = lease;
    _leaseEvidence.add(lease);
  }

  void observeCancellation(CancellationSnapshot cancellation) {
    _requireKnownLineage(cancellation.lineageId);
    _cancellations[cancellation.lineageId] = cancellation;
  }

  void observeEvidenceReference(EvidenceReferenceSnapshot evidence) {
    _evidence[evidence.referenceId] = evidence;
  }

  void observeHumanApproval(HumanApprovalSnapshot approval) {
    _approvals[approval.approvalId] = approval;
  }

  ObservationResult observeAuthoritativeEvent(AuthoritativeEvent event) {
    final semanticKey = _semanticKey(event);
    _eventEvidence.add(event);

    if (!_trustedIssuers.contains(event.sourceSystem)) {
      return ObservationResult(
        disposition: ObservationDisposition.rejectedUntrustedIssuer,
        reason: 'Event issuer is not trusted.',
        eventId: event.eventId,
        semanticKey: semanticKey,
      );
    }
    if (event.governanceVersion != governanceVersion) {
      return ObservationResult(
        disposition: ObservationDisposition.rejectedGovernanceMismatch,
        reason: 'Event governance version does not match pinned governance.',
        eventId: event.eventId,
        semanticKey: semanticKey,
      );
    }
    if (!_tasks.containsKey(event.taskId)) {
      return ObservationResult(
        disposition: ObservationDisposition.rejectedUnknownTask,
        reason: 'Event refers to an unknown task.',
        eventId: event.eventId,
        semanticKey: semanticKey,
      );
    }
    final lineage = _lineages[event.lineageId];
    if (lineage == null || lineage.taskId != event.taskId) {
      return ObservationResult(
        disposition: ObservationDisposition.rejectedUnknownLineage,
        reason: 'Event refers to an unknown or mismatched lineage.',
        eventId: event.eventId,
        semanticKey: semanticKey,
      );
    }
    if (_events.containsKey(event.eventId)) {
      return ObservationResult(
        disposition: ObservationDisposition.duplicateEventId,
        reason: 'Event ID has already been observed.',
        eventId: event.eventId,
        semanticKey: semanticKey,
      );
    }
    if (_semanticEvents.containsKey(semanticKey)) {
      return ObservationResult(
        disposition: ObservationDisposition.duplicateSemanticEvent,
        reason: 'Logical event has already been observed.',
        eventId: event.eventId,
        semanticKey: semanticKey,
      );
    }
    if (_isOlder(
      event.lineageGeneration,
      event.candidateSequence,
      lineage.lineageGeneration,
      lineage.candidateSequence,
    )) {
      return ObservationResult(
        disposition: ObservationDisposition.ignoredStaleEvent,
        reason:
            'Stale event retained as evidence and ignored as current state.',
        eventId: event.eventId,
        semanticKey: semanticKey,
      );
    }
    if (!_validStateForEvent(event)) {
      return ObservationResult(
        disposition: ObservationDisposition.invalidObservedState,
        reason: 'Event state is outside its canonical namespace.',
        eventId: event.eventId,
        semanticKey: semanticKey,
      );
    }

    _events[event.eventId] = event;
    _semanticEvents[semanticKey] = event.eventId;
    _lineages[event.lineageId] = LineageSnapshot(
      taskId: lineage.taskId,
      lineageId: lineage.lineageId,
      currentSha: event.candidateSha,
      lineageGeneration: event.lineageGeneration,
      candidateSequence: event.candidateSequence,
      governanceVersion: lineage.governanceVersion,
      observedAt: _trustedClock(),
    );

    return ObservationResult(
      disposition: ObservationDisposition.accepted,
      reason: 'Event observed. No route or protected transition executed.',
      eventId: event.eventId,
      semanticKey: semanticKey,
    );
  }

  List<String> anomalies() {
    final found = <String>[];
    for (final head in _branchHeads.values) {
      if (!head.matchesExpected) {
        found.add(
          'BRANCH_HEAD_DRIFT:' +
              head.branch +
              ':' +
              head.expectedHead +
              ':' +
              head.observedHead,
        );
      }
    }

    final now = _trustedClock().toUtc();
    final activeByBranch = <String, int>{};
    final activeByLineage = <String, int>{};
    final latestTokenByScope = <String, int>{};
    final observedLeaseIds = <String>{};
    for (final lease in _leases.values) {
      if (lease.active && lease.expiresAt.toUtc().isAfter(now)) {
        activeByBranch[lease.branch] = (activeByBranch[lease.branch] ?? 0) + 1;
        activeByLineage[lease.lineageId] =
            (activeByLineage[lease.lineageId] ?? 0) + 1;
      }
    }
    for (final lease in _leaseEvidence) {
      if (!observedLeaseIds.add(lease.writerLeaseId)) {
        found.add('REPLACED_WRITER_LEASE:' + lease.writerLeaseId);
      }
      final scope = lease.lineageId + ':' + lease.branch;
      final previousToken = latestTokenByScope[scope];
      if (previousToken != null && lease.fencingToken < previousToken) {
        found.add(
          'FENCING_TOKEN_REGRESSION:' +
              scope +
              ':' +
              previousToken.toString() +
              ':' +
              lease.fencingToken.toString(),
        );
      } else if (previousToken == null || lease.fencingToken > previousToken) {
        latestTokenByScope[scope] = lease.fencingToken;
      }
      if (!lease.active || !lease.expiresAt.toUtc().isAfter(now)) {
        found.add('STALE_WRITER_LEASE:' + lease.writerLeaseId);
      }
      final branchHead = _branchHeads[lease.branch];
      if (branchHead != null && branchHead.observedHead != lease.expectedHead) {
        found.add(
          'LEASE_EXPECTED_HEAD_MISMATCH:' +
              lease.writerLeaseId +
              ':' +
              lease.expectedHead +
              ':' +
              branchHead.observedHead,
        );
      }
    }
    for (final entry in activeByBranch.entries) {
      if (entry.value > 1) {
        found.add(
          'MULTIPLE_ACTIVE_WRITERS:' + entry.key + ':' + entry.value.toString(),
        );
      }
    }
    for (final entry in activeByLineage.entries) {
      if (entry.value > 1) {
        found.add(
          'MULTIPLE_ACTIVE_LINEAGE_WRITERS:' +
              entry.key +
              ':' +
              entry.value.toString(),
        );
      }
    }

    for (final approval in _approvals.values) {
      if (approval.governanceVersion != governanceVersion) {
        found.add('APPROVAL_GOVERNANCE_MISMATCH:' + approval.approvalId);
      } else if (approval.status != 'ACTIVE') {
        found.add('INVALID_APPROVAL_STATUS:' + approval.approvalId);
      } else if (approval.revokedAt != null &&
          !now.isBefore(approval.revokedAt!.toUtc())) {
        found.add('REVOKED_APPROVAL:' + approval.approvalId);
      } else if (approval.expiresAt != null &&
          !now.isBefore(approval.expiresAt!.toUtc())) {
        found.add('EXPIRED_APPROVAL:' + approval.approvalId);
      }
    }
    return List.unmodifiable(found..sort());
  }

  ControlPlaneSnapshot snapshot() => ControlPlaneSnapshot(
    maturity: maturity,
    governanceVersion: governanceVersion,
    governanceSha: governanceSha,
    observedAt: _trustedClock(),
    tasks: _sorted(_tasks.values, (e) => e.taskId),
    taskStates: _sorted(_taskStates.values, (e) => e.taskId),
    taskStateEvidence: List.unmodifiable(_taskStateEvidence),
    lineages: _sorted(_lineages.values, (e) => e.lineageId),
    authoritativeEvents: _sorted(_events.values, (e) => e.eventId),
    eventEvidence: List.unmodifiable(_eventEvidence),
    repairBudgets: _sorted(_budgets.values, (e) => e.lineageId),
    branchHeads: _sorted(_branchHeads.values, (e) => e.branch),
    writerLeases: _sorted(_leases.values, (e) => e.lineageId),
    cancellations: _sorted(_cancellations.values, (e) => e.lineageId),
    evidenceReferences: _sorted(_evidence.values, (e) => e.referenceId),
    humanApprovals: _sorted(_approvals.values, (e) => e.approvalId),
    writerLeaseEvidence: List.unmodifiable(_leaseEvidence),
  );

  String exportJson() => snapshot().toPrettyJson();

  String _semanticKey(AuthoritativeEvent event) =>
      sha256.convert(utf8.encode(event.semanticMaterial())).toString();

  bool _validStateForEvent(AuthoritativeEvent event) {
    switch (event.eventType) {
      case 'CHECK_EVENT':
        return checkStates.contains(event.state);
      case 'DO_STOP_EVENT':
        return event.state.startsWith('STOP-') || event.state.startsWith('DO_');
      case 'SECURITY_EVENT':
      case 'HUMAN_DECISION':
      case 'CANCEL_EVENT':
      case 'INFRASTRUCTURE_EVENT':
        return event.state.isNotEmpty;
      default:
        return false;
    }
  }

  bool _validTaskTransition(String previous, String next) {
    const transitions = <String, Set<String>>{
      'TASK_QUEUED': {'TASK_READY', 'TASK_CANCELLED'},
      'TASK_READY': {'TASK_RUNNING', 'TASK_BLOCKED', 'TASK_CANCELLED'},
      'TASK_RUNNING': {
        'TASK_BLOCKED',
        'TASK_HANDOFF_READY',
        'TASK_FAILED_SAFE',
        'TASK_CANCELLED',
      },
      'TASK_BLOCKED': {'TASK_READY', 'TASK_CANCELLED', 'TASK_FAILED_SAFE'},
      'TASK_HANDOFF_READY': {},
      'TASK_FAILED_SAFE': {},
      'TASK_CANCELLED': {},
    };
    return previous == next || (transitions[previous]?.contains(next) ?? false);
  }

  bool _isOlder(
    int generation,
    int sequence,
    int currentGeneration,
    int currentSequence,
  ) =>
      generation < currentGeneration ||
      (generation == currentGeneration && sequence < currentSequence);

  void _requireKnownLineage(String lineageId) {
    if (!_lineages.containsKey(lineageId)) {
      throw StateError('Unknown lineage: ' + lineageId);
    }
  }

  void _requireGovernance(String version) {
    if (version != governanceVersion) {
      throw StateError(
        'Governance mismatch. Expected ' +
            governanceVersion +
            ', got ' +
            version +
            '.',
      );
    }
  }

  List<T> _sorted<T>(Iterable<T> values, String Function(T) key) {
    final result = values.toList()..sort((a, b) => key(a).compareTo(key(b)));
    return List.unmodifiable(result);
  }
}
