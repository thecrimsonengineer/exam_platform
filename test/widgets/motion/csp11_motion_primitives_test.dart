import 'package:exam_platform/theme/motion/csp11_motion.dart';
import 'package:exam_platform/widgets/motion/csp11_pressable.dart';
import 'package:exam_platform/widgets/motion/csp11_state_switcher.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host({
  required Widget child,
  bool disableAnimations = false,
}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: child,
    ),
  );
}

void main() {
  testWidgets('motion preference follows MediaQuery reduced-motion state', (
    tester,
  ) async {
    late bool reduced;

    await tester.pumpWidget(
      _host(
        disableAnimations: true,
        child: Builder(
          builder: (context) {
            reduced = Csp11MotionPreferences.reduced(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(reduced, isTrue);
  });

  testWidgets('state switcher collapses to instant token under reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        disableAnimations: true,
        child: const Csp11StateSwitcher(
          child: SizedBox(key: ValueKey<String>('state')),
        ),
      ),
    );

    final switcher = tester.widget<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    );
    expect(switcher.duration, Csp11MotionDuration.instant);
  });

  testWidgets('pressable uses no scale animation under reduced motion', (
    tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      _host(
        disableAnimations: true,
        child: Csp11Pressable(
          onTap: () => taps++,
          child: const SizedBox(width: 80, height: 48),
        ),
      ),
    );

    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(scale.duration, Duration.zero);

    await tester.tap(find.byType(Csp11Pressable));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('pressable keeps the frozen subtle pressed scale', (tester) async {
    await tester.pumpWidget(
      _host(
        child: Csp11Pressable(
          onTap: () {},
          child: const SizedBox(width: 80, height: 48),
        ),
      ),
    );

    final center = tester.getCenter(find.byType(Csp11Pressable));
    final gesture = await tester.startGesture(center);
    await tester.pump();

    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(scale.scale, 0.985);
    expect(scale.duration, Csp11MotionDuration.instant);

    await gesture.up();
    await tester.pump();
  });
}
