import 'dart:convert';

import 'm0_models.dart';
import 'm1_check_act.dart';
import 'm2_handoff.dart';
import 'm2_repository.dart';
import 'm2_task_packet.dart';

enum M2ReviewState { reviewAccepted, reviewRepairable, reviewEscalate }

enum M2ReviewFindingDisposition { repairable, escalate }

final class M2ReviewFinding {
  const M2ReviewFinding({
    required this.code,
    required this.detail,
    required this.disposition,
    required this.evidenceReference,
    this.repairClass,
  });

  final String code;
  final String detail;
  final M2ReviewFindingDisposition disposition;
  final String evidenceReference;
  final String? repairClass;

  Map<String, Object?> toJson() => {
    'code': code,
    'detail': detail,
    'disposition': disposition.name,
    'evidence_reference': evidenceReference,
    if (repairClass != null) 'repair_class': repairClass,
  };
}

/// Receipt from an independently authenticated read-only reviewer.
/// Callers cannot pass this receipt directly to M2Check3Reviewer.review().
final class M2SemanticReviewReceipt {
  M2SemanticReviewReceipt({
    required this.candidateSha,
    required this.packetHash,
    required this.reviewerPrincipal,
    required this.reviewerRole,
    required this.readOnly,
    required this.observedAt,
    required this.evidenceReference,
    required this.acceptanceCriteriaSatisfied,
    required this.architectureConsistent,
    required this.testQualityAccepted,
    required this.regressionRiskAccepted,
    required this.maintainabilityAccepted,
    required this.behaviorMatchesTask,
    required List<M2ReviewFinding> findings,
  }) : findings = List.unmodifiable(findings);

  final String candidateSha;
  final String packetHash;
  final String reviewerPrincipal;
  final String reviewerRole;
  final bool readOnly;
  final DateTime observedAt;
  final String evidenceReference;
  final bool acceptanceCriteriaSatisfied;
  final bool architectureConsistent;
  final bool testQualityAccepted;
  final bool regressionRiskAccepted;
  final bool maintainabilityAccepted;
  final bool behaviorMatchesTask;
  final List<M2ReviewFinding> findings;
}

abstract interface class M2TrustedSemanticReviewEvidence {
  Future<List<M2SemanticReviewReceipt>> read(
    String candidateSha,
    String packetHash,
  );
}

final class M2ReviewOutcome {
  M2ReviewOutcome({
    required this.state,
    required this.candidateSha,
    required this.packetHash,
    required this.reviewerPrincipal,
    required List<M2ReviewFinding> findings,
  }) : findings = List.unmodifiable(findings);

  final M2ReviewState state;
  final String candidateSha;
  final String packetHash;
  final String reviewerPrincipal;
  final List<M2ReviewFinding> findings;

  String get canonicalJson => m2CanonicalJson({
    'state': state.name,
    'candidate_sha': candidateSha,
    'packet_hash': packetHash,
    'reviewer_principal': reviewerPrincipal,
    'findings': findings.map((finding) => finding.toJson()).toList(),
  });
}

/// CHECK-3 only. No write, process, shell, commit, repair or closure API.
final class M2Check3Reviewer {
  M2Check3Reviewer({
    required this.packet,
    required this.workspace,
    required this.gateEvidence,
    required this.semanticEvidence,
    required this.trustedState,
    DateTime Function()? trustedClock,
  }) : _clock = trustedClock ?? (() => DateTime.now().toUtc());

  final M2TaskPacket packet;
  final M2TrustedWorkspace workspace;
  final M2TrustedGateEvidence gateEvidence;
  final M2TrustedSemanticReviewEvidence semanticEvidence;
  final ControlPlaneSnapshot trustedState;
  final DateTime Function() _clock;

  Future<M2ReviewOutcome> review({
    required String candidateSha,
    required String handoffJson,
  }) async {
    final findings = <M2ReviewFinding>[];
    final now = _clock().toUtc();

    if (!m2ExactSha(candidateSha) || candidateSha == packet.taskBaseSha) {
      return _outcome(candidateSha, '', [
        _escalate(
          'INVALID_CANDIDATE',
          'CHECK-3 requires a new exact candidate SHA.',
          'reviewer:identity',
        ),
      ]);
    }

    if (!_trustedTaskAndApprovalValid(now, candidateSha)) {
      findings.add(
        _escalate(
          'TASK_AUTHORITY',
          'Trusted task or packet approval is missing or inconsistent.',
          'reviewer:authority',
        ),
      );
    }

    M2WorkspaceEvidence? evidence;
    try {
      evidence = await workspace.read(packet.taskBaseSha);
    } catch (_) {
      findings.add(
        _escalate(
          'REPOSITORY_UNAVAILABLE',
          'Trusted read-only repository evidence is unavailable.',
          'reviewer:repository',
        ),
      );
    }
    if (evidence == null) {
      return _outcome(candidateSha, '', findings);
    }

    final facts = evidence.facts;
    if (!evidence.clean ||
        facts.head != candidateSha ||
        facts.mergeBase != packet.taskBaseSha ||
        (facts.ref.isNotEmpty && facts.ref != packet.branch)) {
      findings.add(
        _escalate(
          'CANDIDATE_IDENTITY',
          'Trusted repository state does not match the review candidate.',
          'reviewer:repository',
        ),
      );
    }

    try {
      final phase = await workspace.repository.readFacts(
        approvedBaseSha: m2PhaseBaseSha,
      );
      if (phase.head != candidateSha || phase.mergeBase != m2PhaseBaseSha) {
        findings.add(
          _escalate(
            'PHASE_ANCESTRY',
            'Candidate does not descend from the frozen M2 phase base.',
            'reviewer:ancestry',
          ),
        );
      }
    } catch (_) {
      findings.add(
        _escalate(
          'PHASE_ANCESTRY_UNAVAILABLE',
          'Trusted phase ancestry evidence is unavailable.',
          'reviewer:ancestry',
        ),
      );
    }

    final handoff = _decodeHandoff(handoffJson);
    if (!_validHandoff(handoff, candidateSha, evidence)) {
      findings.add(
        _escalate(
          'HANDOFF_MISMATCH',
          'DO handoff is missing, stale or inconsistent with trusted facts.',
          'reviewer:handoff',
        ),
      );
    }

    List<M2GateReceipt> receipts = const [];
    try {
      receipts = await gateEvidence.read(candidateSha, packet.hash);
    } catch (_) {
      findings.add(
        _escalate(
          'GATE_EVIDENCE_UNAVAILABLE',
          'Trusted gate evidence store is unavailable.',
          'reviewer:gates',
        ),
      );
    }
    final requiredGates = {
      ...packet.strings('required_targeted_tests'),
      ...packet.strings('required_architecture_gates'),
      ...packet
          .strings('required_check_gates')
          .where((gate) => gate != 'CHECK3'),
    };
    final gateNames = receipts.map((receipt) => receipt.gate).toSet();
    final validGates =
        gateNames.length == receipts.length &&
        gateNames.containsAll(requiredGates) &&
        receipts.every(
          (receipt) =>
              receipt.candidateSha == candidateSha &&
              receipt.packetHash == packet.hash &&
              receipt.exitCode == 0 &&
              receipt.evidenceReference.trim().isNotEmpty,
        );
    if (!validGates) {
      findings.add(
        _escalate(
          'GATE_EVIDENCE',
          'Trusted gate evidence is incomplete, stale, duplicated or red.',
          'reviewer:gates',
        ),
      );
    } else if (!_handoffGateResultsMatch(handoff, receipts)) {
      findings.add(
        _escalate(
          'HANDOFF_GATE_MISMATCH',
          'DO handoff gate results do not match trusted gate receipts.',
          'reviewer:gates',
        ),
      );
    }

    try {
      final integrity = await M1IntegrityScanner().scanRepository(
        repository: workspace.repository,
        approvedBaseSha: packet.taskBaseSha,
        candidateSha: candidateSha,
        expectedPaths: packet.expectedPaths,
      );
      for (final finding in integrity) {
        findings.add(
          _escalate(
            'CHECK2_' + finding.code,
            finding.detail,
            'check2:' + finding.code,
          ),
        );
      }
    } catch (_) {
      findings.add(
        _escalate(
          'CHECK2_UNAVAILABLE',
          'Independent CHECK-2 integrity scan could not complete.',
          'reviewer:check2',
        ),
      );
    }

    List<M2SemanticReviewReceipt> assessments = const [];
    try {
      assessments = await semanticEvidence.read(candidateSha, packet.hash);
    } catch (_) {
      findings.add(
        _escalate(
          'SEMANTIC_EVIDENCE_UNAVAILABLE',
          'Trusted semantic review evidence store is unavailable.',
          'reviewer:semantic',
        ),
      );
    }

    M2SemanticReviewReceipt? assessment;
    if (assessments.length != 1) {
      findings.add(
        _escalate(
          'SEMANTIC_EVIDENCE_COUNT',
          'Exactly one trusted independent reviewer receipt is required.',
          'reviewer:semantic',
        ),
      );
    } else {
      assessment = assessments.single;
      _validateAssessment(assessment, candidateSha, now, findings);
    }

    try {
      final after = await workspace.read(packet.taskBaseSha);
      if (!after.clean ||
          after.facts.head != candidateSha ||
          m2CanonicalJson(after.facts.changedPaths) !=
              m2CanonicalJson(facts.changedPaths)) {
        findings.add(
          _escalate(
            'REVIEW_RACE',
            'Repository moved during independent review.',
            'reviewer:repository',
          ),
        );
      }
    } catch (_) {
      findings.add(
        _escalate(
          'REVIEW_RACE_UNAVAILABLE',
          'Final repository stability check could not complete.',
          'reviewer:repository',
        ),
      );
    }

    return _outcome(
      candidateSha,
      assessment?.reviewerPrincipal ?? '',
      findings,
    );
  }

  bool _trustedTaskAndApprovalValid(DateTime now, String candidateSha) {
    if (trustedState.governanceSha != m2GovernanceSha ||
        trustedState.governanceVersion != 'v1.0') {
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

    final approvals = trustedState.humanApprovals.where(
      (approval) =>
          approval.approvalType == 'M2_TASK_PACKET' &&
          approval.subjectId == packet.taskId &&
          approval.exactShaOrObject == packet.hash &&
          approval.planRevision == packet.revision.toString() &&
          approval.governanceVersion == 'v1.0',
    );
    return approvals.length == 1 &&
        !approvals.single.issuedAt.toUtc().isAfter(now) &&
        approvals.single.isValidAt(now, expectedGovernanceVersion: 'v1.0');
  }

  void _validateAssessment(
    M2SemanticReviewReceipt assessment,
    String candidateSha,
    DateTime now,
    List<M2ReviewFinding> findings,
  ) {
    final builderPrincipals = {
      ...trustedState.writerLeases
          .where((lease) => lease.lineageId == packet.lineageId)
          .map((lease) => lease.agentPrincipal),
      ...trustedState.writerLeaseEvidence
          .where((lease) => lease.lineageId == packet.lineageId)
          .map((lease) => lease.agentPrincipal),
    };

    if (assessment.candidateSha != candidateSha ||
        assessment.packetHash != packet.hash ||
        assessment.reviewerPrincipal.trim().isEmpty ||
        assessment.reviewerRole != 'REVIEWER' ||
        !assessment.readOnly ||
        assessment.observedAt.toUtc().isAfter(now) ||
        assessment.evidenceReference.trim().isEmpty) {
      findings.add(
        _escalate(
          'SEMANTIC_EVIDENCE_IDENTITY',
          'Independent reviewer receipt is not valid for this candidate.',
          'reviewer:semantic',
        ),
      );
      return;
    }

    if (builderPrincipals.contains(assessment.reviewerPrincipal)) {
      findings.add(
        _escalate(
          'SELF_REVIEW',
          'Builder principal cannot independently review its own candidate.',
          assessment.evidenceReference,
        ),
      );
    }

    for (final finding in assessment.findings) {
      final valid =
          finding.code.trim().isNotEmpty &&
          finding.detail.trim().isNotEmpty &&
          finding.evidenceReference.trim().isNotEmpty &&
          (finding.disposition == M2ReviewFindingDisposition.escalate ||
              (finding.repairClass != null &&
                  packet
                      .strings('permitted_repair_classes')
                      .contains(finding.repairClass)));
      if (!valid) {
        findings.add(
          _escalate(
            'SEMANTIC_FINDING_INVALID',
            'Semantic reviewer returned an invalid repair classification.',
            assessment.evidenceReference,
          ),
        );
      } else {
        findings.add(finding);
      }
    }

    if (!assessment.acceptanceCriteriaSatisfied) {
      findings.add(
        _repairable(
          'ACCEPTANCE_CRITERIA',
          'Candidate does not yet satisfy all task acceptance criteria.',
          assessment.evidenceReference,
          'F4',
        ),
      );
    }
    if (!assessment.architectureConsistent) {
      findings.add(
        _escalate(
          'ARCHITECTURE_CONFLICT',
          'Independent review found an architecture conflict.',
          assessment.evidenceReference,
          repairClass: 'F6',
        ),
      );
    }
    if (!assessment.testQualityAccepted) {
      findings.add(
        _repairable(
          'TEST_QUALITY',
          'Independent review requires stronger or corrected tests.',
          assessment.evidenceReference,
          'F5',
        ),
      );
    }
    if (!assessment.regressionRiskAccepted) {
      findings.add(
        _repairable(
          'REGRESSION_RISK',
          'Regression risk requires bounded candidate repair.',
          assessment.evidenceReference,
          'F4',
        ),
      );
    }
    if (!assessment.maintainabilityAccepted) {
      findings.add(
        _repairable(
          'MAINTAINABILITY',
          'Maintainability finding requires bounded candidate repair.',
          assessment.evidenceReference,
          'F4',
        ),
      );
    }
    if (!assessment.behaviorMatchesTask) {
      findings.add(
        _repairable(
          'BEHAVIOR_MISMATCH',
          'Observed behavior does not fully match the approved task.',
          assessment.evidenceReference,
          'F4',
        ),
      );
    }
  }

  Map<String, Object?>? _decodeHandoff(String source) {
    try {
      final value = jsonDecode(source);
      if (value is! Map<String, dynamic>) return null;
      return value.cast<String, Object?>();
    } catch (_) {
      return null;
    }
  }

  bool _validHandoff(
    Map<String, Object?>? handoff,
    String candidateSha,
    M2WorkspaceEvidence evidence,
  ) {
    try {
      if (handoff == null) return false;
      final changed = handoff['changed_paths'];
      final expected = handoff['expected_changed_paths'];
      final commits = handoff['commits'];
      final targetedTests = handoff['targeted_tests'];
      final architectureGates = handoff['architecture_gates'];
      final knownLimitations = handoff['known_limitations'];
      if (changed is! List ||
          expected is! List ||
          commits is! List ||
          targetedTests is! List ||
          architectureGates is! List ||
          knownLimitations is! List) {
        return false;
      }

      final trustedChanged = [...evidence.facts.changedPaths]..sort();
      final handoffChanged = changed.cast<String>()..sort();
      return handoff['task_id'] == packet.taskId &&
          handoff['lineage_id'] == packet.lineageId &&
          handoff['packet_hash'] == packet.hash &&
          handoff['revision'] == packet.revision &&
          handoff['base_sha'] == packet.taskBaseSha &&
          handoff['candidate_sha'] == candidateSha &&
          handoff['branch'] == packet.branch &&
          handoff['state'] == 'DO_HANDOFF' &&
          handoff['clean_worktree'] == true &&
          commits.isNotEmpty &&
          commits.last == candidateSha &&
          m2CanonicalJson(commits) == m2CanonicalJson(evidence.commits) &&
          handoff['diff_statistics'] == evidence.diffStatistics &&
          m2CanonicalJson(handoffChanged) == m2CanonicalJson(trustedChanged) &&
          m2CanonicalJson(expected) == m2CanonicalJson(packet.expectedPaths) &&
          m2CanonicalJson(targetedTests) ==
              m2CanonicalJson(packet.strings('required_targeted_tests')) &&
          m2CanonicalJson(architectureGates) ==
              m2CanonicalJson(packet.strings('required_architecture_gates'));
    } catch (_) {
      return false;
    }
  }

  bool _handoffGateResultsMatch(
    Map<String, Object?>? handoff,
    List<M2GateReceipt> receipts,
  ) {
    try {
      if (handoff == null || handoff['gate_results'] is! List) return false;
      final trusted = [...receipts]..sort((a, b) => a.gate.compareTo(b.gate));
      final handoffResults =
          (handoff['gate_results'] as List)
              .map((value) => (value as Map).cast<String, Object?>())
              .toList()
            ..sort(
              (a, b) => (a['gate'] as String).compareTo(b['gate'] as String),
            );
      final handoffReferences = handoff['evidence_references'];
      if (handoffReferences is! List) return false;
      final trustedReferences = trusted
          .map((receipt) => receipt.evidenceReference)
          .toList();
      return m2CanonicalJson(handoffResults) ==
              m2CanonicalJson(
                trusted.map((receipt) => receipt.toJson()).toList(),
              ) &&
          m2CanonicalJson(handoffReferences) ==
              m2CanonicalJson(trustedReferences);
    } catch (_) {
      return false;
    }
  }

  M2ReviewOutcome _outcome(
    String candidateSha,
    String reviewerPrincipal,
    List<M2ReviewFinding> findings,
  ) {
    final state =
        findings.any(
          (finding) =>
              finding.disposition == M2ReviewFindingDisposition.escalate,
        )
        ? M2ReviewState.reviewEscalate
        : findings.any(
            (finding) =>
                finding.disposition == M2ReviewFindingDisposition.repairable,
          )
        ? M2ReviewState.reviewRepairable
        : M2ReviewState.reviewAccepted;

    return M2ReviewOutcome(
      state: state,
      candidateSha: candidateSha,
      packetHash: packet.hash,
      reviewerPrincipal: reviewerPrincipal,
      findings: findings,
    );
  }

  bool _sameStrings(List<String> a, List<String> b) =>
      a.length == b.length && a.toSet().containsAll(b);

  M2ReviewFinding _repairable(
    String code,
    String detail,
    String evidenceReference,
    String repairClass,
  ) => M2ReviewFinding(
    code: code,
    detail: detail,
    disposition: M2ReviewFindingDisposition.repairable,
    evidenceReference: evidenceReference,
    repairClass: repairClass,
  );

  M2ReviewFinding _escalate(
    String code,
    String detail,
    String evidenceReference, {
    String? repairClass,
  }) => M2ReviewFinding(
    code: code,
    detail: detail,
    disposition: M2ReviewFindingDisposition.escalate,
    evidenceReference: evidenceReference,
    repairClass: repairClass,
  );
}
