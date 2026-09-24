import 'package:exam_platform/services/micro_learning/local_micro_fact_repository.dart';
import 'package:exam_platform/services/micro_learning/startup_micro_fact_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('same day and ordinal select the same bundled production fact', () async {
    final service = StartupMicroFactService(
      clock: () => DateTime(2026, 9, 24, 8, 30),
    );

    final first = await service.load();
    final second = await service.load();

    expect(first, isNotNull);
    expect(second, isNotNull);
    expect(first!.microFactId, second!.microFactId);
  });

  test('daily rotation advances across the real 120-fact bundle', () async {
    final firstService = StartupMicroFactService(
      clock: () => DateTime(2026, 9, 24, 23, 59),
    );
    final secondService = StartupMicroFactService(
      clock: () => DateTime(2026, 9, 25, 0, 1),
    );

    final first = await firstService.load();
    final second = await secondService.load();

    expect(first, isNotNull);
    expect(second, isNotNull);
    expect(first!.microFactId, isNot(second!.microFactId));
  });

  test('explicit rotation ordinal is reproducible', () async {
    final service = StartupMicroFactService(
      clock: () => DateTime(2026, 9, 24),
    );

    final first = await service.load(rotationOrdinal: 17);
    final second = await service.load(rotationOrdinal: 17);

    expect(first, isNotNull);
    expect(first!.microFactId, second?.microFactId);
  });

  test('repository failure fails soft to no fact', () async {
    final service = StartupMicroFactService(
      repository: LocalMicroFactRepository(
        assetLoader: (_) async => throw StateError('bundle unavailable'),
      ),
      clock: () => DateTime(2026, 9, 24),
    );

    final result = await service.load();

    expect(result, isNull);
  });

  test('daily ordinal is stable by calendar date', () {
    expect(
      StartupMicroFactService.dailyRotationOrdinal(
        DateTime(2026, 9, 24, 0, 1),
      ),
      StartupMicroFactService.dailyRotationOrdinal(
        DateTime(2026, 9, 24, 23, 59),
      ),
    );
    expect(
      StartupMicroFactService.dailyRotationOrdinal(DateTime(2026, 9, 25)),
      StartupMicroFactService.dailyRotationOrdinal(DateTime(2026, 9, 24)) + 1,
    );
  });
}
