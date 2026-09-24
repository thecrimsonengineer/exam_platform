import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'learner quiz builder uses FR9 metadata and bounded preparation only',
    () async {
      final builder = await File(
        'lib/widgets/csp/student_quiz_builder.dart',
      ).readAsString();

      expect(builder, contains('QuizService.shared'));
      expect(builder, contains('loadCatalogMetadata()'));
      expect(builder, contains('prepareCompetencies('));
      expect(builder, contains('_maxRuntimeScopePackages = 4'));
      expect(builder, isNot(contains('getPublishedContent()')));
      expect(builder, isNot(contains('ContentRepositoryService')));
      expect(builder, isNot(contains('loadPackages()')));
    },
  );

  test('QuizService exposes shared bounded FR9 question preparation', () async {
    final service = await File('lib/services/quiz_service.dart').readAsString();

    expect(service, contains('static QuizService? _shared;'));
    expect(
      service,
      contains('static QuizService get shared => _shared ??= QuizService();'),
    );
    expect(service, contains('prepareScope'));
    expect(service, contains('prepareCompetencies'));
    expect(service, contains('loadCatalogMetadata'));
    expect(service, contains('getPublishedContent()'));
    expect(service, isNot(contains('CloudQuestionRepository')));
    expect(service, isNot(contains('CloudContentRepository')));
  });

  test(
    'learner shell keeps Practice and Settings without whole-bank prewarm',
    () async {
      final nav = await File(
        'lib/screens/navigation/bottom_navigation.dart',
      ).readAsString();

      expect(nav, contains("label: 'Practice'"));
      expect(nav, contains('const PracticeHubScreen()'));
      expect(nav, isNot(contains('QuizService.shared.initialize()')));
      expect(nav, isNot(contains('_prewarmQuizCatalog')));
      expect(nav, contains('Future<void> _openSettings()'));
      expect(nav, contains('onOpenSettings: _openSettings'));
    },
  );

  test(
    'Practice hub is theme-aware and routes to both existing wrappers',
    () async {
      final hub = await File(
        'lib/screens/practice/practice_hub_screen.dart',
      ).readAsString();

      expect(hub, contains('Theme.of(context)'));
      expect(hub, contains('Brightness.dark'));
      expect(hub, contains('CspPracticeScreen('));
      expect(hub, contains('DarkCspPracticeScreen('));
      expect(hub, isNot(contains('FirebaseFirestore')));
    },
  );

  test('Firestore learner rules remain published-only', () async {
    final rules = await File('firestore.rules').readAsString();

    expect(rules, contains("resource.data.status == 'published'"));
    expect(rules, contains("resource.data.copyType == 'published'"));
    expect(
      rules,
      isNot(
        contains(
          'match /questions/{questionId} {\n    allow read: if isSignedIn();',
        ),
      ),
    );
  });
}
