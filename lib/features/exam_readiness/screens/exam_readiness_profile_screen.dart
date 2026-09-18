import '../repositories/evidence_snapshot_repository.dart';
import '../repositories/learner_assessment_attempt_repository.dart';
import '../services/readiness_profile_service.dart';
import 'readiness_profile_screen.dart';

@Deprecated('Use ReadinessProfileScreen.')
class ExamReadinessProfileScreen extends ReadinessProfileScreen {
  const ExamReadinessProfileScreen({
    super.key,
    EvidenceSnapshotRepository? evidenceRepository,
    LearnerAssessmentAttemptRepository? attemptRepository,
    ReadinessProfileService readinessService = const ReadinessProfileService(),
    DateTime Function()? now,
  }) : super(
         evidenceRepository: evidenceRepository,
         attemptRepository: attemptRepository,
         readinessService: readinessService,
         now: now,
       );
}
