import 'package:exam_platform/theme/motion/csp11_motion.dart';
import 'package:exam_platform/widgets/motion/csp11_flip_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host({required Widget child, bool disableAnimations = false}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Directionality(textDirection: TextDirection.ltr, child: child),
  );
}

void main() {
  testWidgets('future flashcard flip is static under reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        disableAnimations: true,
        child: const Csp11FlipCard(
          front: Text('front'),
          back: Text('back'),
          isFlipped: false,
        ),
      ),
    );

    expect(find.text('front'), findsOneWidget);
    expect(find.text('back'), findsNothing);

    await tester.pumpWidget(
      _host(
        disableAnimations: true,
        child: const Csp11FlipCard(
          front: Text('front'),
          back: Text('back'),
          isFlipped: true,
        ),
      ),
    );

    expect(find.text('front'), findsNothing);
    expect(find.text('back'), findsOneWidget);
  });

  testWidgets('future flashcard flip uses emphasized motion by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        child: const Csp11FlipCard(
          front: Text('front'),
          back: Text('back'),
          isFlipped: false,
        ),
      ),
    );

    final animation = tester.widget<TweenAnimationBuilder<double>>(
      find.byType(TweenAnimationBuilder<double>),
    );
    expect(animation.duration, Csp11MotionDuration.emphasized);
  });
}
