import 'study_content.dart';

/// A repository-facing view of one StudyContent package/version.
///
/// StudyContent remains the source content model. This wrapper keeps
/// repository UI logic separate from the student renderer/editor model.
class ContentPackageSummary {
  final StudyContent content;
  final bool isPublishedCopy;
  final DateTime? updatedAt;

  const ContentPackageSummary({
    required this.content,
    required this.isPublishedCopy,
    this.updatedAt,
  });

  String get status => content.status.toLowerCase();

  int get topicCount => content.topics.length;

  int get subtopicCount =>
      content.topics.fold<int>(0, (sum, topic) => sum + topic.subtopics.length);

  int get blockCount => content.topics.fold<int>(
    0,
    (sum, topic) =>
        sum +
        topic.subtopics.fold<int>(
          0,
          (subtopicSum, subtopic) => subtopicSum + subtopic.blocks.length,
        ),
  );

  int get questionCount => content.topics.fold<int>(
    0,
    (sum, topic) =>
        sum +
        topic.subtopics.fold<int>(
          0,
          (subtopicSum, subtopic) =>
              subtopicSum + subtopic.questions.length + subtopic.quizzes.length,
        ),
  );

  double get completeness {
    var checks = 0;
    var passed = 0;

    void check(bool value) {
      checks++;
      if (value) passed++;
    }

    check(content.id.trim().isNotEmpty);
    check(content.domainId.trim().isNotEmpty);
    check(content.competencyId.trim().isNotEmpty);
    check(content.title.trim().isNotEmpty);
    check(content.competencyNumber > 0);
    check(content.version > 0);
    check(subtopicCount > 0);
    check(topicCount > 0);
    check(blockCount > 0);
    check(questionCount > 0);

    return checks == 0 ? 0 : passed / checks;
  }
}
