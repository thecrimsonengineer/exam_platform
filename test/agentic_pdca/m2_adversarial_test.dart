import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/agentic_pdca/m0_models.dart';
import '../../tool/agentic_pdca/m2_act.dart';
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
  _RetryStore(this.receipts);
  final List<M2TransientRetryReceipt> receipts;

  @override
  Future<List<M2TransientRetryReceipt>> read(
    String candidateSha,
    String packetHash,
  ) async => receipts;
}

void main() {
  final sourcePacket = M2TaskPacket.parse(
    File('docs/agentic/implementation/m2/RUN_4_PACKET.json').readAsStringSync(),
  );

  M2TaskPacket packetFor(String suffix) {
    final json = Map<String, Object?>.from(sourcePacket.toJson());
    json['task_id'] = 'M2-RUN-4-' + suffix;
    json['lineage_id'] = 'M2-CONTROLS-4-' + suffix;
    return M2TaskPacket.fromJson(json);
  }

  ControlPlaneSnapshot withBudget(
    M2TaskPacket packet,
    String candidate, {
    bool cancelled = false,
    List<HumanApprovalSnapshot>? approvals,
  }) {
    final base = testState(
      packet,
      lineageSha: candidate,
      cancelled: cancelled,
      approvals: approvals,
    );
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

  test(
    'packet mutation after DO cannot reuse old handoff or evidence',
    () async {
      final packet = packetFor('packet-revision');
      final work = M2FakeWorkspace(packet)
        ..head = m2TestCandidate
        ..changed = [packet.expectedPaths.first]
        ..commits = [m2TestCandidate]
        ..diffPatch =
            'diff --git a/' +
            packet.expectedPaths.first +
            ' b/' +
            packet.expectedPaths.first +
            '\n';
      final receipts = greenReceipts(packet);
      final handoff = await M2HandoffBuilder(
        workspace: work,
        gateEvidence: M2FakeGates(receipts),
        packet: packet,
      ).build(candidateSha: m2TestCandidate, knownLimitations: const []);

      final revisedJson = Map<String, Object?>.from(packet.toJson());
      revisedJson['revision'] = 2;
      final revised = M2TaskPacket.fromJson(revisedJson);
      final semantic = M2SemanticReviewReceipt(
        candidateSha: m2TestCandidate,
        packetHash: packet.hash,
        reviewerPrincipal: 'reviewer',
        reviewerRole: 'REVIEWER',
        readOnly: true,
        observedAt: m2TestNow,
        evidenceReference: 'review:old-packet',
        acceptanceCriteriaSatisfied: true,
        architectureConsistent: true,
        testQualityAccepted: true,
        regressionRiskAccepted: true,
        maintainabilityAccepted: true,
        behaviorMatchesTask: true,
        findings: const [],
      );
      final reviewer = M2Check3Reviewer(
        packet: revised,
        workspace: work,
        gateEvidence: M2FakeGates(receipts),
        semanticEvidence: _SemanticStore([semantic]),
        trustedState: testState(revised, lineageSha: m2TestCandidate),
        trustedClock: () => m2TestNow,
      );
      final outcome = await reviewer.review(
        candidateSha: m2TestCandidate,
        handoffJson: handoff.canonicalJson,
      );
      expect(outcome.state, M2ReviewState.reviewEscalate);
    },
  );

  test('expired approval blocks CHECK-3 authority', () async {
    final packet = packetFor('expired-approval');
    final work = M2FakeWorkspace(packet)
      ..head = m2TestCandidate
      ..changed = [packet.expectedPaths.first]
      ..commits = [m2TestCandidate]
      ..diffPatch =
          'diff --git a/' +
          packet.expectedPaths.first +
          ' b/' +
          packet.expectedPaths.first +
          '\n';
    final receipts = greenReceipts(packet);
    final handoff = await M2HandoffBuilder(
      workspace: work,
      gateEvidence: M2FakeGates(receipts),
      packet: packet,
    ).build(candidateSha: m2TestCandidate, knownLimitations: const []);
    final semantic = M2SemanticReviewReceipt(
      candidateSha: m2TestCandidate,
      packetHash: packet.hash,
      reviewerPrincipal: 'reviewer',
      reviewerRole: 'REVIEWER',
      readOnly: true,
      observedAt: m2TestNow,
      evidenceReference: 'review:expired',
      acceptanceCriteriaSatisfied: true,
      architectureConsistent: true,
      testQualityAccepted: true,
      regressionRiskAccepted: true,
      maintainabilityAccepted: true,
      behaviorMatchesTask: true,
      findings: const [],
    );
    final reviewer = M2Check3Reviewer(
      packet: packet,
      workspace: work,
      gateEvidence: M2FakeGates(receipts),
      semanticEvidence: _SemanticStore([semantic]),
      trustedState: testState(
        packet,
        lineageSha: m2TestCandidate,
        approvals: [
          testApproval(
            packet,
            expiresAt: m2TestNow.subtract(const Duration(seconds: 1)),
          ),
        ],
      ),
      trustedClock: () => m2TestNow,
    );
    final outcome = await reviewer.review(
      candidateSha: m2TestCandidate,
      handoffJson: handoff.canonicalJson,
    );
    expect(outcome.state, M2ReviewState.reviewEscalate);
    expect(
      outcome.findings.any((finding) => finding.code == 'TASK_AUTHORITY'),
      isTrue,
    );
  });

  test(
    'builder cannot self-approve CHECK-3 and ACT cannot hide escalation',
    () async {
      final packet = packetFor('self-review');
      final escalateFinding = M2ReviewFinding(
        code: 'ARCHITECTURE_CONFLICT',
        detail: 'architecture mismatch',
        disposition: M2ReviewFindingDisposition.escalate,
        evidenceReference: 'review:architecture',
        repairClass: 'F6',
      );
      final repairFinding = M2ReviewFinding(
        code: 'BEHAVIOR_MISMATCH',
        detail: 'bounded behavior defect',
        disposition: M2ReviewFindingDisposition.repairable,
        evidenceReference: 'review:behavior',
        repairClass: 'F4',
      );
      final inconsistent = M2ReviewOutcome(
        state: M2ReviewState.reviewRepairable,
        candidateSha: m2TestCandidate,
        packetHash: packet.hash,
        reviewerPrincipal: 'builder',
        findings: [escalateFinding, repairFinding],
      );
      final controller = M2ActController(
        packet: packet,
        trustedState: withBudget(packet, m2TestCandidate),
        reviewEvidence: _ReviewStore([inconsistent]),
        retryEvidence: _RetryStore(const []),
        trustedClock: () => m2TestNow,
      );
      final decision = await controller.route(
        M2ActRequest(
          attemptType: M2ActAttemptType.repair,
          failedCandidateSha: m2TestCandidate,
          repairAgent: 'repairer',
          strategy: 'repair behavior only',
          rootCause: 'candidate defect',
          evidenceReference: 'review:behavior',
          findingCode: 'BEHAVIOR_MISMATCH',
          repairClass: 'F4',
          requestedPaths: [packet.expectedPaths.first],
        ),
      );
      expect(decision.route, M2ActRoute.escalate);
    },
  );

  test(
    'cancelled lineage blocks ACT even with valid repairable review',
    () async {
      final packet = packetFor('cancelled');
      final finding = M2ReviewFinding(
        code: 'BEHAVIOR_MISMATCH',
        detail: 'bounded defect',
        disposition: M2ReviewFindingDisposition.repairable,
        evidenceReference: 'review:cancelled',
        repairClass: 'F4',
      );
      final outcome = M2ReviewOutcome(
        state: M2ReviewState.reviewRepairable,
        candidateSha: m2TestCandidate,
        packetHash: packet.hash,
        reviewerPrincipal: 'reviewer',
        findings: [finding],
      );
      final controller = M2ActController(
        packet: packet,
        trustedState: withBudget(packet, m2TestCandidate, cancelled: true),
        reviewEvidence: _ReviewStore([outcome]),
        retryEvidence: _RetryStore(const []),
        trustedClock: () => m2TestNow,
      );
      final decision = await controller.route(
        M2ActRequest(
          attemptType: M2ActAttemptType.repair,
          failedCandidateSha: m2TestCandidate,
          repairAgent: 'repairer',
          strategy: 'bounded fix',
          rootCause: 'candidate defect',
          evidenceReference: 'review:cancelled',
          findingCode: 'BEHAVIOR_MISMATCH',
          repairClass: 'F4',
          requestedPaths: [packet.expectedPaths.first],
        ),
      );
      expect(decision.route, M2ActRoute.escalate);
    },
  );

  test('M2 state surfaces contain no autonomous closure route', () {
    expect(
      M2ReviewState.values.map((value) => value.name),
      isNot(contains('closed')),
    );
    expect(
      M2ActRoute.values.map((value) => value.name),
      isNot(contains('close')),
    );
    expect(M2ActRoute.values.map((value) => value.name).toSet(), {
      'retry',
      'repair',
      'escalate',
    });
  });

  test('canonical path traversal and protected paths remain denied', () {
    final packet = packetFor('paths');
    for (final path in [
      '../tool/agentic_pdca/m2_act.dart',
      '/tmp/m2.dart',
      r'C:\temp\m2.dart',
      'lib/main.dart',
      'pubspec.yaml',
      '.github/workflows/x.yml',
    ]) {
      expect(packet.allows(path), isFalse);
    }
  });
}
