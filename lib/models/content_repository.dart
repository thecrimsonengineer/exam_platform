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

  int get subtopicCount => content.subtopics.length;

  int get topicCount => content.subtopics.fold<int>(
        0,
        (sum, subtopic) => sum + subtopic.mainContent.length,
      );

  int get blockCount => content.subtopics.fold<int>(
        0,
        (sum, subtopic) =>
            sum +
            subtopic.mainContent.fold<int>(
              0,
              (topicSum, topic) => topicSum + topic.blocks.length,
            ),
      );

  int get questionCount => content.subtopics.fold<int>(
        0,
        (sum, subtopic) =>
            sum +
            subtopic.quizzes.length +
            subtopic.mainContent.fold<int>(
              0,
              (topicSum, topic) => topicSum + topic.quizzes.length,
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