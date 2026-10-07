import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/release_governance/release_admission.dart';
import '../../tool/release_governance/release_recovery.dart';

void main() {
  group('ReleaseRecoveryMetadata', () {
    test('supports no previous stable release', () {
      const recovery = ReleaseRecoveryMetadata.none();

      expect(recovery.hasPreviousStable, isFalse);
      expect(recovery.rollbackEligible, isFalse);
      expect(recovery.toJson(), <String, Object?>{
        'previousStableRelease': null,
        'previousStableCommit': null,
        'previousStableTree': null,
        'rollbackEligible': false,
      });
    });

    test('records a complete rollback-eligible stable anchor', () {
      const recovery = ReleaseRecoveryMetadata(
        previousStableRelease: 'csp11-1.0.0',
        previousStableCommit: '0123456789abcdef0123456789abcdef01234567',
        previousStableTree: '89abcdef0123456789abcdef0123456789abcdef',
        rollbackEligible: true,
      );

      expect(recovery.hasPreviousStable, isTrue);
      expect(recovery.toJson(), <String, Object?>{
        'previousStableRelease': 'csp11-1.0.0',
        'previousStableCommit': '0123456789abcdef0123456789abcdef01234567',
        'previousStableTree': '89abcdef0123456789abcdef0123456789abcdef',
        'rollbackEligible': true,
      });
    });

    test('allows complete lineage to be recorded but ineligible', () {
      const recovery = ReleaseRecoveryMetadata(
        previousStableRelease: 'csp11-1.0.0',
        previousStableCommit: '0123456789abcdef0123456789abcdef01234567',
        previousStableTree: '89abcdef0123456789abcdef0123456789abcdef',
        rollbackEligible: false,
      );

      expect(recovery.hasPreviousStable, isTrue);
      expect(recovery.toJson()['rollbackEligible'], isFalse);
    });

    test('blocks partial recovery lineage', () {
      const recovery = ReleaseRecoveryMetadata(
        previousStableRelease: 'csp11-1.0.0',
        previousStableCommit: null,
        previousStableTree: '89abcdef0123456789abcdef0123456789abcdef',
        rollbackEligible: false,
      );

      expect(recovery.toJson, throwsFormatException);
    });

    test('blocks rollback eligibility without a prior stable anchor', () {
      const recovery = ReleaseRecoveryMetadata(
        previousStableRelease: null,
        previousStableCommit: null,
        previousStableTree: null,
        rollbackEligible: true,
      );

      expect(recovery.toJson, throwsFormatException);
    });

    test('blocks malformed stable commit and tree identities', () {
      const badCommit = ReleaseRecoveryMetadata(
        previousStableRelease: 'csp11-1.0.0',
        previousStableCommit: 'bad',
        previousStableTree: '89abcdef0123456789abcdef0123456789abcdef',
        rollbackEligible: true,
      );
      const badTree = ReleaseRecoveryMetadata(
        previousStableRelease: 'csp11-1.0.0',
        previousStableCommit: '0123456789abcdef0123456789abcdef01234567',
        previousStableTree: 'BAD',
        rollbackEligible: true,
      );

      expect(badCommit.toJson, throwsFormatException);
      expect(badTree.toJson, throwsFormatException);
    });
  });

  group('ReleaseCandidateReviewPolicy', () {
    const policy = ReleaseCandidateReviewPolicy();

    test('allows approval only for an admissible candidate', () {
      final result = policy.evaluate(
        intent: ReleaseCandidateReviewIntent.approve,
        admission: _admissible,
        recovery: const ReleaseRecoveryMetadata.none(),
        rationale: 'Candidate passed all frozen release admission gates.',
      );

      expect(result.allowed, isTrue);
      expect(result.intent.wireValue, 'APPROVE');
      expect(result.issues, isEmpty);
    });

    test('blocks approval of a blocked candidate', () {
      final result = policy.evaluate(
        intent: ReleaseCandidateReviewIntent.approve,
        admission: _blocked,
        recovery: const ReleaseRecoveryMetadata.none(),
        rationale: 'Review attempted approval.',
      );

      expect(result.allowed, isFalse);
      expect(
        result.issues.map((issue) => issue.code),
        contains('RCR002_APPROVAL_REQUIRES_ADMISSIBLE'),
      );
    });

    test('allows explicit rejection with a rationale', () {
      final result = policy.evaluate(
        intent: ReleaseCandidateReviewIntent.reject,
        admission: _admissible,
        recovery: const ReleaseRecoveryMetadata.none(),
        rationale: 'Candidate is not selected for release.',
      );

      expect(result.allowed, isTrue);
      expect(result.intent.wireValue, 'REJECT');
    });

    test('requires review rationale for every disposition', () {
      final result = policy.evaluate(
        intent: ReleaseCandidateReviewIntent.reject,
        admission: _admissible,
        recovery: const ReleaseRecoveryMetadata.none(),
        rationale: '   ',
      );

      expect(result.allowed, isFalse);
      expect(
        result.issues.map((issue) => issue.code),
        contains('RCR001_RATIONALE_REQUIRED'),
      );
    });

    test('allows recovery-required only with an eligible anchor', () {
      final allowed = policy.evaluate(
        intent: ReleaseCandidateReviewIntent.recoveryRequired,
        admission: _blocked,
        recovery: _eligibleRecovery,
        rationale: 'Candidate is blocked and stable recovery is required.',
      );
      final blocked = policy.evaluate(
        intent: ReleaseCandidateReviewIntent.recoveryRequired,
        admission: _blocked,
        recovery: const ReleaseRecoveryMetadata.none(),
        rationale: 'Candidate is blocked.',
      );

      expect(allowed.allowed, isTrue);
      expect(allowed.intent.wireValue, 'RECOVERY_REQUIRED');
      expect(blocked.allowed, isFalse);
      expect(
        blocked.issues.map((issue) => issue.code),
        contains('RCR003_RECOVERY_REQUIRES_ELIGIBLE_ANCHOR'),
      );
    });
  });

  group('REL-GOV-9 non-execution boundary', () {
    test('recovery implementation contains no execution primitives', () async {
      final source = await File(
        'tool/release_governance/release_recovery.dart',
      ).readAsString();
      final lowered = source.toLowerCase();

      final forbidden = <String>[
        'process.run',
        'process.start',
        'git reset',
        'git checkout',
        'git switch',
        'git push',
        'firebase deploy',
        'supabase',
        'flutter build',
        'httpclient',
      ];

      for (final value in forbidden) {
        expect(lowered, isNot(contains(value)), reason: value);
      }
    });
  });
}

const ReleaseRecoveryMetadata _eligibleRecovery = ReleaseRecoveryMetadata(
  previousStableRelease: 'csp11-1.0.0',
  previousStableCommit: '0123456789abcdef0123456789abcdef01234567',
  previousStableTree: '89abcdef0123456789abcdef0123456789abcdef',
  rollbackEligible: true,
);

const ReleaseAdmissionResult _admissible = ReleaseAdmissionResult(
  decision: ReleaseAdmissionDecision.admissible,
  requiredGateCount: 17,
  passedGateCount: 17,
  blockingFailureCount: 0,
  gates: <ReleaseAdmissionGate>[],
  issues: <ReleaseAdmissionIssue>[],
);

const ReleaseAdmissionResult _blocked = ReleaseAdmissionResult(
  decision: ReleaseAdmissionDecision.blocked,
  requiredGateCount: 17,
  passedGateCount: 16,
  blockingFailureCount: 1,
  gates: <ReleaseAdmissionGate>[],
  issues: <ReleaseAdmissionIssue>[
    ReleaseAdmissionIssue(
      code: 'RGA012_REQUIRED_GATE_FAILED',
      gateId: 'RG009',
      message: 'Blocking release admission gate failed.',
    ),
  ],
);
