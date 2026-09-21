import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/agentic_pdca/m2_handoff.dart';
import '../../tool/agentic_pdca/m2_reviewer.dart';
import '../../tool/agentic_pdca/m2_task_packet.dart';
import 'm2_test_support.dart';

final class _SemanticStore implements M2TrustedSemanticReviewEvidence {
  _SemanticStore(this.receipts);

  List<M2SemanticReviewReceipt> receipts;

  @override
  Future<List<M2SemanticReviewReceipt>> read(
    String candidateSha,
    String packetHash,
  ) async => receipts;
}

void main() {
  final packet = M2TaskPacket.parse(
    File('docs/agentic/implementation/m2/RUN_2_PACKET.json').readAsStringSync(),
  );

  M2FakeWorkspace workspace() => M2FakeWorkspace(packet)
    ..head = m2TestCandidate
    ..commits = [m2TestCandidate]
    ..changed = [packet.expectedPaths.first];

  M2SemanticReviewReceipt assessment({
    String reviewer = 'reviewer',
    String role = 'REVIEWER',
    bool readOnly = true,
    String? candidate,
    String? hash,
    DateTime? observedAt,
    bool acceptance = true,
    bool architecture = true,
    bool tests = true,
    bool regression = true,
    bool maintainability = true,
    bool behavior = true,
    List<M2ReviewFinding> findings = const [],
  }) => M2SemanticReviewReceipt(
    candidateSha: candidate ?? m2TestCandidate,
    packetHash: hash ?? packet.hash,
    reviewerPrincipal: reviewer,
    reviewerRole: role,
    readOnly: readOnly,
    observedAt: observedAt ?? m2TestNow,
    evidenceReference: 'semantic:review',
    acceptanceCriteriaSatisfied: acceptance,
    architectureConsistent: architecture,
    testQualityAccepted: tests,
    regressionRiskAccepted: regression,
    maintainabilityAccepted: maintainability,
    behaviorMatchesTask: behavior,
    findings: findings,
  );

  Future<String> handoff(
    M2FakeWorkspace work, {
    List<M2GateReceipt>? receipts,
  }) async =>
      (await M2HandoffBuilder(
            workspace: work,
            gateEvidence: M2FakeGates(receipts ?? greenReceipts(packet)),
            packet: packet,
          ).build(
            candidateSha: m2TestCandidate,
            knownLimitations: ['CHECK-3 test fixture'],
          ))
          .canonicalJson;

  M2Check3Reviewer reviewer(
    M2FakeWorkspace work, {
    List<M2SemanticReviewReceipt>? assessments,
    List<M2GateReceipt>? receipts,
  }) => M2Check3Reviewer(
    packet: packet,
    workspace: work,
    gateEvidence: M2FakeGates(receipts ?? greenReceipts(packet)),
    semanticEvidence: _SemanticStore(assessments ?? [assessment()]),
    trustedState: testState(packet, lineageSha: m2TestCandidate),
    trustedClock: () => m2TestNow,
  );

  test('clean exact candidate with independent evidence is accepted', () async {
    final work = workspace();
    final before = [...work.changed];
    final outcome = await reviewer(
      work,
    ).review(candidateSha: m2TestCandidate, handoffJson: await handoff(work));
    expect(outcome.state, M2ReviewState.reviewAccepted);
    expect(outcome.findings, isEmpty);
    expect(work.changed, before);
    expect(jsonDecode(outcome.canonicalJson)['state'], 'reviewAccepted');
  });

  test('bounded semantic defect is repairable', () async {
    final work = workspace();
    final outcome = await reviewer(
      work,
      assessments: [assessment(acceptance: false)],
    ).review(candidateSha: m2TestCandidate, handoffJson: await handoff(work));
    expect(outcome.state, M2ReviewState.reviewRepairable);
    expect(
      outcome.findings.any(
        (finding) =>
            finding.code == 'ACCEPTANCE_CRITERIA' &&
            finding.repairClass == 'F4',
      ),
      isTrue,
    );
  });

  test(
    'architecture conflict escalates and dominates repairable findings',
    () async {
      final work = workspace();
      final outcome = await reviewer(
        work,
        assessments: [assessment(acceptance: false, architecture: false)],
      ).review(candidateSha: m2TestCandidate, handoffJson: await handoff(work));
      expect(outcome.state, M2ReviewState.reviewEscalate);
      expect(
        outcome.findings.any(
          (finding) => finding.code == 'ARCHITECTURE_CONFLICT',
        ),
        isTrue,
      );
    },
  );

  test('builder cannot act as independent reviewer', () async {
    final work = workspace();
    final outcome = await reviewer(
      work,
      assessments: [assessment(reviewer: 'builder')],
    ).review(candidateSha: m2TestCandidate, handoffJson: await handoff(work));
    expect(outcome.state, M2ReviewState.reviewEscalate);
    expect(
      outcome.findings.any((finding) => finding.code == 'SELF_REVIEW'),
      isTrue,
    );
  });

  test('stale Control Plane lineage candidate escalates', () async {
    final work = workspace();
    final staleReviewer = M2Check3Reviewer(
      packet: packet,
      workspace: work,
      gateEvidence: M2FakeGates(greenReceipts(packet)),
      semanticEvidence: _SemanticStore([assessment()]),
      trustedState: testState(packet),
      trustedClock: () => m2TestNow,
    );
    final outcome = await staleReviewer.review(
      candidateSha: m2TestCandidate,
      handoffJson: await handoff(work),
    );
    expect(outcome.state, M2ReviewState.reviewEscalate);
    expect(
      outcome.findings.any((finding) => finding.code == 'TASK_AUTHORITY'),
      isTrue,
    );
  });

  test('missing or duplicate semantic evidence escalates', () async {
    for (final assessments in <List<M2SemanticReviewReceipt>>[
      [],
      [assessment(), assessment(reviewer: 'reviewer-2')],
    ]) {
      final work = workspace();
      final outcome = await reviewer(
        work,
        assessments: assessments,
      ).review(candidateSha: m2TestCandidate, handoffJson: await handoff(work));
      expect(outcome.state, M2ReviewState.reviewEscalate);
    }
  });

  test(
    'stale, mutable-role or wrongly bound semantic receipt escalates',
    () async {
      for (final receipt in [
        assessment(candidate: packet.taskBaseSha),
        assessment(hash: 'forged'),
        assessment(role: 'BUILDER'),
        assessment(readOnly: false),
        assessment(observedAt: m2TestNow.add(const Duration(minutes: 1))),
      ]) {
        final work = workspace();
        final outcome = await reviewer(work, assessments: [receipt]).review(
          candidateSha: m2TestCandidate,
          handoffJson: await handoff(work),
        );
        expect(outcome.state, M2ReviewState.reviewEscalate);
      }
    },
  );

  test('red or missing trusted gate evidence escalates', () async {
    for (final receipts in <List<M2GateReceipt>>[
      [],
      greenReceipts(packet, exit: 1),
      greenReceipts(packet, hash: 'forged'),
    ]) {
      final work = workspace();
      final sourceHandoff = await handoff(work);
      final outcome = await reviewer(
        work,
        receipts: receipts,
      ).review(candidateSha: m2TestCandidate, handoffJson: sourceHandoff);
      expect(outcome.state, M2ReviewState.reviewEscalate);
    }
  });

  test(
    'dirty, out-of-scope and wrong ancestry repository state escalates',
    () async {
      final cases = [
        workspace()..dirty = ['README.md'],
        workspace()..changed = ['lib/main.dart'],
        workspace()..wrongBase = m2TestCandidate,
      ];
      for (final work in cases) {
        final cleanForHandoff = workspace();
        final outcome = await reviewer(work).review(
          candidateSha: m2TestCandidate,
          handoffJson: await handoff(cleanForHandoff),
        );
        expect(outcome.state, M2ReviewState.reviewEscalate);
      }
    },
  );

  test('detached exact read-only checkout is valid for CHECK-3', () async {
    final work = workspace()..ref = '';
    final handoffWork = workspace();
    final outcome = await reviewer(work).review(
      candidateSha: m2TestCandidate,
      handoffJson: await handoff(handoffWork),
    );
    expect(outcome.state, M2ReviewState.reviewAccepted);
  });

  test('forged handoff identity or gate results escalates', () async {
    final work = workspace();
    final source = jsonDecode(await handoff(work)) as Map<String, dynamic>;
    for (final forged in [
      {...source, 'candidate_sha': packet.taskBaseSha},
      {
        ...source,
        'changed_paths': ['tool/agentic_pdca/m2_other.dart'],
      },
      {...source, 'commits': [packet.taskBaseSha]},
      {...source, 'diff_statistics': 'forged diff'},
      {...source, 'targeted_tests': ['test/forged_test.dart']},
      {...source, 'architecture_gates': ['test/forged_arch_test.dart']},
      {...source, 'gate_results': <Object?>[]},
      {...source, 'evidence_references': ['forged:evidence']},
    ]) {
      final outcome = await reviewer(
        work,
      ).review(candidateSha: m2TestCandidate, handoffJson: jsonEncode(forged));
      expect(outcome.state, M2ReviewState.reviewEscalate);
    }
  });

  test('unbudgeted semantic repair classification escalates', () async {
    final work = workspace();
    final invalidFinding = M2ReviewFinding(
      code: 'BAD_REPAIR',
      detail: 'Cannot autonomously repair security.',
      disposition: M2ReviewFindingDisposition.repairable,
      evidenceReference: 'semantic:bad',
      repairClass: 'F9',
    );
    final outcome = await reviewer(
      work,
      assessments: [
        assessment(findings: [invalidFinding]),
      ],
    ).review(candidateSha: m2TestCandidate, handoffJson: await handoff(work));
    expect(outcome.state, M2ReviewState.reviewEscalate);
    expect(
      outcome.findings.any(
        (finding) => finding.code == 'SEMANTIC_FINDING_INVALID',
      ),
      isTrue,
    );
  });
}
