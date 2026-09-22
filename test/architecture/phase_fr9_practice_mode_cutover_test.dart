import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String practice;
  late String quiz;
  late String delivery;
  late String navigation;

  setUpAll(() {
    practice = File(
      'lib/services/practice/practice_mode_service.dart',
    ).readAsStringSync();
    quiz = File('lib/services/quiz_service.dart').readAsStringSync();
    delivery = File(
      'lib/services/questions/learner_question_package_delivery_service.dart',
    ).readAsStringSync();
    navigation = File(
      'lib/screens/navigation/bottom_navigation.dart',
    ).readAsStringSync();
  });

  test('FR9E practice modes never invoke the global quiz initializer', () {
    expect(practice, isNot(contains('.initialize()')));
    expect(practice, isNot(contains('.refresh()')));
    expect(practice, contains('loadCatalogMetadata'));
    expect(practice, contains('prepareCompetencies'));
  });

  test('FR9E Daily and Random stop at bounded metadata capacity', () {
    expect(practice, contains('_selectUntilQuestionCapacity'));
    expect(practice, contains('dailyQuestionCount'));
    expect(practice, contains('randomQuestionCount'));
    expect(practice, contains('publishedQuestionCount'));
  });

  test('FR9E Ultra Hard discovers packages from compact metadata', () {
    expect(practice, contains('descriptor.ultraHardCount > 0'));
    expect(practice, contains('discoveryCount += descriptor.ultraHardCount'));
    expect(
      practice,
      contains('UltraHardQuestionContract.classificationTag'),
    );
  });

  test('FR9E Weak Areas uses learner progress metadata before package load', () {
    final progressIndex = practice.indexOf(
      'final progress = await _loadQuestionProgress();',
    );
    final prepareIndex = practice.indexOf(
      'await _quizService.prepareCompetencies(',
      progressIndex,
    );

    expect(progressIndex, greaterThanOrEqualTo(0));
    expect(prepareIndex, greaterThan(progressIndex));
    expect(practice, contains('record.domainNumber > 0'));
    expect(practice, contains('record.competencyId.toLowerCase()'));
  });

  test('FR9E catalog remains Firebase-authorized Edge metadata', () {
    expect(delivery, contains("'operation': 'catalog'"));
    expect(delivery, contains("'learner-question-packages'"));
    expect(delivery, contains('Authorization'));
    expect(delivery, contains('_requireAuthorizedUser()'));
    expect(delivery, isNot(contains('CloudQuestionRepository')));
  });

  test('FR9E QuizService supports bounded multi-competency preparation', () {
    expect(quiz, contains('prepareCompetencies('));
    expect(quiz, contains('_deliveryService.loadCompetency(competencyId)'));
    expect(quiz, contains('_deliveryService.loadCatalog()'));
    expect(quiz, isNot(contains('CloudQuestionRepository')));
    expect(quiz, isNot(contains('CloudContentRepository')));
  });

  test('FR9E learner shell does not restore whole-bank prewarming', () {
    expect(navigation, isNot(contains('QuizService.shared.initialize()')));
    expect(navigation, isNot(contains('_prewarmQuizCatalog')));
  });
}
