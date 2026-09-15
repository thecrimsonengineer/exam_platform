import 'learning_twin_context.dart';
import 'learning_twin_message.dart';

abstract interface class LearningTwinRepository {
  Future<List<LearningTwinMessage>> messagesFor(LearningTwinContext context);
}
