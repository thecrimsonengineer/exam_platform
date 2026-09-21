import 'm0_models.dart';
import 'm1_mechanical_authority.dart';
import 'm2_repository.dart';
import 'm2_task_packet.dart';

/// A manifest is supplied by the trusted host, never by the DO request.
/// Parsing a valid packet alone grants no authority.
final class M2ApprovedManifest {
  const M2ApprovedManifest({required this.packet, required this.approval});
  final M2TaskPacket packet;
  final HumanApprovalSnapshot approval;

  bool validAt(DateTime now) =>
      approval.approvalType == 'M2_TASK_PACKET' &&
      approval.subjectId == packet.taskId &&
      approval.exactShaOrObject == packet.hash &&
      approval.planRevision == packet.revision.toString() &&
      approval.issuer == 'Naveed' &&
      !approval.issuedAt.isAfter(now) &&
      approval.isValidAt(now, expectedGovernanceVersion: 'v1.0');
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
    if (!manifest.validAt(now) ||
        request.packetHash != packet.hash ||
        request.revision != packet.revision) {
      return const M2AuthorityDecision(false, 'PACKET_APPROVAL_MISMATCH');
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
          !manifest.validAt(finished)) {
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
}
