import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exam_platform/models/question.dart';
import 'package:exam_platform/services/local_question_repository.dart';
import 'package:exam_platform/services/question_bank_service.dart';

import '_support/dqg300_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  late QuestionBankService service;

  setUp(() async {
    service = QuestionBankService(
      repository: LocalQuestionRepository.instance,
    );
    await LocalQuestionRepository.instance.replaceAll(const <Question>[]);
  });

  test('strict helper accepts only full 300/300 DQG100 evidence', () {
    final question = perfectDqg300Question();
    final result = service.requireDqg300PublicationPass(
      question,
      perfectDqg300Evidence(),
    );

    expect(result.passedRuleCount, 300);
    expect(result.failedRuleCount, 0);
    expect(result.dqs, 100);
    expect(result.isPublishable, isTrue);
  });

  test('missing evidence blocks strict helper', () {
    expect(
      () => service.requireDqg300PublicationPass(
        perfectDqg300Question(),
        null,
      ),
      throwsStateError,
    );
  });

  test('one failed DQG blocks strict helper', () {
    final evidence = failRuleProof(perfectDqg300Evidence(), 'DQG-137');

    expect(
      () => service.requireDqg300PublicationPass(
        perfectDqg300Question(),
        evidence,
      ),
      throwsStateError,
    );
  });

  test('unresolved warning blocks strict helper', () {
    final evidence = perfectDqg300Evidence().copyWith(
      unresolvedWarningCount: 1,
    );

    expect(
      () => service.requireDqg300PublicationPass(
        perfectDqg300Question(),
        evidence,
      ),
      throwsStateError,
    );
  });

  test('legacy answer-length toggle cannot rescue failed DQG300 evidence', () {
    final permissiveLegacyService = QuestionBankService(
      repository: LocalQuestionRepository.instance,
      answerLengthCheckEnabled: false,
    );
    final evidence = failRuleProof(perfectDqg300Evidence(), 'DQG-131');

    expect(
      () => permissiveLegacyService.requireDqg300PublicationPass(
        perfectDqg300Question(),
        evidence,
      ),
      throwsStateError,
    );
  });

  test('review question cannot become validated without DQG300 evidence', () {
    final review = Question.fromJson({
      ...perfectDqg300Question().toJson(),
      'status': 'review',
    });

    expect(
      () => service.validateForPublication(review),
      throwsStateError,
    );
    expect(service.allManagedQuestions(), isEmpty);
  });

  test('review question becomes validated with full DQG300 evidence', () async {
    final review = Question.fromJson({
      ...perfectDqg300Question().toJson(),
      'status': 'review',
    });

    final issues = await service.validateForPublication(
      review,
      qualityEvidence: perfectDqg300Evidence(),
    );

    expect(issues, isEmpty);
    expect(service.allManagedQuestions(), hasLength(1));
    expect(service.allManagedQuestions().single.status, 'validated');
  });

  test('legacy warning blocks validation even when DQG300 evidence is green', () {
    final shortReview = Question.fromJson({
      ...perfectDqg300Question().toJson(),
      'status': 'review',
      'question': 'Short scenario question.',
    });

    expect(
      () => service.validateForPublication(
        shortReview,
        qualityEvidence: perfectDqg300Evidence(),
      ),
      throwsStateError,
    );
    expect(service.allManagedQuestions(), isEmpty);
  });

  test('validated question cannot publish without DQG300 evidence', () {
    final validated = Question.fromJson({
      ...perfectDqg300Question().toJson(),
      'status': 'validated',
    });

    expect(() => service.publish(validated), throwsStateError);
    expect(service.allManagedQuestions(), isEmpty);
  });

  test('full DQG300 pass publishes and preserves correct-answer semantics', () async {
    final validated = Question.fromJson({
      ...perfectDqg300Question().toJson(),
      'status': 'validated',
    });
    final correctText = validated.options[validated.correctAnswer];

    await service.publish(
      validated,
      qualityEvidence: perfectDqg300Evidence(),
    );

    final published = service.allManagedQuestions().single;
    expect(published.status, 'published');
    expect(published.options, hasLength(4));
    expect(published.options[published.correctAnswer], correctText);
    expect(published.options.toSet(), validated.options.toSet());
  });

  test('prepared batch blocks before writes when evidence map is missing', () async {
    final question = Question.fromJson({
      ...perfectDqg300Question().toJson(),
      'status': 'draft',
    });

    expect(
      () => service.publishPreparedBatch([question]),
      throwsStateError,
    );
    expect(service.allManagedQuestions(), isEmpty);
  });

  test('prepared batch publishes with per-question 300/300 evidence', () async {
    final question = Question.fromJson({
      ...perfectDqg300Question().toJson(),
      'status': 'draft',
    });

    final result = await service.publishPreparedBatch(
      [question],
      qualityEvidenceByQuestionId: {
        question.id: perfectDqg300Evidence(),
      },
    );

    expect(result.publishedQuestionCount, 1);
    expect(result.reusedQuestionCount, 0);
    expect(service.allManagedQuestions(), hasLength(1));
    expect(service.allManagedQuestions().single.status, 'published');
  });

  test('one bad evidence record blocks entire batch before any write', () async {
    final first = Question.fromJson({
      ...perfectDqg300Question().toJson(),
      'id': 910001,
      'question': '${perfectDqg300Question().question} First variant.',
      'status': 'draft',
    });
    final second = Question.fromJson({
      ...perfectDqg300Question().toJson(),
      'id': 910002,
      'question': '${perfectDqg300Question().question} Second variant.',
      'status': 'draft',
    });

    expect(
      () => service.publishPreparedBatch(
        [first, second],
        qualityEvidenceByQuestionId: {
          first.id: perfectDqg300Evidence(),
          second.id: failRuleProof(
            perfectDqg300Evidence(),
            'DQG-281',
          ),
        },
      ),
      throwsStateError,
    );
    expect(service.allManagedQuestions(), isEmpty);
  });
}
