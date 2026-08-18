import 'package:flutter_test/flutter_test.dart';

import 'package:exam_platform/models/studio_question_context.dart';

void main() {
  group('StudioQuestionContext', () {
    test('builds a deterministic canonical quiz ID', () {
      expect(
        StudioQuestionContext.canonicalQuizId('d07_c03-v1', 'd07_c03_01'),
        'd07_c03-v1_d07_c03_01_quiz',
      );
    });

    test('returns empty quiz ID when required identifiers are missing', () {
      expect(StudioQuestionContext.canonicalQuizId('', 'd07_c03_01'), '');
      expect(StudioQuestionContext.canonicalQuizId('d07_c03-v1', ''), '');
    });
  });
}
