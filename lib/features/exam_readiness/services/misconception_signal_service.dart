import '../models/learner_assessment_attempt.dart';
import '../models/misconception_signal.dart';

class MisconceptionSignalService {
  const MisconceptionSignalService();

  List<MisconceptionSignal> detect({
    required String competencyId,
    required Iterable<LearnerAssessmentAttempt> attempts,
    required DateTime now,
  }) {
    final normalized = competencyId.trim().toLowerCase();
    final relevant = attempts
        .where(
          (attempt) =>
              attempt.publishedAtAttempt &&
              attempt.competencyId.trim().toLowerCase() == normalized,
        )
        .toList(growable: false)
      ..sort((left, right) => left.answeredAt.compareTo(right.answeredAt));

    final recent = relevant.length <= 12
        ? relevant
        : relevant.sublist(relevant.length - 12);

    if (recent.isEmpty) return const <MisconceptionSignal>[];

    final result = <MisconceptionSignal>[];
    final incorrect = recent.where((attempt) => !attempt.correct).toList();
    final highConfidenceIncorrect = incorrect
        .where((attempt) => attempt.confidence == LearnerConfidenceLevel.high)
        .toList();

    if (highConfidenceIncorrect.length >= 2) {
      result.add(
        MisconceptionSignal(
          competencyId: normalized,
          type: MisconceptionSignalType.highConfidenceIncorrect,
          strength: (highConfidenceIncorrect.length / recent.length)
              .clamp(0, 1),
          sampleCount: highConfidenceIncorrect.length,
          reasonCodes: const [
            'HIGH_CONFIDENCE_INCORRECT_PATTERN',
            'CALIBRATION_REPAIR_NEEDED',
          ],
          generatedAt: now,
        ),
      );
    }

    if (incorrect.length >= 3 && incorrect.length / recent.length >= 0.5) {
      result.add(
        MisconceptionSignal(
          competencyId: normalized,
          type: MisconceptionSignalType.repeatedIncorrect,
          strength: (incorrect.length / recent.length).clamp(0, 1),
          sampleCount: incorrect.length,
          reasonCodes: const ['REPEATED_INCORRECT_PATTERN'],
          generatedAt: now,
        ),
      );
    }

    final application = recent
        .where(
          (attempt) =>
              attempt.cognitiveLevel.contains('application') ||
              attempt.cognitiveLevel.contains('apply') ||
              attempt.cognitiveLevel.contains('scenario'),
        )
        .toList();
    final applicationCorrect = application.where((item) => item.correct).length;
    if (application.length >= 3 &&
        applicationCorrect / application.length < 0.5) {
      result.add(
        MisconceptionSignal(
          competencyId: normalized,
          type: MisconceptionSignalType.applicationReasoning,
          strength: 1 - (applicationCorrect / application.length),
          sampleCount: application.length,
          reasonCodes: const ['APPLICATION_REASONING_WEAK_PATTERN'],
          generatedAt: now,
        ),
      );
    }

    final ultra = recent
        .where(
          (attempt) => attempt.difficultyLane == AttemptDifficultyLane.ultraHard,
        )
        .toList();
    final ultraCorrect = ultra.where((item) => item.correct).length;
    if (ultra.length >= 3 && ultraCorrect / ultra.length < 0.5) {
      result.add(
        MisconceptionSignal(
          competencyId: normalized,
          type: MisconceptionSignalType.ultraHardDifficulty,
          strength: 1 - (ultraCorrect / ultra.length),
          sampleCount: ultra.length,
          reasonCodes: const ['ULTRA_HARD_RECHECK_NEEDED'],
          generatedAt: now,
        ),
      );
    }

    return List<MisconceptionSignal>.unmodifiable(result);
  }
}
