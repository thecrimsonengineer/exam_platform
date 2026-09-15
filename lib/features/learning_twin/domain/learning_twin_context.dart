import 'learning_twin_trigger.dart';

final class LearningTwinContext {
  const LearningTwinContext({
    required this.screenId,
    required this.visitId,
    required this.trigger,
    this.isTimedExamActive = false,
    this.learnerInitiated = false,
    this.domainId,
    this.competencyId,
    this.topicId,
    this.subtopicId,
  }) : assert(screenId != ''),
       assert(visitId != '');

  final String screenId;
  final String visitId;
  final LearningTwinTrigger trigger;

  /// Fail-closed contract consumed by the decision layer.
  ///
  /// M3 defines the suppression rule. M7 will bind and validate this flag
  /// against the real Exam Simulator session state.
  final bool isTimedExamActive;

  /// True only when the learner explicitly requested assistance.
  final bool learnerInitiated;

  final String? domainId;
  final String? competencyId;
  final String? topicId;
  final String? subtopicId;
}
