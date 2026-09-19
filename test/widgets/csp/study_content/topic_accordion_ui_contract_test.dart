import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const rendererPath =
      'lib/widgets/csp/study_content/study_content_renderer.dart';

  late String source;
  late String darkSource;
  late String spacingSource;

  setUpAll(() {
    source = File(rendererPath).readAsStringSync();
    darkSource = File(
      'lib/widgets/csp/study_content/study_content_renderer_dark.dart',
    ).readAsStringSync();
    spacingSource = File('lib/theme/study/study_spacing.dart').readAsStringSync();
  });

  test('learner index preserves Topic -> Subtopic hierarchy', () {
    expect(source, contains('TOPICS & SUBTOPICS'));
    expect(source, contains('Choose a topic'));
    expect(source, contains('_buildTopicAccordionCard'));
    expect(source, contains('topic.subtopics.asMap().entries.map'));
  });

  test('accordion is premium, animated and progress-aware', () {
    expect(source, contains('AnimatedRotation'));
    expect(source, contains('AnimatedSize'));
    expect(source, contains('LinearProgressIndicator'));
    expect(source, contains('_topicCompletionRatio'));
    expect(source, contains('_completedSubtopicCount'));
  });

  test(
    'only subtopic progress is persisted and topic completion is derived',
    () {
      expect(source, contains('_progressBySubtopicId'));
      expect(source, isNot(contains('saveTopicProgress')));
      expect(source, isNot(contains('setTopicProgress')));
    },
  );

  test('subtopic navigation keeps canonical global ordering', () {
    expect(source, contains('_globalSubtopicIndex'));
    expect(source, contains('subtopicIndex: globalIndex'));
    expect(source, contains('_orderedSubtopics'));
  });

  test('phone layout reduces Android-side whitespace in both themes', () {
    expect(spacingSource, contains('pageHorizontalForWidth'));
    expect(spacingSource, contains('heroHorizontalForWidth'));
    expect(spacingSource, contains('if (width < 600) return xs;'));
    expect(spacingSource, contains('if (width < 600) return md;'));

    expect(
      source,
      contains('StudySpacing.pageHorizontalForWidth(constraints.maxWidth)'),
    );
    expect(
      darkSource,
      contains('StudySpacing.pageHorizontalForWidth(constraints.maxWidth)'),
    );
    expect(source, contains('StudySpacing.heroHorizontalForWidth('));
    expect(darkSource, contains('StudySpacing.heroHorizontalForWidth('));
  });

  test('resume target can select its parent topic', () {
    expect(source, contains('_preferredTopicIndex'));
    expect(source, contains('widget.initialSubtopicId'));
    expect(
      source,
      contains('topic.subtopics.any((subtopic) => subtopic.id == savedId)'),
    );
  });
}
