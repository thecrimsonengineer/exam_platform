class ExamSimulationSuppressionPolicy {
  const ExamSimulationSuppressionPolicy();

  bool suppressLearningTwin({required bool isTimedSimulationActive}) =>
      isTimedSimulationActive;

  bool suppressHints({required bool isTimedSimulationActive}) =>
      isTimedSimulationActive;

  bool suppressReadinessPrompts({required bool isTimedSimulationActive}) =>
      isTimedSimulationActive;

  bool allowPostSubmissionEvidenceUpdate({
    required bool isTimedSimulationActive,
    required bool submitted,
  }) =>
      !isTimedSimulationActive || submitted;
}
