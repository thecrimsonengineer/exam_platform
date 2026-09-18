import 'package:exam_platform/services/local_question_repository.dart';
import 'package:exam_platform/services/question_bank_service.dart';
import 'package:exam_platform/services/ultra_hard_question_contract.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../quality_validator_contract/dqg300/_support/dqg300_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    await LocalQuestionRepository.instance.replaceAll(const []);
  });

  QuestionBankService service() {
    return QuestionBankService(repository: LocalQuestionRepository.instance);
  }

  test('Ultra Hard batch publishes only after exact DQG300 pass', () async {
    final question = perfectDqg300Question();
    final evidence = perfectDqg300Evidence();
    final bank = service();

    final result = await bank.publishPreparedUltraHardBatch(
      [question],
      qualityEvidenceByQuestionId: {question.id: evidence},
    );

    expect(result.publishedQuestionCount, 1);
    expect(result.reusedQuestionCount, 0);

    final stored = bank.allManagedQuestions();
    expect(stored, hasLength(1));
    expect(stored.single.status, 'published');
    expect(
      stored.single.tags,
      contains(UltraHardQuestionContract.classificationTag),
    );
  });

  test('Ultra Hard batch blocks when one atomic DQG fails', () async {
    final question = perfectDqg300Question();
    final evidence = failRuleProof(perfectDqg300Evidence(), 'DQG-101');
    final bank = service();

    expect(
      () => bank.publishPreparedUltraHardBatch(
        [question],
        qualityEvidenceByQuestionId: {question.id: evidence},
      ),
      throwsA(isA<StateError>()),
    );

    expect(bank.allManagedQuestions(), isEmpty);
  });

  test('Ultra Hard batch blocks when evidence is missing', () async {
    final question = perfectDqg300Question();
    final bank = service();

    expect(
      () => bank.publishPreparedUltraHardBatch([
        question,
      ], qualityEvidenceByQuestionId: const {}),
      throwsA(isA<StateError>()),
    );

    expect(bank.allManagedQuestions(), isEmpty);
  });
}
