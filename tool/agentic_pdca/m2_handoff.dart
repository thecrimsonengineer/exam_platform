import 'm2_repository.dart';
import 'm2_task_packet.dart';

/// Obtained from a trusted validation store; never an argument on build().
final class M2GateReceipt {
  const M2GateReceipt({
    required this.gate,
    required this.candidateSha,
    required this.packetHash,
    required this.exitCode,
    required this.evidenceReference,
  });
  final String gate;
  final String candidateSha;
  final String packetHash;
  final int exitCode;
  final String evidenceReference;
  Map<String, Object?> toJson() => {
    'gate': gate,
    'candidate_sha': candidateSha,
    'packet_hash': packetHash,
    'exit_code': exitCode,
    'evidence_reference': evidenceReference,
  };
}

abstract interface class M2TrustedGateEvidence {
  Future<List<M2GateReceipt>> read(String candidateSha, String packetHash);
}

final class M2Handoff {
  M2Handoff._(this.canonicalJson);
  final String canonicalJson;
}

/// Produces a handoff, never REVIEW_ACCEPTED or phase closure. Completeness of
/// trusted receipts is checked here; CHECK-2/3 still own correctness verdicts.
final class M2HandoffBuilder {
  const M2HandoffBuilder({
    required this.workspace,
    required this.gateEvidence,
    required this.packet,
  });
  final M2TrustedWorkspace workspace;
  final M2TrustedGateEvidence gateEvidence;
  final M2TaskPacket packet;

  Future<M2Handoff> build({
    required String candidateSha,
    required List<String> knownLimitations,
  }) async {
    if (!m2ExactSha(candidateSha) || candidateSha == packet.taskBaseSha) {
      throw StateError('CHECK_NOT_READY: new exact candidate required.');
    }
    final evidence = await workspace.read(packet.taskBaseSha);
    final facts = evidence.facts;
    if (!evidence.clean ||
        facts.head != candidateSha ||
        facts.ref != packet.branch ||
        facts.mergeBase != packet.taskBaseSha ||
        facts.changedPaths.isEmpty ||
        facts.changedPaths.any(
          (p) => !packet.allows(p) || !packet.expectedPaths.contains(p),
        ) ||
        facts.deletedTestPaths.isNotEmpty ||
        facts.binaryPaths.isNotEmpty ||
        evidence.commits.isEmpty ||
        evidence.commits.last != candidateSha ||
        evidence.commits.any((sha) => !m2ExactSha(sha)) ||
        evidence.diffStatistics.isEmpty) {
      throw StateError(
        'CHECK_NOT_READY: repository inventory does not satisfy packet.',
      );
    }
    final phase = await workspace.repository.readFacts(
      approvedBaseSha: m2PhaseBaseSha,
    );
    if (phase.head != candidateSha || phase.mergeBase != m2PhaseBaseSha) {
      throw StateError('CHECK_NOT_READY: wrong phase ancestry.');
    }
    final required = {
      ...packet.strings('required_targeted_tests'),
      ...packet.strings('required_architecture_gates'),
      ...packet.strings('required_check_gates').where((g) => g != 'CHECK3'),
    };
    final receipts = await gateEvidence.read(candidateSha, packet.hash);
    if (receipts.map((r) => r.gate).toSet().length != receipts.length ||
        !receipts.map((r) => r.gate).toSet().containsAll(required) ||
        receipts.any(
          (r) =>
              r.candidateSha != candidateSha ||
              r.packetHash != packet.hash ||
              r.exitCode != 0 ||
              r.evidenceReference.trim().isEmpty,
        )) {
      throw StateError('CHECK_NOT_READY: missing, stale or red gate evidence.');
    }
    final after = await workspace.read(packet.taskBaseSha);
    if (!after.clean ||
        after.facts.head != candidateSha ||
        after.facts.ref != packet.branch ||
        m2CanonicalJson(after.facts.changedPaths) !=
            m2CanonicalJson(facts.changedPaths)) {
      throw StateError('CHECK_NOT_READY: repository moved during handoff.');
    }
    final sorted = [...receipts]..sort((a, b) => a.gate.compareTo(b.gate));
    final changed = [...facts.changedPaths]..sort();
    return M2Handoff._(
      m2CanonicalJson({
        'task_id': packet.taskId,
        'lineage_id': packet.lineageId,
        'packet_hash': packet.hash,
        'revision': packet.revision,
        'base_sha': packet.taskBaseSha,
        'candidate_sha': candidateSha,
        'branch': facts.ref,
        'commits': evidence.commits,
        'changed_paths': changed,
        'diff_statistics': evidence.diffStatistics,
        'targeted_tests': packet.strings('required_targeted_tests'),
        'architecture_gates': packet.strings('required_architecture_gates'),
        'gate_results': sorted.map((r) => r.toJson()).toList(),
        'known_limitations': knownLimitations,
        'expected_changed_paths': packet.expectedPaths,
        'clean_worktree': true,
        'evidence_references': sorted.map((r) => r.evidenceReference).toList(),
        'state': 'DO_HANDOFF',
      }),
    );
  }
}
