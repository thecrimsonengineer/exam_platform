import 'package:exam_platform/widgets/motion/csp11_staggered_reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host({required Widget child, bool disableAnimations = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('reduced motion bypasses staged reveal animation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        disableAnimations: true,
        child: const Csp11StaggeredReveal(
          delay: Duration(milliseconds: 150),
          child: Text('READY'),
        ),
      ),
    );

    expect(find.text('READY'), findsOneWidget);
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
  });

  testWidgets('normal motion honors delay and reaches fully visible state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        child: const Csp11StaggeredReveal(
          delay: Duration(milliseconds: 100),
          duration: Duration(milliseconds: 200),
          child: Text('READY'),
        ),
      ),
    );

    var opacity = tester.widget<Opacity>(find.byType(Opacity).first);
    expect(opacity.opacity, 0);

    await tester.pump(const Duration(milliseconds: 100));
    opacity = tester.widget<Opacity>(find.byType(Opacity).first);
    expect(opacity.opacity, closeTo(0, 0.01));

    await tester.pump(const Duration(milliseconds: 200));
    opacity = tester.widget<Opacity>(find.byType(Opacity).first);
    expect(opacity.opacity, closeTo(1, 0.001));
  });
}
