import 'package:exam_platform/services/progress_analytics_event_bus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(ProgressAnalyticsEventBus.resetForTest);

  test('dirty revision remains cheap and deterministic', () {
    expect(ProgressAnalyticsEventBus.isDirty, isFalse);

    ProgressAnalyticsEventBus.markDirty();
    expect(ProgressAnalyticsEventBus.isDirty, isTrue);

    ProgressAnalyticsEventBus.markReconciled();
    expect(ProgressAnalyticsEventBus.isDirty, isFalse);
  });
}
