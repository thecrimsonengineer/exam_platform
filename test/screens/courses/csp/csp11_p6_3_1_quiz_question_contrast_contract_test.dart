import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test(
    'quiz question card uses dark-aware surface and explicit contrast colors',
    () {
      final card = read(
        'lib/screens/courses/csp/quiz/widgets/question/question_card.dart',
      );
      final colors = read(
        'lib/screens/courses/csp/quiz/theme/quiz_colors.dart',
      );

      expect(card, contains('gradient: QuizColors.questionGradient'));
      expect(card, contains('QuizColors.questionAccent'));
      expect(card, contains('QuizColors.questionLabel'));
      expect(card, contains('QuizColors.questionMuted'));
      expect(card, contains('QuizColors.textPrimary'));

      expect(
        card,
        isNot(
          contains(
            "colors: [\n            Color(0xFFFFFFFF),\n            Color(0xFFF8FAFF),",
          ),
        ),
      );

      expect(colors, contains('static LinearGradient get questionGradient'));
      expect(colors, contains('Color(0xFF111B2C)'));
      expect(colors, contains('Color(0xFF14243B)'));
      expect(colors, contains('Color(0xFF1D1934)'));
      expect(colors, contains('Color(0xFF60A5FA)'));
      expect(colors, contains('Color(0xFF9AA8BC)'));
    },
  );
}
