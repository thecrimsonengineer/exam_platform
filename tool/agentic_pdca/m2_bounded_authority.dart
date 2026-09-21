import 'm0_models.dart';
import 'm1_mechanical_authority.dart';
import 'm2_repository.dart';
import 'm2_task_packet.dart';

/// The manifest carries only immutable packet identity. Human approval is
/// resolved from the trusted Control Plane snapshot, never supplied by DO.
final class M2ApprovedManifest {
  const M2ApprovedManifest({required this.packet});

  final M2TaskPacket packet;

  HumanApprovalSnapshot? trustedApproval(
    ControlPlaneSnapshot trustedState,
    DateTime now,
  ) {
    final matches = trustedState.humanApprovals.where(
      (approval) =>
          approval.approvalType == 'M2_TASK_PACKET' &&
          approval.subjectId == packet.taskId &&
          approval.exactShaOrObject == packet.hash &&
          approval.planRevision == packet.revision.toString() &&
          approval.governanceVersion == 'v1.0',
    );
    if (matches.length != 1) return null;
    final approval = matches.single;
    if (approval.issuedAt.toUtc().isAfter(now.toUtc()) ||
        !approval.isValidAt(now, expectedGovernanceVersion: 'v1.0')) {
      return null;
    }
    return approval;
  }
}

final class M2BuilderRequest {
  M2BuilderRequest({
    required this.packetHash,
    required this.revision,
    required this.expectedHead,
    required this.writerLeaseId,
    required this.writerIdentity,
    required this.fencingToken,
    required List<String> requestedPaths,
  }) : requestedPaths = List.unmodifiable(requestedPaths);

  final String packetHash;
  final int revision;
  final String expectedHead;
  final String writerLeaseId;
  final String writerIdentity;
  final int fencingToken;
  final List<String> requestedPaths;
}

final class M2AuthorityDecision {
  const M2AuthorityDecision(this.authorized, this.reason);

  final bool authorized;
  final String reason;
}

/// Bounded Pilot A authority preflight, not a shell or write executor.
/// Existing M1 authority supplies lineage, branch, lease and fencing checks.
final class M2BoundedAuthority {
  M2BoundedAuthority({
    required this.manifest,
    required this.workspace,
    required this.trustedState,
    DateTime Function()? trustedClock,
  }) : _clock = trustedClock ?? (() => DateTime.now().toUtc());

  final M2ApprovedManifest manifest;
  final M2TrustedWorkspace workspace;
  final ControlPlaneSnapshot trustedState;
  final DateTime Function() _clock;

  Future<M2AuthorityDecision> authorize(M2BuilderRequest request) async {
    final packet = manifest.packet;
    final now = _clock().toUtc();

    if (manifest.trustedApproval(trustedState, now) == null ||
        request.packetHash != packet.hash ||
        request.revision != packet.revision) {
      return const M2AuthorityDecision(false, 'PACKET_APPROVAL_MISMATCH');
    }

    final tasks = trustedState.tasks.where(
      (task) => task.taskId == packet.taskId,
    );
    if (tasks.length != 1 || !_taskMatchesPacket(tasks.single, packet, now)) {
      return const M2AuthorityDecision(false, 'TRUSTED_TASK_MISMATCH');
    }

    if (trustedState.governanceSha != m2GovernanceSha ||
        trustedState.governanceVersion != 'v1.0' ||
        request.expectedHead != packet.taskBaseSha ||
        request.requestedPaths.isEmpty ||
        request.requestedPaths.toSet().length !=
            request.requestedPaths.length ||
        request.requestedPaths.any(
          (p) => !packet.allows(p) || !packet.expectedPaths.contains(p),
        )) {
      return const M2AuthorityDecision(false, 'BASE_OR_SCOPE_MISMATCH');
    }

    final active = trustedState.writerLeases.where(
      (lease) =>
          (lease.branch == packet.branch ||
              lease.lineageId == packet.lineageId) &&
          lease.active &&
          lease.expiresAt.isAfter(now) &&
          (lease.revokedAt == null || now.isBefore(lease.revokedAt!)),
    );
    if (active.length != 1 ||
        active.single.writerLeaseId != request.writerLeaseId ||
        active.single.observedAt.isAfter(now) ||
        trustedState.cancellations.any(
          (c) => c.lineageId == packet.lineageId,
        )) {
      return const M2AuthorityDecision(
        false,
        'WRITER_CONFLICT_OR_CANCELLATION',
      );
    }

    try {
      final before = await workspace.read(packet.taskBaseSha);
      final phase = await workspace.repository.readFacts(
        approvedBaseSha: m2PhaseBaseSha,
      );
      if (!before.clean ||
          before.facts.head != request.expectedHead ||
          before.facts.ref != packet.branch ||
          before.facts.mergeBase != packet.taskBaseSha ||
          phase.head != request.expectedHead ||
          phase.mergeBase != m2PhaseBaseSha) {
        return const M2AuthorityDecision(false, 'UNCLEAN_OR_STALE_REPOSITORY');
      }

      final inherited =
          await M1MechanicalAuthority(
            trustedState: trustedState,
            repository: workspace.repository,
            approvedBaseSha: packet.taskBaseSha,
            trustedClock: () => now,
          ).authorize(
            M1MechanicalAuthorityRequest(
              taskId: packet.taskId,
              lineageId: packet.lineageId,
              baseSha: packet.taskBaseSha,
              expectedHead: request.expectedHead,
              branch: packet.branch,
              allowedPaths: packet.strings('allowed_paths'),
              expectedChangedPaths: request.requestedPaths,
              actionClass: 'FORMAT',
              requiredGates: packet.strings('required_check_gates'),
              writerLeaseId: request.writerLeaseId,
              writerIdentity: request.writerIdentity,
              fencingToken: request.fencingToken,
            ),
          );
      if (!inherited.authorized) {
        return M2AuthorityDecision(false, inherited.reason);
      }

      final after = await workspace.read(packet.taskBaseSha);
      final finished = _clock().toUtc();
      if (!after.clean ||
          after.facts.head != request.expectedHead ||
          after.facts.ref != packet.branch ||
          !active.single.expiresAt.isAfter(finished) ||
          (active.single.revokedAt != null &&
              !finished.isBefore(active.single.revokedAt!)) ||
          manifest.trustedApproval(trustedState, finished) == null) {
        return const M2AuthorityDecision(false, 'PREFLIGHT_CHANGED');
      }

      return const M2AuthorityDecision(
        true,
        'DO_READY: bounded Pilot A preflight only.',
      );
    } catch (_) {
      return const M2AuthorityDecision(false, 'TRUSTED_REPOSITORY_UNAVAILABLE');
    }
  }

  bool _taskMatchesPacket(
    PlanTaskSnapshot task,
    M2TaskPacket packet,
    DateTime now,
  ) =>
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
      !task.observedAt.toUtc().isAfter(now.toUtc());

  bool _sameStrings(List<String> a, List<String> b) =>
      a.length == b.length && a.toSet().containsAll(b);
}
