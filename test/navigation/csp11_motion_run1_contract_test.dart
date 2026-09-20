import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('Settings uses central route and state transition primitives', () {
    final navigation = read('lib/screens/navigation/bottom_navigation.dart');
    final settings = read('lib/screens/settings/settings_route.dart');

    expect(
      navigation,
      contains('Csp11Route.forward<void>(child: const SettingsRoute())'),
    );
    expect(settings, contains('Csp11StateSwitcher('));
    expect(settings, isNot(contains('AnimatedSwitcher(')));
  });

  test(
    'bottom navigation preserves cached IndexedStack state during motion',
    () {
      final source = read('lib/screens/navigation/bottom_navigation.dart');

      expect(source, contains('IndexedStack('));
      expect(source, contains('AnimationController('));
      expect(source, contains('Csp11MotionDuration.quick'));
      expect(source, contains('Csp11MotionPreferences.reduced(context)'));
      expect(source, contains('_ensureScreenBuilt(index, isDarkMode)'));
      expect(source, contains('_screensFor(isDarkMode)'));
      expect(
        source,
        isNot(contains('AnimatedSwitcher(\n              child: IndexedStack')),
      );
    },
  );

  test('route factory exposes the frozen Run 1 route families', () {
    final source = read('lib/navigation/csp11_route.dart');

    expect(source, contains('static PageRoute<T> forward<T>'));
    expect(source, contains('static PageRoute<T> detail<T>'));
    expect(source, contains('static PageRoute<T> modal<T>'));
    expect(source, contains('static PageRoute<T> replacement<T>'));
    expect(source, contains('Csp11MotionPreferences.reduced(context)'));
  });

  test('motion foundation does not import Firebase or Supabase', () {
    final roots = <Directory>[
      Directory('lib/theme/motion'),
      Directory('lib/widgets/motion'),
    ];

    final files = <File>[
      for (final root in roots)
        ...root
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart')),
      File('lib/navigation/csp11_route.dart'),
    ];

    for (final file in files) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('cloud_firestore')));
      expect(source, isNot(contains('firebase_')));
      expect(source, isNot(contains('supabase')));
    }
  });
}
