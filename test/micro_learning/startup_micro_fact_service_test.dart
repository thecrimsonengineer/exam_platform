import 'package:exam_platform/services/micro_learning/local_micro_fact_repository.dart';
import 'package:exam_platform/services/micro_learning/startup_micro_fact_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('daily rotation ordinal is stable within a date', () {
    final morning = StartupMicroFactService.dailyRotationOrdinal(
      DateTime(2026, 9, 24, 8, 30),
    );
    final evening = StartupMicroFactService.dailyRotationOrdinal(
      DateTime(2026, 9, 24, 22, 15),
    );
    final nextDay = StartupMicroFactService.dailyRotationOrdinal(
      DateTime(2026, 9, 25, 0, 1),
    );

    expect(morning, evening);
    expect(nextDay, morning + 1);
  });

  test('real frozen bundle returns one published startup fact', () async {
    final service = StartupMicroFactService(
      clock: () => DateTime(2026, 9, 24, 12),
    );

    final fact = await service.load(rotationOrdinal: 0);

    expect(fact, isNotNull);
    expect(fact!.status, 'published');
    expect(fact.runtime.startupEligible, isTrue);
  });

  test('repository failure resolves to no fact instead of throwing', () async {
    final repository = LocalMicroFactRepository(
      assetLoader: (_) async => throw StateError('asset unavailable'),
    );
    final service = StartupMicroFactService(
      repository: repository,
      clock: () => DateTime(2026, 9, 24),
    );

    final fact = await service.load();

    expect(fact, isNull);
  });
}
