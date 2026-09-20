import 'package:exam_platform/theme/motion/csp11_motion.dart';
import 'package:exam_platform/widgets/motion/csp11_status_reveal.dart';
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
  testWidgets('status reveal is static under reduced motion', (tester) async {
    await tester.pumpWidget(
      _host(
        disableAnimations: true,
        child: const Csp11StatusReveal(
          kind: Csp11StatusKind.error,
          child: Text('error'),
        ),
      ),
    );

    expect(find.text('error'), findsOneWidget);
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
  });

  testWidgets('loading status uses quick semantic duration', (tester) async {
    await tester.pumpWidget(
      _host(
        child: const Csp11StatusReveal(
          kind: Csp11StatusKind.loading,
          child: Text('loading'),
        ),
      ),
    );

    final animation = tester.widget<TweenAnimationBuilder<double>>(
      find.byType(TweenAnimationBuilder<double>),
    );
    expect(animation.duration, Csp11MotionDuration.quick);
  });

  testWidgets('empty status uses standard semantic duration', (tester) async {
    await tester.pumpWidget(
      _host(
        child: const Csp11StatusReveal(
          kind: Csp11StatusKind.empty,
          child: Text('empty'),
        ),
      ),
    );

    final animation = tester.widget<TweenAnimationBuilder<double>>(
      find.byType(TweenAnimationBuilder<double>),
    );
    expect(animation.duration, Csp11MotionDuration.standard);
  });
}
