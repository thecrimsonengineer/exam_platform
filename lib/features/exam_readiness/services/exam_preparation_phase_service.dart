import '../models/exam_preparation_phase.dart';

class ExamPreparationPhaseService {
  const ExamPreparationPhaseService({
    this.configuration = const ExamPreparationPhaseConfiguration(),
  });

  final ExamPreparationPhaseConfiguration configuration;

  ExamPreparationPhase phaseForDaysRemaining(int daysRemaining) {
    configuration.validate();

    if (daysRemaining >= configuration.foundationMinimumDays) {
      return ExamPreparationPhase.foundation;
    }
    if (daysRemaining >= configuration.integrationMinimumDays) {
      return ExamPreparationPhase.integration;
    }
    if (daysRemaining >= configuration.readinessMinimumDays) {
      return ExamPreparationPhase.readiness;
    }
    return ExamPreparationPhase.consolidation;
  }

  ExamPreparationPhase phaseFor({
    required DateTime currentDate,
    required DateTime examDate,
  }) {
    final current = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );
    final exam = DateTime(examDate.year, examDate.month, examDate.day);
    return phaseForDaysRemaining(exam.difference(current).inDays);
  }

  PhaseAllocationProfile allocationForDaysRemaining(int daysRemaining) {
    final phase = phaseForDaysRemaining(daysRemaining);
    return configuration.allocationFor(phase);
  }
}
