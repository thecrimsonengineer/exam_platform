import 'package:flutter_test/flutter_test.dart';
import 'package:exam_platform/services/quiz_service.dart';

void main() {
  group('Dedicated subtopic quiz minimum', () {
    test('fewer than five published questions is not ready', () {
      expect(QuizService.hasMinimumPublishedQuestions(0), isFalse);
      expect(QuizService.hasMinimumPublishedQuestions(4), isFalse);
    });

    test('five or more published questions is ready', () {
      expect(QuizService.hasMinimumPublishedQuestions(5), isTrue);
      expect(QuizService.hasMinimumPublishedQuestions(6), isTrue);
      expect(QuizService.hasMinimumPublishedQuestions(20), isTrue);
    });
  });
}
