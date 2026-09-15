import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/spikes/learning_twin/twin_identity_studio_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpStudio(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: TwinIdentityStudioScreen(
          isDarkMode: false,
          onDarkModeChanged: (_) {},
          showAuthoringLane: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('M1 studio renders on phone without package authoring lane', (
    tester,
  ) async {
    await pumpStudio(tester);

    expect(find.text('Phase M1 · Twin Identity Studio'), findsOneWidget);
    expect(find.text('M1 isolation contract'), findsOneWidget);
    expect(find.text('Professional reference set'), findsOneWidget);
    expect(find.text('Real learner-size check'), findsOneWidget);
    expect(find.text('Intentional stop boundary'), findsOneWidget);
    expect(find.textContaining('no canonical freeze'), findsOneWidget);
    expect(find.textContaining('upper-body crop'), findsOneWidget);
    expect(find.textContaining('full-body hero reference'), findsOneWidget);
  });

  testWidgets('M1 studio remains responsive on a wide surface', (tester) async {
    await pumpStudio(tester, size: const Size(1280, 900));

    expect(find.text('Professional · Neutral'), findsOneWidget);
    expect(find.text('Professional · Explain'), findsOneWidget);
    expect(find.text('Professional · Success'), findsOneWidget);
    expect(find.text('Professional · Full body'), findsOneWidget);
  });

  test('reference manifest is explicitly non-canonical', () async {
    final manifestText = await rootBundle.loadString(
      'assets/learning_twin/candidates/reference_manifest.json',
    );
    final manifest = jsonDecode(manifestText) as Map<String, dynamic>;

    expect(manifest['phase'], 'M1');
    expect(manifest['canonical_identity_frozen'], isFalse);
    expect(manifest['status'], 'candidate_reference_only');
  });

  for (final assetName in const [
    'naveed_professional_neutral.svg',
    'naveed_professional_explain.svg',
    'naveed_professional_success.svg',
    'naveed_professional_fullbody.svg',
  ]) {
    test(
      '$assetName is a local candidate SVG with no filter/network href',
      () async {
        final svg = await rootBundle.loadString(
          'assets/learning_twin/candidates/$assetName',
        );

        expect(svg, contains('<svg'));
        expect(svg, contains('data:image/png;base64,'));
        expect(svg, isNot(contains('<filter')));
        expect(svg, isNot(contains('href="http')));
        expect(svg, isNot(contains("href='http")));
      },
    );
  }

  test('production entry points do not import M1 studio', () async {
    final main = await File('lib/main.dart').readAsString();
    final navigation = await File(
      'lib/screens/navigation/bottom_navigation.dart',
    ).readAsString();

    expect(main, isNot(contains('twin_identity_studio')));
    expect(navigation, isNot(contains('twin_identity_studio')));
    expect(main, isNot(contains('avatar_maker')));
    expect(navigation, isNot(contains('avatar_maker')));
  });
}
