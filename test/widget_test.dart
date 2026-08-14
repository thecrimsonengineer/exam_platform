import 'package:flutter_test/flutter_test.dart';

import 'package:exam_platform/main.dart';

void main() {
  testWidgets('Exam Platform application starts successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ExamPlatformApp());

    await tester.pumpAndSettle();

    expect(find.byType(ExamPlatformApp), findsOneWidget);
  });
}
