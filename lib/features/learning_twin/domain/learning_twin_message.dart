import 'learning_twin_action.dart';
import 'learning_twin_context.dart';
import 'learning_twin_state.dart';
import 'learning_twin_trigger.dart';

final class LearningTwinMessage {
  const LearningTwinMessage({
    required this.id,
    required this.state,
    required this.trigger,
    required this.body,
    this.title,
    this.action,
    this.unsolicited = true,
    this.allowRepeat = false,
    this.priority = 0,
    this.screenId,
    this.domainId,
    this.competencyId,
    this.topicId,
    this.subtopicId,
  }) : assert(id != ''),
       assert(body != '');

  final String id;
  final LearningTwinState state;
  final LearningTwinTrigger trigger;
  final String body;
  final String? title;
  final LearningTwinAction? action;

  /// Unsolicited messages count against the one-per-screen-visit rule.
  final bool unsolicited;

  /// Repeat delivery is opt-in. The default is fail-quiet after first show.
  final bool allowRepeat;

  /// Higher values win. Equal priority is resolved by stable message ID.
  final int priority;

  final String? screenId;
  final String? domainId;
  final String? competencyId;
  final String? topicId;
  final String? subtopicId;

  bool matchesContext(LearningTwinContext context) {
    if (trigger != context.trigger) {
      return false;
    }
    if (screenId != null && screenId != context.screenId) {
      return false;
    }
    if (domainId != null && domainId != context.domainId) {
      return false;
    }
    if (competencyId != null && competencyId != context.competencyId) {
      return false;
    }
    if (topicId != null && topicId != context.topicId) {
      return false;
    }
    if (subtopicId != null && subtopicId != context.subtopicId) {
      return false;
    }
    return true;
  }
}
