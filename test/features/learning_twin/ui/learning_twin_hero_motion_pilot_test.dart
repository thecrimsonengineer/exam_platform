import 'package:exam_platform/features/learning_twin/ui/learning_twin_avatar.dart';
import 'package:exam_platform/features/learning_twin/ui/learning_twin_card.dart';
import 'package:exam_platform/features/learning_twin/ui/learning_twin_celebration.dart';
import 'package:exam_platform/features/learning_twin/ui/learning_twin_hero.dart';
import 'package:exam_platform/features/learning_twin/ui/learning_twin_motion_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

void main() {
  setUp(() {
    LearningTwinMotionRenderer.clearAssetAvailabilityCacheForTesting();
  });

  Future<void> pumpHero(
    WidgetTester tester, {
    required double width,
    bool motionPilotEnabled = false,
    bool disableAnimations = false,
    Brightness brightness = Brightness.light,
    VoidCallback? onAction,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          brightness: brightness,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: brightness,
          ),
        ),
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 900),
            disableAnimations: disableAnimations,
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: LearningTwinHero(
                title: 'Your Learning Guide',
                message: 'Keep the next step clear.',
                actionLabel: 'Continue',
                onAction: onAction ?? () {},
                motionPilotEnabled: motionPilotEnabled,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('production-default Hero remains on legacy static SVG path', (
    tester,
  ) async {
    await pumpHero(tester, width: 390);

    expect(find.byType(LearningTwinAvatar), findsOneWidget);
    expect(find.byType(LearningTwinMotionRenderer), findsNothing);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byType(Lottie), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'forced pilot enters motion facade but missing idle asset is static-safe',
    (tester) async {
      await pumpHero(tester, width: 390, motionPilotEnabled: true);
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.byType(LearningTwinMotionRenderer), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.byType(Lottie), findsNothing);
      expect(find.text('Your Learning Guide'), findsOneWidget);
      expect(find.text('Keep the next step clear.'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reduced motion keeps forced pilot static', (tester) async {
    await pumpHero(
      tester,
      width: 390,
      motionPilotEnabled: true,
      disableAnimations: true,
    );

    expect(find.byType(LearningTwinMotionRenderer), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byType(Lottie), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hero CTA never waits for animation or fallback', (tester) async {
    var taps = 0;

    await pumpHero(
      tester,
      width: 390,
      motionPilotEnabled: true,
      onAction: () => taps++,
    );

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact Hero preserves 150 square avatar contract', (
    tester,
  ) async {
    await pumpHero(tester, width: 390, motionPilotEnabled: true);

    expect(
      tester.getSize(find.byType(LearningTwinAvatar)),
      const Size(150, 150),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide Hero preserves 180 square avatar contract', (tester) async {
    await pumpHero(tester, width: 760, motionPilotEnabled: true);

    expect(
      tester.getSize(find.byType(LearningTwinAvatar)),
      const Size(180, 180),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('theme change does not remove Hero content or CTA', (
    tester,
  ) async {
    await pumpHero(
      tester,
      width: 760,
      motionPilotEnabled: true,
      brightness: Brightness.dark,
    );

    expect(find.text('Your Learning Guide'), findsOneWidget);
    expect(find.text('Keep the next step clear.'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('background and resume are safe for the gated Hero path', (
    tester,
  ) async {
    await pumpHero(tester, width: 390, motionPilotEnabled: true);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('Your Learning Guide'), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Card and Celebration remain static during Hero-only pilot', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              LearningTwinCard(title: 'Card', message: 'Static card'),
              LearningTwinCelebration(
                title: 'Milestone',
                message: 'Static celebration',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(LearningTwinMotionRenderer), findsNothing);
    expect(find.byType(SvgPicture), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
