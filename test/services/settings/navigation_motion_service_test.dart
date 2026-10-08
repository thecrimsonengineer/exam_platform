import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exam_platform/services/settings/navigation_motion_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    NavigationMotionService.isEnabled.value = true;
  });

  test('navigation motion defaults to enabled', () async {
    await NavigationMotionService.initialize();

    expect(NavigationMotionService.isEnabled.value, isTrue);
  });

  test('navigation motion persists disabled state', () async {
    await NavigationMotionService.setEnabled(false);
    NavigationMotionService.isEnabled.value = true;

    await NavigationMotionService.initialize();

    expect(NavigationMotionService.isEnabled.value, isFalse);
  });

  test('navigation motion toggle updates and persists state', () async {
    await NavigationMotionService.initialize();
    await NavigationMotionService.toggle();

    expect(NavigationMotionService.isEnabled.value, isFalse);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('csp11.ui.navigation_motion.v1'), isFalse);
  });
}
