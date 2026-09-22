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
    expect(practice, contains('_deliveryService.loadCatalog()'));
    expect(practice, contains('_loadUntilQuestionCount'));
  });

  test('FR9E Daily and Random stop after enough verified questions load', () {
    expect(practice, contains('_loadUntilQuestionCount'));
    expect(practice, contains('dailyQuestionCount'));
    expect(practice, contains('randomQuestionCount'));
    expect(practice, contains('if (merged.length >= requestedCount)'));
  });

  test('FR9E Ultra Hard discovers packages from compact metadata', () {
    expect(practice, contains('descriptor.ultraHardCount > 0'));
    expect(practice, contains('advertisedUltraHard'));
    expect(practice, contains('descriptor.ultraHardCount'));
    expect(practice, contains('UltraHardQuestionContract.classificationTag'));
  });

  test(
    'FR9E Weak Areas uses learner progress metadata before package load',
    () {
      final weakStart = practice.indexOf(
        'Future<PracticeSessionPlan> _buildWeakAreas(',
      );
      final weakEnd = practice.indexOf(
        'Future<PracticeSessionPlan> _buildWeakFallback(',
        weakStart,
      );
      final weakBlock = practice.substring(weakStart, weakEnd);
      final progressIndex = weakBlock.indexOf(
        'final progress = await _loadQuestionProgress();',
      );
      final packageIndex = weakBlock.indexOf(
        'final published = await _loadUntilQuestionCount(',
      );

      expect(progressIndex, greaterThanOrEqualTo(0));
      expect(packageIndex, greaterThan(progressIndex));
      expect(weakBlock, contains('record.domainNumber > 0'));
      expect(weakBlock, contains('record.competencyId.trim()'));
    },
  );

  test('FR9E catalog remains Firebase-authorized Edge metadata', () {
    expect(delivery, contains("'operation': 'catalog'"));
    expect(delivery, contains("'learner-question-packages'"));
    expect(delivery, contains('Authorization'));
    expect(delivery, contains('_requireAuthorizedUser()'));
    expect(delivery, isNot(contains('CloudQuestionRepository')));
  });

  test('FR9E keeps learner QuizService free from Firestore global loaders', () {
    expect(quiz, contains('prepareCompetencies('));
    expect(quiz, contains('_deliveryService.loadCompetency(competencyId)'));
    expect(quiz, isNot(contains('CloudQuestionRepository')));
    expect(quiz, isNot(contains('CloudContentRepository')));
    expect(quiz, isNot(contains('loadPublished()')));
  });

  test('FR9E learner shell does not restore whole-bank prewarming', () {
    expect(navigation, isNot(contains('QuizService.shared.initialize()')));
    expect(navigation, isNot(contains('_prewarmQuizCatalog')));
  });
}
