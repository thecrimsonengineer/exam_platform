import 'package:exam_platform/widgets/motion/csp11_slide_fade.dart';
import 'package:exam_platform/widgets/motion/csp11_staggered_reveal.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: child,
  );
}

void main() {
  testWidgets('same-key slide reveal does not replay on ordinary rebuild', (
    tester,
  ) async {
    const key = ValueKey<String>('stable-slide');

    await tester.pumpWidget(
      _host(
        const Csp11SlideFade(
          key: key,
          child: Text('first'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);

    await tester.pumpWidget(
      _host(
        const Csp11SlideFade(
          key: key,
          child: Text('updated'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('updated'), findsOneWidget);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
  });

  testWidgets('same-key staggered reveal does not replay on ordinary rebuild', (
    tester,
  ) async {
    const key = ValueKey<String>('stable-stagger');

    await tester.pumpWidget(
      _host(
        const Csp11StaggeredReveal(
          key: key,
          delay: Duration(milliseconds: 40),
          child: Text('first'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);

    await tester.pumpWidget(
      _host(
        const Csp11StaggeredReveal(
          key: key,
          delay: Duration(milliseconds: 40),
          child: Text('updated'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('updated'), findsOneWidget);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
  });
}
