import 'learning_twin_context.dart';
import 'learning_twin_message.dart';

final class LearningTwinSessionState {
  LearningTwinSessionState({
    Set<String> dismissedMessageIds = const <String>{},
    Set<String> shownMessageIds = const <String>{},
    Set<String> visitsWithUnsolicitedIntervention = const <String>{},
  }) : dismissedMessageIds = Set<String>.unmodifiable(dismissedMessageIds),
       shownMessageIds = Set<String>.unmodifiable(shownMessageIds),
       visitsWithUnsolicitedIntervention = Set<String>.unmodifiable(
         visitsWithUnsolicitedIntervention,
       );

  factory LearningTwinSessionState.empty() => LearningTwinSessionState();

  final Set<String> dismissedMessageIds;
  final Set<String> shownMessageIds;
  final Set<String> visitsWithUnsolicitedIntervention;

  bool hasDismissed(String messageId) =>
      dismissedMessageIds.contains(messageId);

  bool hasShown(String messageId) => shownMessageIds.contains(messageId);

  bool hasUnsolicitedForVisit(String visitId) =>
      visitsWithUnsolicitedIntervention.contains(visitId);

  LearningTwinSessionState markShown({
    required LearningTwinMessage message,
    required LearningTwinContext context,
  }) {
    final nextShown = <String>{...shownMessageIds, message.id};
    final nextVisits = <String>{...visitsWithUnsolicitedIntervention};

    if (message.unsolicited) {
      nextVisits.add(context.visitId);
    }

    return LearningTwinSessionState(
      dismissedMessageIds: dismissedMessageIds,
      shownMessageIds: nextShown,
      visitsWithUnsolicitedIntervention: nextVisits,
    );
  }

  LearningTwinSessionState dismiss(String messageId) {
    return LearningTwinSessionState(
      dismissedMessageIds: <String>{...dismissedMessageIds, messageId},
      shownMessageIds: shownMessageIds,
      visitsWithUnsolicitedIntervention: visitsWithUnsolicitedIntervention,
    );
  }
}
