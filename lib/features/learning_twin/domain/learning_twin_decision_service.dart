import 'learning_twin_context.dart';
import 'learning_twin_decision.dart';
import 'learning_twin_message.dart';
import 'learning_twin_session_state.dart';

abstract interface class LearningTwinDecisionService {
  LearningTwinDecision decide({
    required LearningTwinContext context,
    required Iterable<LearningTwinMessage> candidates,
    required LearningTwinSessionState sessionState,
  });
}

final class DeterministicLearningTwinDecisionService
    implements LearningTwinDecisionService {
  const DeterministicLearningTwinDecisionService();

  @override
  LearningTwinDecision decide({
    required LearningTwinContext context,
    required Iterable<LearningTwinMessage> candidates,
    required LearningTwinSessionState sessionState,
  }) {
    // Permanent Phase M safety rule. M7 will connect this contract to the
    // real Exam Simulator state and validate the end-to-end boundary.
    if (context.isTimedExamActive) {
      return const LearningTwinDecision.none(
        LearningTwinDecisionReason.timedExamActive,
      );
    }

    final eligible = candidates
        .where((message) {
          if (!message.matchesContext(context)) {
            return false;
          }

          if (sessionState.hasDismissed(message.id)) {
            return false;
          }

          if (!message.allowRepeat && sessionState.hasShown(message.id)) {
            return false;
          }

          if (message.unsolicited &&
              sessionState.hasUnsolicitedForVisit(context.visitId)) {
            return false;
          }

          return true;
        })
        .toList(growable: false);

    if (eligible.isEmpty) {
      return const LearningTwinDecision.none(
        LearningTwinDecisionReason.noEligibleMessage,
      );
    }

    final ordered = eligible.toList(growable: true)
      ..sort((left, right) {
        final priorityOrder = right.priority.compareTo(left.priority);
        if (priorityOrder != 0) {
          return priorityOrder;
        }
        return left.id.compareTo(right.id);
      });

    return LearningTwinDecision.selected(ordered.first);
  }
}
