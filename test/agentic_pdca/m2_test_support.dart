import 'dart:convert';
import 'dart:io';

import '../../tool/agentic_pdca/m0_models.dart';
import '../../tool/agentic_pdca/m1_repository.dart';
import '../../tool/agentic_pdca/m2_bounded_authority.dart';
import '../../tool/agentic_pdca/m2_handoff.dart';
import '../../tool/agentic_pdca/m2_repository.dart';
import '../../tool/agentic_pdca/m2_task_packet.dart';

const m2TestCandidate = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
final m2TestNow = DateTime.utc(2026, 9, 21, 12);
Map<String, Object?> packetJson() =>
    (jsonDecode(
              File(
                'docs/agentic/implementation/m2/RUN_1_PACKET.json',
              ).readAsStringSync(),
            )
            as Map)
        .cast<String, Object?>();
M2TaskPacket testPacket() => M2TaskPacket.fromJson(packetJson());

M2ApprovedManifest testManifest(
  M2TaskPacket packet, {
  String? hash,
  String revision = '1',
  String status = 'ACTIVE',
  DateTime? issuedAt,
  DateTime? expiresAt,
}) => M2ApprovedManifest(
  packet: packet,
  approval: HumanApprovalSnapshot(
    approvalId: 'synthetic-approval',
    approvalType: 'M2_TASK_PACKET',
    subjectId: packet.taskId,
    exactShaOrObject: hash ?? packet.hash,
    planRevision: revision,
    governanceVersion: 'v1.0',
    issuer: 'Naveed',
    issuedAt: issuedAt ?? m2TestNow.subtract(const Duration(minutes: 1)),
    expiresAt: expiresAt,
    status: status,
  ),
);

ControlPlaneSnapshot testState(
  M2TaskPacket packet, {
  String? lineageSha,
  int fencingToken = 7,
  bool conflict = false,
  bool expired = false,
  bool cancelled = false,
}) {
  WriterLeaseSnapshot lease(String id) => WriterLeaseSnapshot(
    writerLeaseId: id,
    lineageId: packet.lineageId,
    branch: packet.branch,
    agentPrincipal: 'builder',
    fencingToken: fencingToken,
    expectedHead: packet.taskBaseSha,
    active: true,
    expiresAt: m2TestNow.add(Duration(minutes: expired ? -1 : 10)),
    observedAt: m2TestNow,
  );
  return ControlPlaneSnapshot(
    maturity: 'M0_OBSERVATION',
    governanceVersion: 'v1.0',
    governanceSha: m2GovernanceSha,
    observedAt: m2TestNow,
    tasks: const [],
    taskStates: const [],
    taskStateEvidence: const [],
    lineages: [
      LineageSnapshot(
        taskId: packet.taskId,
        lineageId: packet.lineageId,
        currentSha: lineageSha ?? packet.taskBaseSha,
        lineageGeneration: 1,
        candidateSequence: 1,
        governanceVersion: 'v1.0',
        observedAt: m2TestNow,
      ),
    ],
    authoritativeEvents: const [],
    eventEvidence: const [],
    repairBudgets: const [],
    branchHeads: const [],
    writerLeases: [lease('lease'), if (conflict) lease('other')],
    cancellations: [
      if (cancelled)
        CancellationSnapshot(
          lineageId: packet.lineageId,
          mode: 'STOP',
          reason: 'test',
          observedAt: m2TestNow,
        ),
    ],
    evidenceReferences: const [],
    humanApprovals: const [],
    writerLeaseEvidence: const [],
  );
}

final class M2FakeWorkspace implements M2TrustedWorkspace, M1TrustedRepository {
  M2FakeWorkspace(this.packet) : head = packet.taskBaseSha, ref = packet.branch;
  final M2TaskPacket packet;
  String head;
  String ref;
  String? wrongBase;
  List<String> dirty = [];
  List<String> untracked = [];
  List<String> changed = [];
  List<String> deleted = [];
  List<String> binary = [];
  List<String> commits = [];
  int reads = 0;
  void Function()? onRead;
  @override
  String get root => '.';
  @override
  M1TrustedRepository get repository => this;
  @override
  Future<M1RepositoryFacts> readFacts({
    required String approvedBaseSha,
  }) async => M1RepositoryFacts(
    root: root,
    head: head,
    ref: ref,
    mergeBase: wrongBase ?? approvedBaseSha,
    changedPaths: List.of(changed),
    deletedTestPaths: List.of(deleted),
    dirtyTrackedPaths: List.of(dirty),
    fileContents: const {},
    binaryPaths: List.of(binary),
  );
  @override
  Future<M2WorkspaceEvidence> read(String approvedBaseSha) async {
    reads++;
    onRead?.call();
    return M2WorkspaceEvidence(
      facts: await readFacts(approvedBaseSha: approvedBaseSha),
      untrackedPaths: untracked,
      commits: commits,
      diffStatistics: '1 file changed, 1 insertion(+)',
    );
  }
}

final class M2FakeGates implements M2TrustedGateEvidence {
  M2FakeGates(this.receipts);
  List<M2GateReceipt> receipts;
  @override
  Future<List<M2GateReceipt>> read(
    String candidateSha,
    String packetHash,
  ) async => receipts;
}

List<M2GateReceipt> greenReceipts(
  M2TaskPacket packet, {
  String candidate = m2TestCandidate,
  String? hash,
  int exit = 0,
}) =>
    {
          ...packet.strings('required_targeted_tests'),
          ...packet.strings('required_architecture_gates'),
          ...packet.strings('required_check_gates').where((g) => g != 'CHECK3'),
        }
        .map(
          (gate) => M2GateReceipt(
            gate: gate,
            candidateSha: candidate,
            packetHash: hash ?? packet.hash,
            exitCode: exit,
            evidenceReference: 'synthetic:$gate',
          ),
        )
        .toList();
