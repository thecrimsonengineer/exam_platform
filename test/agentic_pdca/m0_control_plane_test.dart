import 'package:flutter_test/flutter_test.dart';

import '../../tool/agentic_pdca/m0_control_plane.dart';
import '../../tool/agentic_pdca/m0_models.dart';

void main() {
  const governanceVersion = 'v1.0';
  const governanceSha = '43b2b3cc99839ae9de4092b4e2b7058d1964bff7';
  final now = DateTime.utc(2026, 9, 21, 2, 30);

  M0ObservationControlPlane plane() => M0ObservationControlPlane(
        governanceVersion: governanceVersion,
        governanceSha: governanceSha,
        trustedIssuers: const {'github-actions', 'human-review'},
        trustedClock: () => now,
      );

  PlanTaskSnapshot task() => PlanTaskSnapshot(
        taskId: 'TASK-M0-001',
        phaseId: 'AGENTIC-PDCA-M0',
        baseBranch: 'agentic-pdca-governance-v1-closed',
        baseSha: governanceSha,
        riskClass: 'R0',
        allowedPaths: const {
          'tool/agentic_pdca/**',
          'test/agentic_pdca/**',
          'docs/agentic/implementation/**',
        }.toList(),
        forbiddenPaths: const {'lib/**', 'firebase/**', 'content/**'}.toList(),
        requiredTests: const {'test/agentic_pdca/m0_control_plane_test.dart'}.toList(),
        stopConditions: const {'application feature code change'}.toList(),
        governanceVersion: governanceVersion,
        observedAt: now,
      );

  LineageSnapshot lineage({
    int generation = 1,
    int sequence = 1,
    String sha = governanceSha,
  }) =>
      LineageSnapshot(
        taskId: 'TASK-M0-001',
        lineageId: 'LINEAGE-M0-001',
        currentSha: sha,
        lineageGeneration: generation,
        candidateSequence: sequence,
        governanceVersion: governanceVersion,
        observedAt: now,
      );

  AuthoritativeEvent event({
    String eventId = 'EVENT-001',
    String source = 'github-actions',
    String governance = governanceVersion,
    String state = 'CHECK_RED',
    int generation = 1,
    int sequence = 1,
    int attempt = 1,
    String? workflowRunId = 'run-1',
  }) =>
      AuthoritativeEvent(
        eventId: eventId,
        eventType: 'CHECK_EVENT',
        sourceSystem: source,
        taskId: 'TASK-M0-001',
        lineageId: 'LINEAGE-M0-001',
        candidateSha: 'abc123',
        validationScope: 'TASK_CHECK',
        workflowRunId: workflowRunId,
        checkAttempt: attempt,
        lineageGeneration: generation,
        candidateSequence: sequence,
        state: state,
        riskClass: 'R0',
        evidenceBundleRef: 'evidence://run-1',
        governanceVersion: governance,
        timestamp: now,
      );

  void seed(M0ObservationControlPlane controlPlane) {
    controlPlane.observeTask(task());
    controlPlane.observeLineage(lineage());
  }

  group('M0 authority boundary', () {
    test('denies every protected capability', () {
      final controlPlane = plane();
      for (final capability in ControlPlaneCapability.values) {
        expect(controlPlane.permits(capability), isFalse);
      }
    });

    test('exports explicit observation-only maturity', () {
      final controlPlane = plane();
      seed(controlPlane);

      final json = controlPlane.exportJson();

      expect(json, contains('"maturity": "M0_OBSERVATION"'));
      expect(json, contains('"observation_only": true'));
      expect(json, contains(governanceSha));
    });
  });

  group('event provenance and deduplication', () {
    test('accepts trusted canonical CHECK event', () {
      final controlPlane = plane();
      seed(controlPlane);

      final result = controlPlane.observeAuthoritativeEvent(event());

      expect(result.disposition, ObservationDisposition.accepted);
      expect(controlPlane.snapshot().authoritativeEvents, hasLength(1));
      expect(controlPlane.snapshot().lineages.single.currentSha, 'abc123');
    });

    test('rejects unknown issuer but retains raw event evidence', () {
      final controlPlane = plane();
      seed(controlPlane);

      final result = controlPlane.observeAuthoritativeEvent(
        event(source: 'untrusted-agent'),
      );

      expect(
        result.disposition,
        ObservationDisposition.rejectedUntrustedIssuer,
      );
      expect(controlPlane.snapshot().authoritativeEvents, isEmpty);
      expect(controlPlane.snapshot().eventEvidence, hasLength(1));
    });

    test('rejects governance-version drift', () {
      final controlPlane = plane();
      seed(controlPlane);

      final result = controlPlane.observeAuthoritativeEvent(
        event(governance: 'v2.0'),
      );

      expect(
        result.disposition,
        ObservationDisposition.rejectedGovernanceMismatch,
      );
    });

    test('deduplicates by exact event ID', () {
      final controlPlane = plane();
      seed(controlPlane);

      expect(
        controlPlane.observeAuthoritativeEvent(event()).disposition,
        ObservationDisposition.accepted,
      );
      expect(
        controlPlane.observeAuthoritativeEvent(event()).disposition,
        ObservationDisposition.duplicateEventId,
      );
      expect(controlPlane.snapshot().authoritativeEvents, hasLength(1));
    });

    test('deduplicates semantically across different event IDs', () {
      final controlPlane = plane();
      seed(controlPlane);

      expect(
        controlPlane.observeAuthoritativeEvent(event()).disposition,
        ObservationDisposition.accepted,
      );
      expect(
        controlPlane
            .observeAuthoritativeEvent(event(eventId: 'EVENT-002'))
            .disposition,
        ObservationDisposition.duplicateSemanticEvent,
      );
      expect(controlPlane.snapshot().authoritativeEvents, hasLength(1));
      expect(controlPlane.snapshot().eventEvidence, hasLength(2));
    });
  });

  group('ordering and namespace protection', () {
    test('retains stale event as evidence without replacing current lineage', () {
      final controlPlane = plane();
      controlPlane.observeTask(task());
      controlPlane.observeLineage(
        lineage(generation: 2, sequence: 3, sha: 'newer-sha'),
      );

      final result = controlPlane.observeAuthoritativeEvent(
        event(generation: 2, sequence: 2),
      );

      expect(result.disposition, ObservationDisposition.ignoredStaleEvent);
      expect(controlPlane.snapshot().lineages.single.currentSha, 'newer-sha');
      expect(controlPlane.snapshot().eventEvidence, hasLength(1));
    });

    test('rejects CHECK event with non-CHECK state', () {
      final controlPlane = plane();
      seed(controlPlane);

      final result = controlPlane.observeAuthoritativeEvent(
        event(state: 'ACT_CLOSED'),
      );

      expect(
        result.disposition,
        ObservationDisposition.invalidObservedState,
      );
    });

    test('rejects unknown task and unknown lineage', () {
      final controlPlane = plane();

      final unknownTaskResult = controlPlane.observeAuthoritativeEvent(event());
      expect(
        unknownTaskResult.disposition,
        ObservationDisposition.rejectedUnknownTask,
      );

      controlPlane.observeTask(task());
      final unknownLineageResult =
          controlPlane.observeAuthoritativeEvent(event(eventId: 'EVENT-002'));
      expect(
        unknownLineageResult.disposition,
        ObservationDisposition.rejectedUnknownLineage,
      );
    });
  });

  group('observed control-state diagnostics', () {
    test('reports expected-head drift', () {
      final controlPlane = plane();
      controlPlane.observeBranchHead(
        BranchHeadSnapshot(
          branch: 'agentic-pdca-m0-control-plane',
          expectedHead: 'expected',
          observedHead: 'actual',
          ownerTaskId: 'TASK-M0-001',
          observedAt: now,
        ),
      );

      expect(
        controlPlane.anomalies(),
        contains('BRANCH_HEAD_DRIFT:agentic-pdca-m0-control-plane:expected:actual'),
      );
    });

    test('reports expired human approval using trusted clock', () {
      final controlPlane = plane();
      controlPlane.observeHumanApproval(
        HumanApprovalSnapshot(
          approvalId: 'APPROVAL-001',
          approvalType: 'ARCHITECTURE',
          approvedSha: governanceSha,
          planRevision: '1',
          governanceVersion: governanceVersion,
          approver: 'human',
          approvedAt: now.subtract(const Duration(days: 2)),
          validUntil: now.subtract(const Duration(days: 1)),
        ),
      );

      expect(
        controlPlane.anomalies(),
        contains('EXPIRED_APPROVAL:APPROVAL-001'),
      );
    });

    test('records observed budget, lease, cancellation, and evidence', () {
      final controlPlane = plane();
      seed(controlPlane);

      controlPlane.observeRepairBudget(
        RepairBudgetSnapshot(
          lineageId: 'LINEAGE-M0-001',
          mechanicalRemaining: 5,
          behavioralRemaining: 3,
          architectureRemaining: 0,
          observedAt: now,
        ),
      );
      controlPlane.observeWriterLease(
        WriterLeaseSnapshot(
          lineageId: 'LINEAGE-M0-001',
          branch: 'agentic-pdca-m0-control-plane',
          agentPrincipal: 'observer-only',
          fencingToken: 1,
          active: false,
          expiresAt: now,
          observedAt: now,
        ),
      );
      controlPlane.observeCancellation(
        CancellationSnapshot(
          lineageId: 'LINEAGE-M0-001',
          mode: 'NONE',
          reason: 'No cancellation observed',
          observedAt: now,
        ),
      );
      controlPlane.observeEvidenceReference(
        EvidenceReferenceSnapshot(
          referenceId: 'EVIDENCE-001',
          uri: 'github://actions/run-1',
          contentHash: 'sha256:123',
          observedAt: now,
        ),
      );

      final snapshot = controlPlane.snapshot();
      expect(snapshot.repairBudgets, hasLength(1));
      expect(snapshot.writerLeases, hasLength(1));
      expect(snapshot.cancellations, hasLength(1));
      expect(snapshot.evidenceReferences, hasLength(1));
    });
  });
}
