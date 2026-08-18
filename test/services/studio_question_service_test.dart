import 'package:flutter_test/flutter_test.dart';

import 'package:exam_platform/services/local_question_repository.dart';
import 'package:exam_platform/services/question_bank_service.dart';
import 'package:exam_platform/services/studio/studio_question_service.dart';

void main() {
  group('StudioQuestionService', () {
    test('uses the existing question management service boundary', () {
      final service = StudioQuestionService(
        questionBankService: QuestionBankService(
          repository: LocalQuestionRepository.instance,
        ),
      );

      expect(service.allManagedQuestions(), isA<List>());
      expect(service.answerLengthCheckEnabled, isTrue);
    });

    test('keeps the Studio service answer-length setting independent', () {
      final service = StudioQuestionService(
        questionBankService: QuestionBankService(
          repository: LocalQuestionRepository.instance,
        ),
      );

      service.answerLengthCheckEnabled = false;

      expect(service.answerLengthCheckEnabled, isFalse);

      service.answerLengthCheckEnabled = true;
      expect(service.answerLengthCheckEnabled, isTrue);
    });
  });
}
