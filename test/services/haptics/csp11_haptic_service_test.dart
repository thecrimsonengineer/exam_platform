import 'package:exam_platform/services/haptics/csp11_haptic_driver.dart';
import 'package:exam_platform/services/haptics/csp11_haptic_event.dart';
import 'package:exam_platform/services/haptics/csp11_haptic_service.dart';
import 'package:exam_platform/services/settings/haptic_preference_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingHapticDriver implements Csp11HapticDriver {
  final List<Csp11HapticEvent> events = <Csp11HapticEvent>[];

  @override
  Future<void> trigger(Csp11HapticEvent event) async {
    events.add(event);
  }
}

class _ThrowingHapticDriver implements Csp11HapticDriver {
  @override
  Future<void> trigger(Csp11HapticEvent event) async {
    throw StateError('simulated haptic failure');
  }
}

void main() {
  late _RecordingHapticDriver driver;
  late DateTime now;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      HapticPreferenceService.preferenceKey: true,
    });
    await HapticPreferenceService.initialize();

    now = DateTime.utc(2026, 9, 19, 12);
    driver = _RecordingHapticDriver();
    Csp11Haptics.debugSetDriver(driver);
    Csp11Haptics.debugSetNow(() => now);
  });

  tearDown(Csp11Haptics.debugResetDriver);

  test(
    'semantic convenience methods route to the frozen event vocabulary',
    () async {
      await Csp11Haptics.selection();
      await Csp11Haptics.navigation();
      await Csp11Haptics.confirm();
      await Csp11Haptics.success();
      await Csp11Haptics.warning();
      await Csp11Haptics.error();
      await Csp11Haptics.criticalDecision();
      await Csp11Haptics.completion();

      expect(driver.events, <Csp11HapticEvent>[
        Csp11HapticEvent.selection,
        Csp11HapticEvent.navigation,
        Csp11HapticEvent.confirm,
        Csp11HapticEvent.success,
        Csp11HapticEvent.warning,
        Csp11HapticEvent.error,
        Csp11HapticEvent.criticalDecision,
        Csp11HapticEvent.completion,
      ]);
    },
  );

  test('disabled preference suppresses all haptic driver calls', () async {
    await HapticPreferenceService.setEnabled(false);

    await Csp11Haptics.navigation();
    await Csp11Haptics.success();

    expect(driver.events, isEmpty);
  });

  test('driver failure never escapes into the learner interaction', () async {
    Csp11Haptics.debugSetDriver(_ThrowingHapticDriver());

    await expectLater(Csp11Haptics.confirm(), completes);
  });

  test('rapid duplicate light events are suppressed then allowed', () async {
    await Csp11Haptics.selection();
    now = now.add(const Duration(milliseconds: 40));
    await Csp11Haptics.selection();

    expect(driver.events, <Csp11HapticEvent>[Csp11HapticEvent.selection]);

    now = now.add(const Duration(milliseconds: 41));
    await Csp11Haptics.selection();

    expect(driver.events, <Csp11HapticEvent>[
      Csp11HapticEvent.selection,
      Csp11HapticEvent.selection,
    ]);
  });

  test('strong events use the longer suppression window', () async {
    await Csp11Haptics.completion();
    now = now.add(const Duration(milliseconds: 200));
    await Csp11Haptics.completion();

    expect(driver.events, <Csp11HapticEvent>[Csp11HapticEvent.completion]);

    now = now.add(const Duration(milliseconds: 61));
    await Csp11Haptics.completion();

    expect(driver.events, <Csp11HapticEvent>[
      Csp11HapticEvent.completion,
      Csp11HapticEvent.completion,
    ]);
  });

  test('different semantic events are not collapsed together', () async {
    await Csp11Haptics.confirm();
    await Csp11Haptics.success();

    expect(driver.events, <Csp11HapticEvent>[
      Csp11HapticEvent.confirm,
      Csp11HapticEvent.success,
    ]);
  });
}
