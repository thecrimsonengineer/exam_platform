import 'dart:io';

import 'package:exam_platform/features/learning_twin/ui/learning_twin_motion_manifest.dart';
import 'package:exam_platform/features/learning_twin/ui/learning_twin_motion_renderer.dart';
import 'package:exam_platform/features/learning_twin/ui/learning_twin_motion_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

void main() {
  late LearningTwinMotionManifest manifest;

  setUpAll(() async {
    final raw = await File(
      LearningTwinMotionManifest.assetPath,
    ).readAsString();
    manifest = LearningTwinMotionManifest.parse(raw).manifest!;
  });

  Future<void> pumpRenderer(
    WidgetTester tester, {
    bool animationEnabled = false,
    bool disableAnimations = false,
    bool decorative = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Scaffold(
            body: LearningTwinMotionRenderer(
              state: LearningTwinMotionState.celebrate,
              size: 96,
              animationEnabled: animationEnabled,
              decorative: decorative,
              manifest: manifest,
              eventKey: 'celebrate:1',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('static policy selects SVG without changing avatar size', (
    tester,
  ) async {
    await pumpRenderer(tester);

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byType(Lottie), findsNothing);

    final size = tester.getSize(find.byType(LearningTwinMotionRenderer));
    expect(size, const Size(96, 96));
  });

  testWidgets('reduced motion selects SVG even when animation is enabled', (
    tester,
  ) async {
    await pumpRenderer(
      tester,
      animationEnabled: true,
      disableAnimations: true,
    );

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byType(Lottie), findsNothing);
  });

  testWidgets('decorative renderer excludes image semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpRenderer(tester, decorative: true);
      expect(
        find.bySemanticsLabel('Naveed Learning Guide'),
        findsNothing,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('meaningful renderer exposes one concise image label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpRenderer(tester);
      expect(
        find.bySemanticsLabel('Naveed Learning Guide'),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });
}
