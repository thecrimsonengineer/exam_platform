import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'learner quiz builder no longer loads the admin package repository',
    () async {
      final builder = await File(
        'lib/widgets/csp/student_quiz_builder.dart',
      ).readAsString();

      expect(builder, contains('QuizService.shared'));
      expect(builder, contains('getPublishedContent()'));
      expect(builder, isNot(contains('ContentRepositoryService')));
      expect(builder, isNot(contains('loadPackages()')));
    },
  );

  test(
    'QuizService exposes one shared in-flight published catalogue',
    () async {
      final service = await File(
        'lib/services/quiz_service.dart',
      ).readAsString();

      expect(
        service,
        contains('static final QuizService shared = QuizService();'),
      );
      expect(service, contains('Future<void>? _initializationFuture'));
      expect(service, contains('getPublishedContent()'));
      expect(service, contains('final independentFuture ='));
      expect(service, contains('final publishedContentFuture ='));
      expect(service, contains('initialize({bool forceRefresh = false})'));
    },
  );

  test(
    'learner shell prewarms practice and keeps Settings reachable',
    () async {
      final nav = await File(
        'lib/screens/navigation/bottom_navigation.dart',
      ).readAsString();

      expect(nav, contains("label: 'Practice'"));
      expect(nav, contains('const PracticeHubScreen()'));
      expect(nav, contains('QuizService.shared.initialize()'));
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
