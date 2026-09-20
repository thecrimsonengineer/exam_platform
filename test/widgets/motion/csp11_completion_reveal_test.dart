import 'package:exam_platform/theme/motion/csp11_motion.dart';
import 'package:exam_platform/widgets/motion/csp11_completion_reveal.dart';
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
  testWidgets('completion reveal becomes static under reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        disableAnimations: true,
        child: const Csp11CompletionReveal(
          celebratory: true,
          child: Text('done'),
        ),
      ),
    );

    expect(find.text('done'), findsOneWidget);
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
  });

  testWidgets('celebratory completion uses the frozen celebration duration', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        child: const Csp11CompletionReveal(
          celebratory: true,
          child: Text('done'),
        ),
      ),
    );

    final animation = tester.widget<TweenAnimationBuilder<double>>(
      find.byType(TweenAnimationBuilder<double>),
    );
    expect(animation.duration, Csp11MotionDuration.celebration);
  });

  testWidgets('calm completion uses emphasized duration', (tester) async {
    await tester.pumpWidget(
      _host(
        child: const Csp11CompletionReveal(
          child: Text('done'),
        ),
      ),
    );

    final animation = tester.widget<TweenAnimationBuilder<double>>(
      find.byType(TweenAnimationBuilder<double>),
    );
    expect(animation.duration, Csp11MotionDuration.emphasized);
  });
}
