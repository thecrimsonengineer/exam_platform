import 'package:exam_platform/features/learning_twin/ui/learning_twin_card.dart';
import 'package:exam_platform/theme/glass/student_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpCard(
  WidgetTester tester, {
  required Brightness brightness,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: const Scaffold(
        body: LearningTwinCard(
          title: 'Study first, then test recall',
          message: 'Open one topic at a time.',
          invertSurfaceContrast: true,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('inverse guidance card is dark in light mode', (tester) async {
    await _pumpCard(tester, brightness: Brightness.light);

    final surface = tester.widget<StudentGlassSurface>(
      find.byType(StudentGlassSurface),
    );
    final gradient = surface.gradient! as LinearGradient;
    final title = tester.widget<Text>(
      find.text('Study first, then test recall'),
    );

    expect(gradient.colors.first, const Color(0xFF101827));
    expect(title.style?.color, const Color(0xFFF7F9FC));
  });

  testWidgets('inverse guidance card is light in dark mode', (tester) async {
    await _pumpCard(tester, brightness: Brightness.dark);

    final surface = tester.widget<StudentGlassSurface>(
      find.byType(StudentGlassSurface),
    );
    final gradient = surface.gradient! as LinearGradient;
    final title = tester.widget<Text>(
      find.text('Study first, then test recall'),
    );

    expect(gradient.colors.first, const Color(0xFFF7F9FC));
    expect(title.style?.color, const Color(0xFF18243A));
  });
}
