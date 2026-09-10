import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const rendererPath =
      'lib/widgets/csp/study_content/study_content_renderer.dart';

  late String source;

  setUpAll(() {
    source = File(rendererPath).readAsStringSync();
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

  test('resume target can select its parent topic', () {
    expect(source, contains('_preferredTopicIndex'));
    expect(source, contains('widget.initialSubtopicId'));
    expect(
      source,
      contains('topic.subtopics.any((subtopic) => subtopic.id == savedId)'),
    );
  });
}
