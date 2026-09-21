import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/agentic_pdca/m0_models.dart';
import '../../tool/agentic_pdca/m2_act.dart';
import '../../tool/agentic_pdca/m2_reviewer.dart';
import '../../tool/agentic_pdca/m2_task_packet.dart';
import 'm2_test_support.dart';

final class _ReviewStore implements M2TrustedReviewOutcomeEvidence {
  _ReviewStore(this.outcomes);
  List<M2ReviewOutcome> outcomes;

  @override
  Future<List<M2ReviewOutcome>> read(
    String candidateSha,
    String packetHash,
  ) async => outcomes;
}

final class _RetryStore implements M2TrustedRetryEvidence {
  _RetryStore(this.receipts);
  List<M2TransientRetryReceipt> receipts;

  @override
  Future<List<M2TransientRetryReceipt>> read(
    String candidateSha,
    String packetHash,
  ) async => receipts;
}

void main() {
  final sourcePacket = M2TaskPacket.parse(
    File('docs/agentic/implementation/m2/RUN_3_PACKET.json').readAsStringSync(),
  );

  M2TaskPacket packetFor(String suffix, {int? f4Budget}) {
    final json = Map<String, Object?>.from(sourcePacket.toJson());
    json['task_id'] = 'M2-RUN-3-' + suffix;
    json['lineage_id'] = 'M2-CONTROLS-3-' + suffix;
    if (f4Budget != null) {
      final budgets = Map<String, Object?>.from(
        (json['repair_budgets'] as Map).cast<String, Object?>(),
      );
      budgets['F4'] = f4Budget;
      json['repair_budgets'] = budgets;
    }
    return M2TaskPacket.fromJson(json);
  }

  ControlPlaneSnapshot stateFor(
    M2TaskPacket packet, {
    String candidate = m2TestCandidate,
    int mechanical = 10,
    int behavioral = 11,
    int architecture = 0,
    bool cancelled = false,
  }) {
    final base = testState(
      packet,
      lineageSha: candidate,
      cancelled: cancelled,
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
          mechanicalRemaining: mechanical,
          behavioralRemaining: behavioral,
          architectureRemaining: architecture,
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

  M2ReviewOutcome repairableOutcome(
    M2TaskPacket packet, {
    String code = 'BEHAVIOR_MISMATCH',
    String repairClass = 'F4',
    String evidence = 'review:finding',
  }) =>
      M2ReviewOutcome(
        state: M2ReviewState.reviewRepairable,
        candidateSha: m2TestCandidate,
        packetHash: packet.hash,
        reviewerPrincipal: 'reviewer',
        findings: [
          M2ReviewFinding(
            code: code,
            detail: 'bounded defect',
            disposition: M2ReviewFindingDisposition.repairable,
            evidenceReference: evidence,
            repairClass: repairClass,
          ),
        ],
      );

  M2TransientRetryReceipt retryReceipt(M2TaskPacket packet) =>
      M2TransientRetryReceipt(
        candidateSha: m2TestCandidate,
        packetHash: packet.hash,
        transientInfrastructure: true,
        observedAt: m2TestNow,
        evidenceReference: 'ci:transient',
      );

  M2ActController controller(
    M2TaskPacket packet, {
    M2ReviewOutcome? outcome,
    List<M2TransientRetryReceipt>? retries,
    M2RepairBudgetStore? store,
    ControlPlaneSnapshot? state,
  }) =>
      M2ActController(
        packet: packet,
        trustedState: state ?? stateFor(packet),
        reviewEvidence: _ReviewStore([
          outcome ?? repairableOutcome(packet),
        ]),
        retryEvidence: _RetryStore(retries ?? [retryReceipt(packet)]),
        budgetStore: store,
        trustedClock: () => m2TestNow,
      );

  M2ActRequest repairRequest(
    M2TaskPacket packet, {
    String repairAgent = 'repairer-a',
    String strategy = 'fix bounded behavior',
    String findingCode = 'BEHAVIOR_MISMATCH',
    String repairClass = 'F4',
    String evidence = 'review:finding',
    List<String>? paths,
  }) =>
      M2ActRequest(
        attemptType: M2ActAttemptType.repair,
        failedCandidateSha: m2TestCandidate,
        repairAgent: repairAgent,
        strategy: strategy,
        rootCause: 'candidate-local defect',
        evidenceReference: evidence,
        findingCode: findingCode,
        repairClass: repairClass,
        requestedPaths: paths ?? [packet.expectedPaths.first],
      );

  test('bounded F4 repair consumes class and behavioral budget', () async {
    final packet = packetFor('consume');
    final decision = await controller(packet).route(repairRequest(packet));
    expect(decision.route, M2ActRoute.repair);
    expect(decision.ledgerEntry!.classRemaining, 2);
    expect(decision.ledgerEntry!.categoryRemaining, 10);
    expect(decision.ledgerEntry!.failureClass, 'F4');
  });

  test('new controller and changed repair agent cannot reset budget', () async {
    final packet = packetFor('no-reset');
    final first = await controller(packet).route(repairRequest(packet));
    expect(first.route, M2ActRoute.repair);

    final second = await controller(
      packet,
      store: M2RepairBudgetStore(),
    ).route(
      repairRequest(
        packet,
        repairAgent: 'repairer-b',
        strategy: 'different bounded fix',
      ),
    );
    expect(second.route, M2ActRoute.repair);
    expect(second.ledgerEntry!.classRemaining, 1);
    expect(second.ledgerEntry!.categoryRemaining, 9);
  });

  test('higher trusted snapshot cannot replenish consumed balance', () async {
    final packet = packetFor('clamp');
    final store = M2RepairBudgetStore();
    await controller(packet, store: store).route(repairRequest(packet));
    final second = await controller(
      packet,
      store: M2RepairBudgetStore(),
      state: stateFor(packet, mechanical: 99, behavioral: 99),
    ).route(repairRequest(packet, strategy: 'second strategy'));
    expect(second.route, M2ActRoute.repair);
    expect(second.ledgerEntry!.classRemaining, 1);
  });

  test('trusted transient retry keeps same SHA and consumes no budget', () async {
    final packet = packetFor('retry');
    final store = M2RepairBudgetStore();
    final request = M2ActRequest(
      attemptType: M2ActAttemptType.retry,
      failedCandidateSha: m2TestCandidate,
      repairAgent: 'retry-agent',
      strategy: 'rerun exact CI candidate',
      rootCause: 'runner outage',
      evidenceReference: 'caller:evidence',
    );
    final decision = await controller(packet, store: store).route(request);
    expect(decision.route, M2ActRoute.retry);
    expect(decision.candidateSha, m2TestCandidate);
    expect(store.classRemaining(packet.lineageId, 'F4'), 3);
    expect(decision.ledgerEntry!.classRemaining, isNull);

    final repeated = await controller(
      packet,
      store: M2RepairBudgetStore(),
    ).route(request);
    expect(repeated.route, M2ActRoute.escalate);
    expect(repeated.reason, 'REPEATED_RETRY_STRATEGY');
  });

  test('retry cannot request mutation or use untrusted transient evidence', () async {
    final packet = packetFor('bad-retry');
    final mutating = M2ActRequest(
      attemptType: M2ActAttemptType.retry,
      failedCandidateSha: m2TestCandidate,
      repairAgent: 'retry-agent',
      strategy: 'rerun',
      rootCause: 'runner issue',
      evidenceReference: 'evidence',
      requestedPaths: [packet.expectedPaths.first],
    );
    expect((await controller(packet).route(mutating)).route, M2ActRoute.escalate);

    final invalidReceipt = M2TransientRetryReceipt(
      candidateSha: m2TestCandidate,
      packetHash: packet.hash,
      transientInfrastructure: false,
      observedAt: m2TestNow,
      evidenceReference: 'not-transient',
    );
    final retry = M2ActRequest(
      attemptType: M2ActAttemptType.retry,
      failedCandidateSha: m2TestCandidate,
      repairAgent: 'retry-agent',
      strategy: 'rerun',
      rootCause: 'runner issue',
      evidenceReference: 'evidence',
    );
    expect(
      (
        await controller(
          packet,
          retries: [invalidReceipt],
        ).route(retry)
      ).route,
      M2ActRoute.escalate,
    );
  });

  test('repeated identical repair strategy escalates early', () async {
    final packet = packetFor('repeat');
    await controller(packet).route(repairRequest(packet));
    final repeated = await controller(
      packet,
      store: M2RepairBudgetStore(),
    ).route(repairRequest(packet, repairAgent: 'other-agent'));
    expect(repeated.route, M2ActRoute.escalate);
    expect(repeated.reason, 'REPEATED_REPAIR_STRATEGY');
  });

  test('class and category exhaustion fail closed', () async {
    final packet = packetFor('exhaust', f4Budget: 1);
    final first = await controller(packet).route(repairRequest(packet));
    expect(first.route, M2ActRoute.repair);
    final second = await controller(packet).route(
      repairRequest(packet, strategy: 'new strategy'),
    );
    expect(second.route, M2ActRoute.escalate);

    final categoryPacket = packetFor('category');
    final categoryState = stateFor(categoryPacket, behavioral: 0);
    expect(
      (
        await controller(
          categoryPacket,
          state: categoryState,
        ).route(repairRequest(categoryPacket))
      ).route,
      M2ActRoute.escalate,
    );
  });

  test('zero-budget and unpermitted repair classes escalate', () async {
    for (final failureClass in ['F6', 'F8', 'F9', 'F10']) {
      final packet = packetFor('zero-' + failureClass);
      final outcome = repairableOutcome(
        packet,
        code: 'FINDING-' + failureClass,
        repairClass: failureClass,
      );
      final decision = await controller(packet, outcome: outcome).route(
        repairRequest(
          packet,
          findingCode: 'FINDING-' + failureClass,
          repairClass: failureClass,
        ),
      );
      expect(decision.route, M2ActRoute.escalate);
    }
  });

  test('F7 requires trusted current-candidate regression finding', () async {
    final packet = packetFor('f7');
    final badOutcome = repairableOutcome(
      packet,
      code: 'FROZEN_REGRESSION_UNKNOWN_CAUSE',
      repairClass: 'F7',
    );
    expect(
      (
        await controller(packet, outcome: badOutcome).route(
          repairRequest(
            packet,
            findingCode: 'FROZEN_REGRESSION_UNKNOWN_CAUSE',
            repairClass: 'F7',
          ),
        )
      ).route,
      M2ActRoute.escalate,
    );

    final goodOutcome = repairableOutcome(
      packet,
      code: 'FROZEN_REGRESSION_CURRENT_CANDIDATE',
      repairClass: 'F7',
    );
    final good = await controller(packet, outcome: goodOutcome).route(
      repairRequest(
        packet,
        strategy: 'restore candidate regression',
        findingCode: 'FROZEN_REGRESSION_CURRENT_CANDIDATE',
        repairClass: 'F7',
      ),
    );
    expect(good.route, M2ActRoute.repair);
  });

  test('repair requires trusted repairable review and exact finding', () async {
    final packet = packetFor('review-bind');
    final accepted = M2ReviewOutcome(
      state: M2ReviewState.reviewAccepted,
      candidateSha: m2TestCandidate,
      packetHash: packet.hash,
      reviewerPrincipal: 'reviewer',
      findings: const [],
    );
    expect(
      (
        await controller(packet, outcome: accepted).route(repairRequest(packet))
      ).route,
      M2ActRoute.escalate,
    );

    expect(
      (
        await controller(packet).route(
          repairRequest(packet, evidence: 'forged:evidence'),
        )
      ).route,
      M2ActRoute.escalate,
    );
  });

  test('scope expansion, cancellation and stale lineage escalate', () async {
    final packet = packetFor('trust');
    expect(
      (
        await controller(packet).route(
          repairRequest(packet, paths: ['tool/agentic_pdca/m2_other.dart']),
        )
      ).route,
      M2ActRoute.escalate,
    );

    expect(
      (
        await controller(
          packet,
          state: stateFor(packet, cancelled: true),
        ).route(repairRequest(packet))
      ).route,
      M2ActRoute.escalate,
    );

    expect(
      (
        await controller(
          packet,
          state: stateFor(packet, candidate: packet.taskBaseSha),
        ).route(repairRequest(packet))
      ).route,
      M2ActRoute.escalate,
    );
  });

  test('ACT-2 route surface has no closure state', () {
    expect(
      M2ActRoute.values.map((value) => value.name).toSet(),
      {'retry', 'repair', 'escalate'},
    );
  });
}
