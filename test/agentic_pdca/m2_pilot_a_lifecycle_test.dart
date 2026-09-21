import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/agentic_pdca/m0_models.dart';
import '../../tool/agentic_pdca/m2_act.dart';
import '../../tool/agentic_pdca/m2_bounded_authority.dart';
import '../../tool/agentic_pdca/m2_handoff.dart';
import '../../tool/agentic_pdca/m2_reviewer.dart';
import '../../tool/agentic_pdca/m2_task_packet.dart';
import 'm2_test_support.dart';

final class _SemanticStore implements M2TrustedSemanticReviewEvidence {
  _SemanticStore(this.receipts);
  final List<M2SemanticReviewReceipt> receipts;

  @override
  Future<List<M2SemanticReviewReceipt>> read(
    String candidateSha,
    String packetHash,
  ) async => receipts;
}

final class _ReviewStore implements M2TrustedReviewOutcomeEvidence {
  _ReviewStore(this.outcomes);
  final List<M2ReviewOutcome> outcomes;

  @override
  Future<List<M2ReviewOutcome>> read(
    String candidateSha,
    String packetHash,
  ) async => outcomes;
}

final class _RetryStore implements M2TrustedRetryEvidence {
  const _RetryStore();

  @override
  Future<List<M2TransientRetryReceipt>> read(
    String candidateSha,
    String packetHash,
  ) async => const [];
}

void main() {
  final packet = M2TaskPacket.parse(
    File('docs/agentic/implementation/m2/RUN_5_PACKET.json').readAsStringSync(),
  );
  const firstCandidate = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
  const repairedCandidate = 'cccccccccccccccccccccccccccccccccccccccc';
  final changedPath = packet.expectedPaths.first;

  M2FakeWorkspace workspaceAt(
    String candidate, {
    required List<String> commits,
  }) => M2FakeWorkspace(packet)
    ..head = candidate
    ..changed = [changedPath]
    ..commits = commits
    ..diffPatch =
        'diff --git a/$changedPath b/$changedPath\n'
        '+void pilotEvidence() {}\n';

  List<M2GateReceipt> receiptsFor(String candidate) =>
      greenReceipts(packet, candidate: candidate);

  M2SemanticReviewReceipt semanticFor(
    String candidate, {
    required bool behaviorMatchesTask,
    required String reference,
  }) => M2SemanticReviewReceipt(
    candidateSha: candidate,
    packetHash: packet.hash,
    reviewerPrincipal: 'pilot-a-independent-reviewer',
    reviewerRole: 'REVIEWER',
    readOnly: true,
    observedAt: m2TestNow,
    evidenceReference: reference,
    acceptanceCriteriaSatisfied: true,
    architectureConsistent: true,
    testQualityAccepted: true,
    regressionRiskAccepted: true,
    maintainabilityAccepted: true,
    behaviorMatchesTask: behaviorMatchesTask,
    findings: const [],
  );

  ControlPlaneSnapshot stateAt(
    String candidate, {
    bool withRepairBudget = false,
  }) {
    final base = testState(packet, lineageSha: candidate);
    if (!withRepairBudget) return base;
    return ControlPlaneSnapshot(
      maturity: base.maturity,
      governanceVersion: base.governanceVersion,
      governanceSha: base.governanceSha,
      observedAt: base.observedAt,
      tasks: base.tasks,
      taskStates: base.taskStates,
      taskStateEvidence: base.taskStateEvidence,
      lineages: base.lineages,
      authoritativeEvents: base.authoritativeEvents,
      eventEvidence: base.eventEvidence,
      repairBudgets: [
        RepairBudgetSnapshot(
          lineageId: packet.lineageId,
          mechanicalRemaining: 10,
          behavioralRemaining: 11,
          architectureRemaining: 0,
          observedAt: m2TestNow,
        ),
      ],
      branchHeads: base.branchHeads,
      writerLeases: base.writerLeases,
      cancellations: base.cancellations,
      evidenceReferences: base.evidenceReferences,
      humanApprovals: base.humanApprovals,
      writerLeaseEvidence: base.writerLeaseEvidence,
    );
  }

  Future<M2ReviewOutcome> reviewCandidate({
    required String candidate,
    required List<String> commits,
    required bool behaviorMatchesTask,
    required String semanticReference,
  }) async {
    final work = workspaceAt(candidate, commits: commits);
    final receipts = receiptsFor(candidate);
    final handoff =
        await M2HandoffBuilder(
          workspace: work,
          gateEvidence: M2FakeGates(receipts),
          packet: packet,
        ).build(
          candidateSha: candidate,
          knownLimitations: const ['Pilot A deterministic fixture'],
        );
    return M2Check3Reviewer(
      packet: packet,
      workspace: work,
      gateEvidence: M2FakeGates(receipts),
      semanticEvidence: _SemanticStore([
        semanticFor(
          candidate,
          behaviorMatchesTask: behaviorMatchesTask,
          reference: semanticReference,
        ),
      ]),
      trustedState: stateAt(candidate),
      trustedClock: () => m2TestNow,
    ).review(candidateSha: candidate, handoffJson: handoff.canonicalJson);
  }

  test(
    'Pilot A completes DO to repair to new candidate to CHECK-3 acceptance',
    () async {
      final doWorkspace = M2FakeWorkspace(packet);
      final doDecision =
          await M2BoundedAuthority(
            manifest: M2ApprovedManifest(packet: packet),
            workspace: doWorkspace,
            trustedState: testState(packet),
            trustedClock: () => m2TestNow,
          ).authorize(
            M2BuilderRequest(
              packetHash: packet.hash,
              revision: packet.revision,
              expectedHead: packet.taskBaseSha,
              writerLeaseId: 'lease',
              writerIdentity: 'builder',
              fencingToken: 7,
              requestedPaths: [changedPath],
            ),
          );
      expect(doDecision.authorized, isTrue);

      final firstReview = await reviewCandidate(
        candidate: firstCandidate,
        commits: const [firstCandidate],
        behaviorMatchesTask: false,
        semanticReference: 'pilot-a:first-review',
      );
      expect(firstReview.state, M2ReviewState.reviewRepairable);
      expect(
        firstReview.findings.any(
          (finding) =>
              finding.code == 'BEHAVIOR_MISMATCH' &&
              finding.repairClass == 'F4',
        ),
        isTrue,
      );

      final budgetStore = M2RepairBudgetStore();
      final act = M2ActController(
        packet: packet,
        trustedState: stateAt(firstCandidate, withRepairBudget: true),
        reviewEvidence: _ReviewStore([firstReview]),
        retryEvidence: const _RetryStore(),
        budgetStore: budgetStore,
        trustedClock: () => m2TestNow,
      );
      final repairDecision = await act.route(
        M2ActRequest(
          attemptType: M2ActAttemptType.repair,
          failedCandidateSha: firstCandidate,
          repairAgent: 'pilot-a-repairer',
          strategy: 'correct controlled Pilot A behavior finding',
          rootCause: 'controlled Pilot A candidate-local behavior finding',
          evidenceReference: 'pilot-a:first-review',
          findingCode: 'BEHAVIOR_MISMATCH',
          repairClass: 'F4',
          requestedPaths: [changedPath],
        ),
      );
      expect(repairDecision.route, M2ActRoute.repair);
      expect(repairDecision.candidateSha, firstCandidate);
      expect(repairDecision.ledgerEntry!.classRemaining, 2);
      expect(repairDecision.ledgerEntry!.categoryRemaining, 10);
      expect(repairDecision.ledgerEntry!.failedCandidateSha, firstCandidate);

      expect(repairedCandidate, isNot(firstCandidate));
      final repairedReview = await reviewCandidate(
        candidate: repairedCandidate,
        commits: const [firstCandidate, repairedCandidate],
        behaviorMatchesTask: true,
        semanticReference: 'pilot-a:repaired-review',
      );
      expect(repairedReview.state, M2ReviewState.reviewAccepted);
      expect(repairedReview.findings, isEmpty);

      final staleReviewController = M2ActController(
        packet: packet,
        trustedState: stateAt(repairedCandidate, withRepairBudget: true),
        reviewEvidence: _ReviewStore([firstReview]),
        retryEvidence: const _RetryStore(),
        trustedClock: () => m2TestNow,
      );
      final staleDecision = await staleReviewController.route(
        M2ActRequest(
          attemptType: M2ActAttemptType.repair,
          failedCandidateSha: repairedCandidate,
          repairAgent: 'pilot-a-repairer',
          strategy: 'attempt stale evidence reuse',
          rootCause: 'stale evidence attempt',
          evidenceReference: 'pilot-a:first-review',
          findingCode: 'BEHAVIOR_MISMATCH',
          repairClass: 'F4',
          requestedPaths: [changedPath],
        ),
      );
      expect(staleDecision.route, M2ActRoute.escalate);

      expect(M2ActRoute.values.map((value) => value.name).toSet(), {
        'retry',
        'repair',
        'escalate',
      });
    },
  );
}
