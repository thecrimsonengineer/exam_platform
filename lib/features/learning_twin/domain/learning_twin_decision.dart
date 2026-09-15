import 'learning_twin_message.dart';

enum LearningTwinDecisionReason { selected, timedExamActive, noEligibleMessage }

final class LearningTwinDecision {
  const LearningTwinDecision.selected(LearningTwinMessage selectedMessage)
    : reason = LearningTwinDecisionReason.selected,
      message = selectedMessage;

  const LearningTwinDecision.none(this.reason)
    : assert(reason != LearningTwinDecisionReason.selected),
      message = null;

  final LearningTwinDecisionReason reason;
  final LearningTwinMessage? message;

  bool get hasMessage => message != null;
}
