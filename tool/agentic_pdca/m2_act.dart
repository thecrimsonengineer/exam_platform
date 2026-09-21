import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'm0_models.dart';
import 'm2_bounded_authority.dart';
import 'm2_reviewer.dart';
import 'm2_task_packet.dart';

enum M2ActRoute { retry, repair, escalate }

enum M2ActAttemptType { retry, repair }

enum M2RepairBudgetKind { mechanical, behavioral, architecture }

final class M2TransientRetryReceipt {
  const M2TransientRetryReceipt({
    required this.candidateSha,
    required this.packetHash,
    required this.transientInfrastructure,
    required this.observedAt,
    required this.evidenceReference,
  });

  final String candidateSha;
  final String packetHash;
  final bool transientInfrastructure;
  final DateTime observedAt;
  final String evidenceReference;
}

abstract interface class M2TrustedReviewOutcomeEvidence {
  Future<List<M2ReviewOutcome>> read(String candidateSha, String packetHash);
}

abstract interface class M2TrustedRetryEvidence {
  Future<List<M2TransientRetryReceipt>> read(
    String candidateSha,
    String packetHash,
  );
}

final class M2ActRequest {
  M2ActRequest({
    required this.attemptType,
    required this.failedCandidateSha,
    required this.repairAgent,
    required this.strategy,
    required this.rootCause,
    required this.evidenceReference,
    this.findingCode,
    this.repairClass,
    List<String> requestedPaths = const [],
  }) : requestedPaths = List.unmodifiable(requestedPaths);

  final M2ActAttemptType attemptType;
  final String failedCandidateSha;
  final String repairAgent;
  final String strategy;
  final String rootCause;
  final String evidenceReference;
  final String? findingCode;
  final String? repairClass;
  final List<String> requestedPaths;
}

final class M2RepairLedgerEntry {
  M2RepairLedgerEntry({
    required this.authorizationId,
    required this.taskId,
    required this.lineageId,
    required this.packetHash,
    required this.failedCandidateSha,
    required this.attemptType,
    required this.repairAgent,
    required this.failureClass,
    required this.findingCode,
    required this.strategy,
    required this.rootCause,
    required this.evidenceReference,
    required List<String> requestedPaths,
    required this.classRemaining,
    required this.categoryRemaining,
    required this.timestamp,
  }) : requestedPaths = List.unmodifiable(requestedPaths);

  final String authorizationId;
  final String taskId;
  final String lineageId;
  final String packetHash;
  final String failedCandidateSha;
  final M2ActAttemptType attemptType;
  final String repairAgent;
  final String? failureClass;
  final String? findingCode;
  final String strategy;
  final String rootCause;
  final String evidenceReference;
  final List<String> requestedPaths;
  final int? classRemaining;
  final int? categoryRemaining;
  final DateTime timestamp;

  Map<String, Object?> toJson() => {
    'authorization_id': authorizationId,
    'task_id': taskId,
    'lineage_id': lineageId,
    'packet_hash': packetHash,
    'failed_candidate_sha': failedCandidateSha,
    'attempt_type': attemptType.name,
    'repair_agent': repairAgent,
    if (failureClass != null) 'failure_class': failureClass,
    if (findingCode != null) 'finding_code': findingCode,
    'strategy': strategy,
    'root_cause': rootCause,
    'evidence_reference': evidenceReference,
    'requested_paths': requestedPaths,
    if (classRemaining != null) 'class_remaining': classRemaining,
    if (categoryRemaining != null) 'category_remaining': categoryRemaining,
    'timestamp': timestamp.toUtc().toIso8601String(),
  };
}

final class M2ActDecision {
  M2ActDecision({
    required this.route,
    required this.reason,
    required this.candidateSha,
    required this.packetHash,
    this.ledgerEntry,
  });

  final M2ActRoute route;
  final String reason;
  final String candidateSha;
  final String packetHash;
  final M2RepairLedgerEntry? ledgerEntry;
}

/// Process-lifetime central ACT-2 store. State is keyed by lineage, never by
/// repair agent or controller instance. Reinitialization can only clamp
/// balances downward; it can never replenish consumed budget.
final class M2RepairBudgetStore {
  static final Map<String, Map<String, int>> _classBalances = {};
  static final Map<String, Map<M2RepairBudgetKind, int>> _categoryBalances = {};
  static final Map<String, List<M2RepairLedgerEntry>> _history = {};

  void initialize({
    required M2TaskPacket packet,
    required RepairBudgetSnapshot trustedBudget,
  }) {
    if (trustedBudget.lineageId != packet.lineageId ||
        trustedBudget.mechanicalRemaining < 0 ||
        trustedBudget.behavioralRemaining < 0 ||
        trustedBudget.architectureRemaining < 0) {
      throw StateError('Invalid trusted repair budget.');
    }

    final raw = (packet.toJson()['repair_budgets'] as Map)
        .cast<String, Object?>();
    final proposed = {
      for (final code in M2TaskPacket.budgetCaps.keys) code: raw[code] as int,
    };

    final currentClasses = _classBalances[packet.lineageId];
    if (currentClasses == null) {
      _classBalances[packet.lineageId] = Map<String, int>.from(proposed);
    } else {
      for (final entry in proposed.entries) {
        currentClasses[entry.key] = _min(
          currentClasses[entry.key] ?? 0,
          entry.value,
        );
      }
    }

    final proposedCategories = {
      M2RepairBudgetKind.mechanical: trustedBudget.mechanicalRemaining,
      M2RepairBudgetKind.behavioral: trustedBudget.behavioralRemaining,
      M2RepairBudgetKind.architecture: trustedBudget.architectureRemaining,
    };
    final currentCategories = _categoryBalances[packet.lineageId];
    if (currentCategories == null) {
      _categoryBalances[packet.lineageId] = Map<M2RepairBudgetKind, int>.from(
        proposedCategories,
      );
    } else {
      for (final entry in proposedCategories.entries) {
        currentCategories[entry.key] = _min(
          currentCategories[entry.key] ?? 0,
          entry.value,
        );
      }
    }

    _history.putIfAbsent(packet.lineageId, () => []);
  }

  int classRemaining(String lineageId, String failureClass) =>
      _classBalances[lineageId]?[failureClass] ??
      (throw StateError('Unknown ACT-2 lineage or failure class.'));

  int categoryRemaining(String lineageId, M2RepairBudgetKind kind) =>
      _categoryBalances[lineageId]?[kind] ??
      (throw StateError('Unknown ACT-2 lineage or budget category.'));

  List<M2RepairLedgerEntry> history(String lineageId) => List.unmodifiable(
    _history[lineageId] ?? (throw StateError('Unknown ACT-2 repair lineage.')),
  );

  bool repairStrategyAlreadyUsed({
    required String lineageId,
    required String failureClass,
    required String findingCode,
    required String strategy,
  }) => history(lineageId).any(
    (entry) =>
        entry.attemptType == M2ActAttemptType.repair &&
        entry.failureClass == failureClass &&
        entry.findingCode == findingCode &&
        _normalize(entry.strategy) == _normalize(strategy),
  );

  bool retryStrategyAlreadyUsed({
    required String lineageId,
    required String strategy,
  }) => history(lineageId).any(
    (entry) =>
        entry.attemptType == M2ActAttemptType.retry &&
        _normalize(entry.strategy) == _normalize(strategy),
  );

  M2RepairLedgerEntry reserveRepair({
    required M2TaskPacket packet,
    required String failedCandidateSha,
    required String repairAgent,
    required String failureClass,
    required String findingCode,
    required String strategy,
    required String rootCause,
    required String evidenceReference,
    required List<String> requestedPaths,
    required DateTime timestamp,
  }) {
    final kind = _kindFor(failureClass);
    final classBalance = classRemaining(packet.lineageId, failureClass);
    final categoryBalance = categoryRemaining(packet.lineageId, kind);
    if (classBalance <= 0 || categoryBalance <= 0) {
      throw StateError('Repair budget exhausted.');
    }

    final nextClass = classBalance - 1;
    final nextCategory = categoryBalance - 1;
    _classBalances[packet.lineageId]![failureClass] = nextClass;
    _categoryBalances[packet.lineageId]![kind] = nextCategory;

    final history = _history[packet.lineageId]!;
    final entry = M2RepairLedgerEntry(
      authorizationId: _authorizationId(
        packet: packet,
        candidateSha: failedCandidateSha,
        attemptSequence: history.length + 1,
        attemptType: M2ActAttemptType.repair,
        strategy: strategy,
      ),
      taskId: packet.taskId,
      lineageId: packet.lineageId,
      packetHash: packet.hash,
      failedCandidateSha: failedCandidateSha,
      attemptType: M2ActAttemptType.repair,
      repairAgent: repairAgent,
      failureClass: failureClass,
      findingCode: findingCode,
      strategy: strategy,
      rootCause: rootCause,
      evidenceReference: evidenceReference,
      requestedPaths: requestedPaths,
      classRemaining: nextClass,
      categoryRemaining: nextCategory,
      timestamp: timestamp,
    );
    history.add(entry);
    return entry;
  }

  M2RepairLedgerEntry recordRetry({
    required M2TaskPacket packet,
    required String failedCandidateSha,
    required String repairAgent,
    required String strategy,
    required String rootCause,
    required String evidenceReference,
    required DateTime timestamp,
  }) {
    final history = _history[packet.lineageId]!;
    final entry = M2RepairLedgerEntry(
      authorizationId: _authorizationId(
        packet: packet,
        candidateSha: failedCandidateSha,
        attemptSequence: history.length + 1,
        attemptType: M2ActAttemptType.retry,
        strategy: strategy,
      ),
      taskId: packet.taskId,
      lineageId: packet.lineageId,
      packetHash: packet.hash,
      failedCandidateSha: failedCandidateSha,
      attemptType: M2ActAttemptType.retry,
      repairAgent: repairAgent,
      failureClass: null,
      findingCode: null,
      strategy: strategy,
      rootCause: rootCause,
      evidenceReference: evidenceReference,
      requestedPaths: const [],
      classRemaining: null,
      categoryRemaining: null,
      timestamp: timestamp,
    );
    history.add(entry);
    return entry;
  }

  static int _min(int a, int b) => a < b ? a : b;

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static M2RepairBudgetKind _kindFor(String failureClass) {
    if (failureClass == 'F1' || failureClass == 'F2') {
      return M2RepairBudgetKind.mechanical;
    }
    if (failureClass == 'F3' ||
        failureClass == 'F4' ||
        failureClass == 'F5' ||
        failureClass == 'F7') {
      return M2RepairBudgetKind.behavioral;
    }
    return M2RepairBudgetKind.architecture;
  }

  static String _authorizationId({
    required M2TaskPacket packet,
    required String candidateSha,
    required int attemptSequence,
    required M2ActAttemptType attemptType,
    required String strategy,
  }) {
    final material = [
      packet.lineageId,
      packet.hash,
      candidateSha,
      attemptSequence.toString(),
      attemptType.name,
      _normalize(strategy),
    ].join('\u001f');
    return sha256.convert(utf8.encode(material)).toString();
  }
}

final class M2ActController {
  M2ActController({
    required this.packet,
    required this.trustedState,
    required this.reviewEvidence,
    required this.retryEvidence,
    M2RepairBudgetStore? budgetStore,
    DateTime Function()? trustedClock,
  }) : budgetStore = budgetStore ?? M2RepairBudgetStore(),
       _clock = trustedClock ?? (() => DateTime.now().toUtc());

  final M2TaskPacket packet;
  final ControlPlaneSnapshot trustedState;
  final M2TrustedReviewOutcomeEvidence reviewEvidence;
  final M2TrustedRetryEvidence retryEvidence;
  final M2RepairBudgetStore budgetStore;
  final DateTime Function() _clock;

  Future<M2ActDecision> route(M2ActRequest request) async {
    final now = _clock().toUtc();
    if (!_requestBasicsValid(request) ||
        !_trustedAuthorityValid(request.failedCandidateSha, now)) {
      return _escalate(request, 'TRUST_OR_REQUEST_INVALID');
    }

    final budgets = trustedState.repairBudgets.where(
      (budget) => budget.lineageId == packet.lineageId,
    );
    if (budgets.length != 1 || budgets.single.observedAt.toUtc().isAfter(now)) {
      return _escalate(request, 'TRUSTED_BUDGET_UNAVAILABLE');
    }

    try {
      budgetStore.initialize(packet: packet, trustedBudget: budgets.single);
    } catch (_) {
      return _escalate(request, 'TRUSTED_BUDGET_INVALID');
    }

    if (request.attemptType == M2ActAttemptType.retry) {
      return _routeRetry(request, now);
    }
    return _routeRepair(request, now);
  }

  Future<M2ActDecision> _routeRetry(M2ActRequest request, DateTime now) async {
    if (request.findingCode != null ||
        request.repairClass != null ||
        request.requestedPaths.isNotEmpty) {
      return _escalate(request, 'RETRY_CANNOT_MUTATE');
    }

    List<M2TransientRetryReceipt> receipts;
    try {
      receipts = await retryEvidence.read(
        request.failedCandidateSha,
        packet.hash,
      );
    } catch (_) {
      return _escalate(request, 'RETRY_EVIDENCE_UNAVAILABLE');
    }

    if (receipts.length != 1) {
      return _escalate(request, 'RETRY_EVIDENCE_COUNT');
    }
    final receipt = receipts.single;
    if (receipt.candidateSha != request.failedCandidateSha ||
        receipt.packetHash != packet.hash ||
        !receipt.transientInfrastructure ||
        receipt.observedAt.toUtc().isAfter(now) ||
        receipt.evidenceReference.trim().isEmpty) {
      return _escalate(request, 'RETRY_EVIDENCE_INVALID');
    }

    if (budgetStore.retryStrategyAlreadyUsed(
      lineageId: packet.lineageId,
      strategy: request.strategy,
    )) {
      return _escalate(request, 'REPEATED_RETRY_STRATEGY');
    }

    final entry = budgetStore.recordRetry(
      packet: packet,
      failedCandidateSha: request.failedCandidateSha,
      repairAgent: request.repairAgent,
      strategy: request.strategy,
      rootCause: request.rootCause,
      evidenceReference: receipt.evidenceReference,
      timestamp: now,
    );
    return M2ActDecision(
      route: M2ActRoute.retry,
      reason: 'TRANSIENT_RETRY_AUTHORIZED',
      candidateSha: request.failedCandidateSha,
      packetHash: packet.hash,
      ledgerEntry: entry,
    );
  }

  Future<M2ActDecision> _routeRepair(M2ActRequest request, DateTime now) async {
    final failureClass = request.repairClass;
    final findingCode = request.findingCode;
    if (failureClass == null ||
        findingCode == null ||
        request.requestedPaths.isEmpty ||
        request.requestedPaths.toSet().length !=
            request.requestedPaths.length ||
        request.requestedPaths.any(
          (path) =>
              !packet.expectedPaths.contains(path) || !packet.allows(path),
        )) {
      return _escalate(request, 'REPAIR_SCOPE_INVALID');
    }

    if (!packet.strings('permitted_repair_classes').contains(failureClass) ||
        failureClass == 'F6' ||
        failureClass == 'F8' ||
        failureClass == 'F9' ||
        failureClass == 'F10') {
      return _escalate(request, 'REPAIR_CLASS_NOT_AUTHORIZED');
    }

    List<M2ReviewOutcome> outcomes;
    try {
      outcomes = await reviewEvidence.read(
        request.failedCandidateSha,
        packet.hash,
      );
    } catch (_) {
      return _escalate(request, 'REVIEW_EVIDENCE_UNAVAILABLE');
    }
    if (outcomes.length != 1) {
      return _escalate(request, 'REVIEW_EVIDENCE_COUNT');
    }

    final review = outcomes.single;
    if (review.candidateSha != request.failedCandidateSha ||
        review.packetHash != packet.hash ||
        review.state != M2ReviewState.reviewRepairable ||
        review.findings.any(
          (finding) =>
              finding.disposition == M2ReviewFindingDisposition.escalate,
        )) {
      return _escalate(request, 'REVIEW_NOT_REPAIRABLE');
    }

    final matches = review.findings.where(
      (finding) =>
          finding.code == findingCode &&
          finding.disposition == M2ReviewFindingDisposition.repairable &&
          finding.repairClass == failureClass &&
          finding.evidenceReference == request.evidenceReference,
    );
    if (matches.length != 1) {
      return _escalate(request, 'REPAIR_FINDING_MISMATCH');
    }

    if (failureClass == 'F7' &&
        findingCode != 'FROZEN_REGRESSION_CURRENT_CANDIDATE') {
      return _escalate(request, 'F7_CAUSE_NOT_PROVEN');
    }

    try {
      if (budgetStore.repairStrategyAlreadyUsed(
        lineageId: packet.lineageId,
        failureClass: failureClass,
        findingCode: findingCode,
        strategy: request.strategy,
      )) {
        return _escalate(request, 'REPEATED_REPAIR_STRATEGY');
      }

      final entry = budgetStore.reserveRepair(
        packet: packet,
        failedCandidateSha: request.failedCandidateSha,
        repairAgent: request.repairAgent,
        failureClass: failureClass,
        findingCode: findingCode,
        strategy: request.strategy,
        rootCause: request.rootCause,
        evidenceReference: request.evidenceReference,
        requestedPaths: request.requestedPaths,
        timestamp: now,
      );
      return M2ActDecision(
        route: M2ActRoute.repair,
        reason: 'BOUNDED_REPAIR_AUTHORIZED',
        candidateSha: request.failedCandidateSha,
        packetHash: packet.hash,
        ledgerEntry: entry,
      );
    } on StateError {
      return _escalate(request, 'REPAIR_BUDGET_EXHAUSTED');
    }
  }

  bool _requestBasicsValid(M2ActRequest request) =>
      m2ExactSha(request.failedCandidateSha) &&
      request.failedCandidateSha != packet.taskBaseSha &&
      request.repairAgent.trim().isNotEmpty &&
      request.strategy.trim().isNotEmpty &&
      request.rootCause.trim().isNotEmpty &&
      request.evidenceReference.trim().isNotEmpty;

  bool _trustedAuthorityValid(String candidateSha, DateTime now) {
    if (trustedState.governanceSha != m2GovernanceSha ||
        trustedState.governanceVersion != 'v1.0' ||
        trustedState.cancellations.any(
          (cancellation) => cancellation.lineageId == packet.lineageId,
        )) {
      return false;
    }

    final lineages = trustedState.lineages.where(
      (lineage) =>
          lineage.lineageId == packet.lineageId &&
          lineage.taskId == packet.taskId,
    );
    if (lineages.length != 1 ||
        lineages.single.currentSha != candidateSha ||
        lineages.single.governanceVersion != 'v1.0' ||
        lineages.single.observedAt.toUtc().isAfter(now)) {
      return false;
    }

    final tasks = trustedState.tasks.where(
      (task) => task.taskId == packet.taskId,
    );
    if (tasks.length != 1) return false;
    final task = tasks.single;
    final taskValid =
        task.phaseId == 'M2' &&
        task.baseBranch == packet.branch &&
        task.baseSha == packet.taskBaseSha &&
        task.riskClass == packet.text('risk_class') &&
        _sameStrings(task.allowedPaths, packet.strings('allowed_paths')) &&
        _sameStrings(task.forbiddenPaths, packet.strings('forbidden_paths')) &&
        _sameStrings(
          task.requiredTests,
          packet.strings('required_targeted_tests'),
        ) &&
        _sameStrings(task.stopConditions, packet.strings('stop_conditions')) &&
        task.governanceVersion == 'v1.0' &&
        !task.observedAt.toUtc().isAfter(now);
    if (!taskValid) return false;

    return M2ApprovedManifest(
          packet: packet,
        ).trustedApproval(trustedState, now) !=
        null;
  }

  bool _sameStrings(List<String> a, List<String> b) =>
      a.length == b.length && a.toSet().containsAll(b);

  M2ActDecision _escalate(M2ActRequest request, String reason) => M2ActDecision(
    route: M2ActRoute.escalate,
    reason: reason,
    candidateSha: request.failedCandidateSha,
    packetHash: packet.hash,
  );
}
