import 'package:exam_platform/theme/motion/csp11_motion.dart';
import 'package:exam_platform/widgets/motion/csp11_completion_reveal.dart';
import 'package:exam_platform/widgets/motion/csp11_fade_in.dart';
import 'package:exam_platform/widgets/motion/csp11_flip_card.dart';
import 'package:exam_platform/widgets/motion/csp11_pressable.dart';
import 'package:exam_platform/widgets/motion/csp11_slide_fade.dart';
import 'package:exam_platform/widgets/motion/csp11_staggered_reveal.dart';
import 'package:exam_platform/widgets/motion/csp11_state_switcher.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) {
  return MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: Directionality(textDirection: TextDirection.ltr, child: child),
  );
}

void main() {
  testWidgets('reduced-motion matrix keeps all core content available', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            const Csp11FadeIn(child: Text('fade')),
            const Csp11SlideFade(child: Text('slide')),
            const Csp11StaggeredReveal(child: Text('stagger')),
            const Csp11CompletionReveal(child: Text('completion')),
            const Csp11FlipCard(
              front: Text('front'),
              back: Text('back'),
              isFlipped: false,
            ),
            Csp11Pressable(onTap: () {}, child: const Text('press')),
            const Csp11StateSwitcher(child: Text('switch')),
          ],
        ),
      ),
    );

    for (final text in <String>[
      'fade',
      'slide',
      'stagger',
      'completion',
      'front',
      'press',
      'switch',
    ]) {
      expect(find.text(text), findsOneWidget);
    }

    expect(find.text('back'), findsNothing);

    final slideAnimation = tester.widget<TweenAnimationBuilder<double>>(
      find.descendant(
        of: find.byType(Csp11SlideFade),
        matching: find.byType(TweenAnimationBuilder<double>),
      ),
    );
    expect(slideAnimation.duration, Csp11MotionDuration.instant);

    final switcher = tester.widget<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    );
    expect(switcher.duration, Csp11MotionDuration.instant);

    final pressScale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(pressScale.duration, Duration.zero);
  });
}
