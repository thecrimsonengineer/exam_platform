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

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      HapticPreferenceService.preferenceKey: true,
    });
    await HapticPreferenceService.initialize();

    driver = _RecordingHapticDriver();
    Csp11Haptics.debugSetDriver(driver);
  });

  tearDown(Csp11Haptics.debugResetDriver);

  test('semantic convenience methods route to the frozen event vocabulary', () async {
    await Csp11Haptics.selection();
    await Csp11Haptics.navigation();
    await Csp11Haptics.confirm();
    await Csp11Haptics.success();
    await Csp11Haptics.warning();
    await Csp11Haptics.error();
    await Csp11Haptics.criticalDecision();
    await Csp11Haptics.completion();

    expect(
      driver.events,
      <Csp11HapticEvent>[
        Csp11HapticEvent.selection,
        Csp11HapticEvent.navigation,
        Csp11HapticEvent.confirm,
        Csp11HapticEvent.success,
        Csp11HapticEvent.warning,
        Csp11HapticEvent.error,
        Csp11HapticEvent.criticalDecision,
        Csp11HapticEvent.completion,
      ],
    );
  });

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
}
