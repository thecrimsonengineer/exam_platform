import 'release_admission.dart';

enum ReleaseCandidateReviewIntent {
  approve,
  reject,
  recoveryRequired;

  String get wireValue {
    switch (this) {
      case ReleaseCandidateReviewIntent.approve:
        return 'APPROVE';
      case ReleaseCandidateReviewIntent.reject:
        return 'REJECT';
      case ReleaseCandidateReviewIntent.recoveryRequired:
        return 'RECOVERY_REQUIRED';
    }
  }
}

class ReleaseRecoveryMetadata {
  const ReleaseRecoveryMetadata({
    required this.previousStableRelease,
    required this.previousStableCommit,
    required this.previousStableTree,
    required this.rollbackEligible,
  });

  const ReleaseRecoveryMetadata.none()
    : previousStableRelease = null,
      previousStableCommit = null,
      previousStableTree = null,
      rollbackEligible = false;

  static final RegExp _gitShaPattern = RegExp(r'^[0-9a-f]{40}$');

  final String? previousStableRelease;
  final String? previousStableCommit;
  final String? previousStableTree;
  final bool rollbackEligible;

  bool get hasPreviousStable =>
      previousStableRelease != null &&
      previousStableCommit != null &&
      previousStableTree != null;

  Map<String, Object?> toJson() {
    validate();
    return <String, Object?>{
      'previousStableRelease': previousStableRelease,
      'previousStableCommit': previousStableCommit,
      'previousStableTree': previousStableTree,
      'rollbackEligible': rollbackEligible,
    };
  }

  void validate() {
    final supplied = <Object?>[
      previousStableRelease,
      previousStableCommit,
      previousStableTree,
    ].where((value) => value != null).length;

    if (supplied != 0 && supplied != 3) {
      throw const FormatException(
        'Recovery lineage must be either completely absent or complete.',
      );
    }

    if (!hasPreviousStable) {
      if (rollbackEligible) {
        throw const FormatException(
          'rollbackEligible requires complete previous stable lineage.',
        );
      }
      return;
    }

    final release = previousStableRelease!;
    final commit = previousStableCommit!;
    final tree = previousStableTree!;

    if (release.trim().isEmpty) {
      throw const FormatException('previousStableRelease must not be empty.');
    }
    if (!_gitShaPattern.hasMatch(commit)) {
      throw FormatException(
        'previousStableCommit must be a lowercase 40-character Git SHA.',
        commit,
      );
    }
    if (!_gitShaPattern.hasMatch(tree)) {
      throw FormatException(
        'previousStableTree must be a lowercase 40-character Git SHA.',
        tree,
      );
    }
  }
}

class ReleaseCandidateReviewIssue {
  const ReleaseCandidateReviewIssue({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  Map<String, Object?> toJson() => <String, Object?>{
    'code': code,
    'message': message,
  };
}

class ReleaseCandidateReviewResult {
  const ReleaseCandidateReviewResult({
    required this.intent,
    required this.allowed,
    required this.issues,
  });

  final ReleaseCandidateReviewIntent intent;
  final bool allowed;
  final List<ReleaseCandidateReviewIssue> issues;

  Map<String, Object?> toJson() => <String, Object?>{
    'intent': intent.wireValue,
    'allowed': allowed,
    'issues': issues.map((issue) => issue.toJson()).toList(),
  };
}

class ReleaseCandidateReviewPolicy {
  const ReleaseCandidateReviewPolicy();

  ReleaseCandidateReviewResult evaluate({
    required ReleaseCandidateReviewIntent intent,
    required ReleaseAdmissionResult admission,
    required ReleaseRecoveryMetadata recovery,
    required String rationale,
  }) {
    recovery.validate();

    final issues = <ReleaseCandidateReviewIssue>[];

    if (rationale.trim().isEmpty) {
      issues.add(
        const ReleaseCandidateReviewIssue(
          code: 'RCR001_RATIONALE_REQUIRED',
          message: 'Candidate review requires a non-empty rationale.',
        ),
      );
    }

    switch (intent) {
      case ReleaseCandidateReviewIntent.approve:
        if (!admission.admissible) {
          issues.add(
            const ReleaseCandidateReviewIssue(
              code: 'RCR002_APPROVAL_REQUIRES_ADMISSIBLE',
              message: 'A blocked candidate cannot be approved.',
            ),
          );
        }
        break;
      case ReleaseCandidateReviewIntent.reject:
        break;
      case ReleaseCandidateReviewIntent.recoveryRequired:
        if (!recovery.rollbackEligible) {
          issues.add(
            const ReleaseCandidateReviewIssue(
              code: 'RCR003_RECOVERY_REQUIRES_ELIGIBLE_ANCHOR',
              message:
                  'Recovery cannot be required without an eligible stable anchor.',
            ),
          );
        }
        break;
    }

    return ReleaseCandidateReviewResult(
      intent: intent,
      allowed: issues.isEmpty,
      issues: List<ReleaseCandidateReviewIssue>.unmodifiable(issues),
    );
  }
}
