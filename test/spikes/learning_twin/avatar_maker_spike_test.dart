import 'dart:convert';
import 'dart:io';

import 'package:avatar_maker/avatar_maker.dart';
import 'package:exam_platform/spikes/learning_twin/avatar_maker_spike_main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _waitForController(
  NonPersistentAvatarMakerController controller,
) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (controller.displayedAvatarSVG.isNotEmpty) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('avatar_maker controller did not initialize.');
}

void main() {
  test(
    'M0 uses a non-persistent controller and exports SVG plus JSON',
    () async {
      final controller = NonPersistentAvatarMakerController(
        locale: const Locale('en'),
      );
      addTearDown(controller.dispose);

      await _waitForController(controller);

      expect(controller.isPersistentController(), isFalse);

      final svg = controller.getAvatarSVGSync();
      final json = controller.getJsonOptionsSync();

      expect(svg, contains('<svg'));
      expect(svg, isNotEmpty);
      expect(json, isNotEmpty);
      expect(jsonDecode(json), isA<Map<String, dynamic>>());
    },
  );

  testWidgets('M0 spike renders at phone width without framework exceptions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LearningTwinAvatarMakerSpikeApp());
    await tester.pumpAndSettle();

    expect(find.text('Phase M0 · Learning Twin Spike'), findsOneWidget);
    expect(find.text('M0 isolation contract'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('M0 spike renders at wide width without framework exceptions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LearningTwinAvatarMakerSpikeApp());
    await tester.pumpAndSettle();

    expect(find.text('avatar_maker 1.8.0 customizer'), findsOneWidget);
    expect(find.text('Canonical-export proof'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('M0 dependency remains isolated from the CSP11 production root', () {
    String read(String path) => File(path).readAsStringSync();

    final pubspec = read('pubspec.yaml');
    final mainSource = read('lib/main.dart');
    final navigation = read('lib/screens/navigation/bottom_navigation.dart');

    expect(pubspec, contains('avatar_maker: 1.8.0'));
    expect(mainSource, isNot(contains('avatar_maker')));
    expect(navigation, isNot(contains('avatar_maker')));

    for (final forbiddenAudioDependency in <String>[
      'audioplayers:',
      'just_audio:',
      'flutter_tts:',
      'speech_to_text:',
      'record:',
    ]) {
      expect(pubspec, isNot(contains(forbiddenAudioDependency)));
    }
  });
}
