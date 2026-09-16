import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android app window globally enables FLAG_SECURE', () async {
    final source = await File(
      'android/app/src/main/kotlin/com/example/exam_platform/MainActivity.kt',
    ).readAsString();

    expect(source, contains('WindowManager.LayoutParams.FLAG_SECURE'));
    expect(source, contains('window.addFlags('));
    expect(
      source,
      contains('override fun onCreate(savedInstanceState: Bundle?)'),
    );
  });

  test('screen capture protection is native app-wide, not quiz-only', () async {
    final source = await File(
      'android/app/src/main/kotlin/com/example/exam_platform/MainActivity.kt',
    ).readAsString();

    expect(source, contains('class MainActivity : FlutterActivity()'));
    expect(source, isNot(contains('QuizScreen')));
    expect(source, isNot(contains('PracticeHubScreen')));
  });
}
