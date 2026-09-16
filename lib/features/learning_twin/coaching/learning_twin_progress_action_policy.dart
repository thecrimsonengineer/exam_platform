import '../domain/learning_twin_domain.dart';

final class LearningTwinProgressActionBinding {
  const LearningTwinProgressActionBinding({
    required this.targetDomainId,
    required this.label,
  }) : assert(targetDomainId != ''),
       assert(label != '');

  final String targetDomainId;
  final String label;
}

/// Fail-closed policy for the first adaptive navigation slice.
///
/// M5.3 permits only explicit Domain-targeted actions that are already present
/// on the selected M3 message. Unsupported action types or missing targets do
/// not produce a button.
final class LearningTwinProgressActionPolicy {
  const LearningTwinProgressActionPolicy();

  LearningTwinProgressActionBinding? resolve(LearningTwinMessage message) {
    final action = message.action;
    final targetId = action?.targetId;

    if (action == null || targetId == null || targetId.trim().isEmpty) {
      return null;
    }

    return switch (action.type) {
      LearningTwinActionType.openContent => LearningTwinProgressActionBinding(
        targetDomainId: targetId,
        label: action.label,
      ),
      LearningTwinActionType.continueLearning =>
        LearningTwinProgressActionBinding(
          targetDomainId: targetId,
          label: action.label,
        ),
      _ => null,
    };
  }
}
