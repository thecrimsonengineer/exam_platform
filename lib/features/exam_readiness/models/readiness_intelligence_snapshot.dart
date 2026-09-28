import 'competency_readiness_profile.dart';
import 'evidence_confidence.dart';

enum ReadinessIntelligenceState {
  insufficientEvidence,
  building,
  progressing,
  strong,
  atRisk,
}

enum ReadinessNextActionKind {
  diagnostic,
  targetedPractice,
  flashcardReview,
  studyReview,
  lab,
  confidenceCalibration,
  simulation,
}

class ReadinessNextAction {
  const ReadinessNextAction({
    required this.kind,
    required this.competencyId,
    required this.minutes,
    required this.reasonCodes,
    required this.reasonText,
  });

  final ReadinessNextActionKind kind;
  final String competencyId;
  final int minutes;
  final List<String> reasonCodes;
  final String reasonText;
}

class ReadinessIntelligenceSnapshot {
  const ReadinessIntelligenceSnapshot({
    required this.generatedAt,
    required this.state,
    required this.overallScore,
    required this.evidenceConfidence,
    required this.knowledge,
    required this.application,
    required this.retention,
    required this.blueprintCoverage,
    required this.difficultyCoverage,
    required this.recency,
    required this.confidenceCalibration,
    required this.evidenceSufficiency,
    required this.strongCompetencyIds,
    required this.weakCompetencyIds,
    required this.evidenceGapCompetencyIds,
    required this.dueFlashcards,
    required this.nextBestAction,
    required this.reasonCodes,
    required this.algorithmVersion,
  });

  final DateTime generatedAt;
  final ReadinessIntelligenceState state;
  final int? overallScore;
  final EvidenceConfidence evidenceConfidence;
  final ReadinessDimension knowledge;
  final ReadinessDimension application;
  final ReadinessDimension retention;
  final double blueprintCoverage;
  final ReadinessDimension difficultyCoverage;
  final ReadinessDimension recency;
  final ReadinessDimension confidenceCalibration;
  final double evidenceSufficiency;
  final List<String> strongCompetencyIds;
  final List<String> weakCompetencyIds;
  final List<String> evidenceGapCompetencyIds;
  final int dueFlashcards;
  final ReadinessNextAction? nextBestAction;
  final List<String> reasonCodes;
  final String algorithmVersion;

  int get weakCompetencyCount => weakCompetencyIds.length;
}
