import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String quizService;
  late String quizScreen;
  late String bottomNavigation;
  late String delivery;

  setUpAll(() {
    quizService = File('lib/services/quiz_service.dart').readAsStringSync();
    quizScreen = File(
      'lib/screens/courses/csp/quiz/quiz_screen.dart',
    ).readAsStringSync();
    bottomNavigation = File(
      'lib/screens/navigation/bottom_navigation.dart',
    ).readAsStringSync();
    delivery = File(
      'lib/services/questions/learner_question_package_delivery_service.dart',
    ).readAsStringSync();
  });

  test('FR9D QuizService contains no global learner Firestore loaders', () {
    expect(quizService, isNot(contains('CloudQuestionRepository')));
    expect(quizService, isNot(contains('CloudContentRepository')));
    expect(quizService, isNot(contains('loadPublished()')));
    expect(quizService, contains('prepareScope'));
  });

  test('FR9D QuizScreen prepares the explicit selected scope', () {
    expect(quizScreen, contains('await quizService.prepareScope('));
    expect(quizScreen, contains('competencyId: widget.competencyId'));
    expect(quizScreen, contains('subtopicId: widget.subtopicId'));
    expect(quizScreen, contains('topicId: widget.topicId'));
    expect(quizScreen, contains('quizId: widget.quizId'));
    expect(quizScreen, isNot(contains('await quizService.initialize()')));
  });

  test('FR9D bottom navigation never prewarms the global quiz bank', () {
    expect(bottomNavigation, isNot(contains('_prewarmQuizCatalog')));
    expect(
      bottomNavigation,
      isNot(contains('QuizService.shared.initialize()')),
    );
  });

  test('FR9D delivery remains Edge-gateway and protected-cache based', () {
    expect(
      delivery,
      contains("'learner-question-packages'"),
    );
    expect(delivery, contains('UidScopedQuestionPackageCache'));
    expect(delivery, contains('LearnerOnlineAccessRuntime.requireBoundaryFor'));
    expect(delivery, contains('QuestionPackageDecoder'));
    expect(delivery, contains('Authorization'));
  });

  test('FR9D signed package download remains HTTPS-only', () {
    expect(delivery, contains("signedUrl.scheme.toLowerCase() != 'https'"));
    expect(delivery, contains('http.get(signedUrl)'));
  });
}
