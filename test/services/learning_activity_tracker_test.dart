import 'package:exam_platform/services/learning_activity_tracker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      LearningActivityTracker.storageKeyForUser('learner-a'):
          '{"2026-09-09":60,"2026-09-15":120}',
    });
  });

  test('weekly activity always returns ordered daily buckets', () async {
    final values = await LearningActivityTracker.instance.loadDailySeconds(
      userIdOverride: 'learner-a',
      days: 7,
      now: DateTime(2026, 9, 15, 12),
    );

    expect(values.length, 7);
    expect(values['2026-09-09'], 60);
    expect(values['2026-09-15'], 120);
  });
}
