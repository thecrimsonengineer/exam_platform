import '../models/exam_preparation_phase.dart';
import '../models/readiness_checkpoint.dart';
import 'exam_preparation_phase_service.dart';

class ReadinessCheckpointService {
  const ReadinessCheckpointService({
    this.phaseService = const ExamPreparationPhaseService(),
    this.milestones = const <int>[90, 60, 30, 14, 7],
    this.algorithmVersion = currentAlgorithmVersion,
  });

  static const String currentAlgorithmVersion = 'm7f-checkpoint-v1';

  final ExamPreparationPhaseService phaseService;
  final List<int> milestones;
  final String algorithmVersion;

  ReadinessCheckpoint? nextCheckpoint({
    required DateTime currentDate,
    required DateTime examDate,
    required bool ultraHardAvailable,
  }) {
    final today = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );
    final exam = DateTime(examDate.year, examDate.month, examDate.day);
    final daysRemaining = exam.difference(today).inDays;
    if (daysRemaining < 0) return null;

    final ordered = milestones.toSet().toList(growable: false)
      ..sort((left, right) => right.compareTo(left));

    int? target;
    for (final milestone in ordered) {
      if (milestone <= daysRemaining) {
        target = milestone;
        break;
      }
    }
    if (target == null) return null;

    final dueDate = exam.subtract(Duration(days: target));
    final phase = phaseService.phaseForDaysRemaining(target);
    final readinessOrLater =
        phase == ExamPreparationPhase.readiness ||
        phase == ExamPreparationPhase.consolidation;

    return ReadinessCheckpoint(
      milestoneDaysRemaining: target,
      dueDate: dueDate,
      status: target == daysRemaining
          ? ReadinessCheckpointStatus.due
          : ReadinessCheckpointStatus.upcoming,
      phase: phase,
      questionCount: switch (phase) {
        ExamPreparationPhase.foundation => 20,
        ExamPreparationPhase.integration => 25,
        ExamPreparationPhase.readiness => 30,
        ExamPreparationPhase.consolidation => 35,
      },
      includeHard: true,
      includeUltraHard: readinessOrLater && ultraHardAvailable,
      includeConfidencePrompts: readinessOrLater,
      includeDelayedRetrieval: phase != ExamPreparationPhase.foundation,
      reasonCodes: <String>[
        'READINESS_CHECKPOINT_${target}D',
        'EXAM_PHASE_${phase.name.toUpperCase()}',
        if (readinessOrLater && !ultraHardAvailable)
          'ULTRA_HARD_BANK_UNAVAILABLE',
      ],
      algorithmVersion: algorithmVersion,
    );
  }
}
