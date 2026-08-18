import 'package:flutter_test/flutter_test.dart';

import 'package:exam_platform/main.dart';

void main() {
  testWidgets('Exam Platform application starts successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ExamPlatformApp());

    // Allow the first frame and initial widget startup work to complete.
    await tester.pump();

    expect(find.byType(ExamPlatformApp), findsOneWidget);
  });
}
