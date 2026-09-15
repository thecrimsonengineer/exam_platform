import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('M4.2 guidance bridges stay deterministic and non-adaptive', () async {
    for (final path in <String>[
      'lib/features/learning_twin/integration/'
          'learning_twin_domain_guidance.dart',
      'lib/features/learning_twin/integration/'
          'learning_twin_competency_guidance.dart',
    ]) {
      final text = await File(path).readAsString();

      for (final token in <String>[
        'avatar_maker',
        'cloud_firestore',
        'firebase_',
        'SharedPreferences',
        'StudentLearningProgress',
        'student_learning_progress',
        'student_progress_dashboard',
        'Navigator.',
        'showDialog(',
        'showModalBottomSheet(',
        'DateTime.now',
        'Random(',
        'dart:math',
      ]) {
        expect(
          text,
          isNot(contains(token)),
          reason: '$token must not enter $path during M4',
        );
      }

      expect(text, contains('DeterministicLearningTwinDecisionService'));
      expect(text, contains('LearningTwinSessionState'));
      expect(text, contains('LearningTwinCard'));
    }
  });

  test(
    'domain guidance is hosted once in light and dark domain screens',
    () async {
      const integrationImport =
          'features/learning_twin/integration/learning_twin_domain_guidance.dart';

      for (final path in <String>[
        'lib/screens/courses/csp/domain_screen.dart',
        'lib/screens/courses/csp/domain_screen_dark.dart',
      ]) {
        final text = await File(path).readAsString();

        expect(text, contains(integrationImport), reason: path);
        expect(
          RegExp('LearningTwinDomainGuidance\\(').allMatches(text).length,
          1,
          reason: '$path must contain exactly one domain guidance host',
        );
      }
    },
  );

  test(
    'competency guidance is hosted once in light and dark content renderers',
    () async {
      const integrationImport =
          'features/learning_twin/integration/'
          'learning_twin_competency_guidance.dart';

      for (final path in <String>[
        'lib/widgets/csp/study_content/study_content_renderer.dart',
        'lib/widgets/csp/study_content/study_content_renderer_dark.dart',
      ]) {
        final text = await File(path).readAsString();

        expect(text, contains(integrationImport), reason: path);
        expect(
          RegExp('LearningTwinCompetencyGuidance\\(').allMatches(text).length,
          1,
          reason: '$path must contain exactly one competency guidance host',
        );
      }
    },
  );

  test(
    'M4.2 deliberately does not place Twin on every subtopic screen',
    () async {
      for (final path in <String>[
        'lib/screens/courses/csp/study_subtopic_screen.dart',
        'lib/screens/courses/csp/study_subtopic_screen_dark.dart',
      ]) {
        final text = await File(path).readAsString();

        expect(
          text,
          isNot(contains('features/learning_twin/integration/')),
          reason: '$path must remain free of automatic M4 Twin guidance',
        );
      }
    },
  );

  test('M4.1 Study Hub checkpoint remains present', () async {
    for (final path in <String>[
      'lib/screens/courses/csp/csp_study_hub_screen.dart',
      'lib/screens/courses/csp/csp_study_hub_screen_dark.dart',
    ]) {
      final text = await File(path).readAsString();

      expect(
        RegExp('LearningTwinStudyHubGuidance\\(').allMatches(text).length,
        1,
        reason: '$path must retain the approved M4.1 host',
      );
    }
  });

  test('app shell still does not own Learning Twin decisions', () async {
    for (final path in <String>[
      'lib/main.dart',
      'lib/screens/navigation/bottom_navigation.dart',
    ]) {
      final text = await File(path).readAsString();

      expect(
        text,
        isNot(contains('DeterministicLearningTwinDecisionService')),
        reason: '$path must not become a Learning Twin decision owner',
      );
      expect(
        text,
        isNot(contains('learning_twin_domain_guidance.dart')),
        reason: '$path must not directly host domain guidance',
      );
      expect(
        text,
        isNot(contains('learning_twin_competency_guidance.dart')),
        reason: '$path must not directly host competency guidance',
      );
    }
  });
}
