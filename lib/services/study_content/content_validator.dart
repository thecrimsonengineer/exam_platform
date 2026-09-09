import '../../models/study_content.dart';
import 'content_import_service.dart';

/// Deterministic validation performed after JSON has been successfully parsed.
///
/// Importing answers:
/// "Can this JSON become StudyContent?"
///
/// Validation answers:
/// "Is this StudyContent structurally ready for preview
/// and eventual publishing?"
class ContentValidator {
  const ContentValidator();

  List<ContentImportIssue> validate(StudyContent content) {
    final issues = <ContentImportIssue>[];

    _validateRoot(content, issues);
    _validateTopics(content, issues);

    return List.unmodifiable(issues);
  }

  void _validateRoot(StudyContent content, List<ContentImportIssue> issues) {
    _required(content.id, 'Content ID is required.', 'id', issues);

    _required(content.domainId, 'Domain ID is required.', 'domainId', issues);

    _required(
      content.competencyId,
      'Competency ID is required.',
      'competencyId',
      issues,
    );

    _required(content.title, 'Competency title is required.', 'title', issues);

    if (content.competencyNumber <= 0) {
      issues.add(
        const ContentImportIssue(
          severity: ContentImportIssueSeverity.error,
          message: 'Competency number must be greater than zero.',
          path: 'competencyNumber',
        ),
      );
    }

    if (content.version <= 0) {
      issues.add(
        const ContentImportIssue(
          severity: ContentImportIssueSeverity.error,
          message: 'Content version must be greater than zero.',
          path: 'version',
        ),
      );
    }

    if (content.topics.isEmpty) {
      issues.add(
        const ContentImportIssue(
          severity: ContentImportIssueSeverity.error,
          message: 'At least one topic is required.',
          path: 'topics',
        ),
      );
    }
  }

  void _validateTopics(StudyContent content, List<ContentImportIssue> issues) {
    final topicIds = <String>{};

    // Subtopic IDs remain unique within the content package.
    // Several learner-progress services identify subtopics by ID.
    final subtopicIds = <String>{};

    for (var topicIndex = 0; topicIndex < content.topics.length; topicIndex++) {
      final topic = content.topics[topicIndex];
      final topicPath = 'topics[$topicIndex]';

      _required(topic.id, 'Topic ID is required.', '$topicPath.id', issues);

      if (topic.id.isNotEmpty && !topicIds.add(topic.id)) {
        issues.add(
          ContentImportIssue(
            severity: ContentImportIssueSeverity.error,
            message: 'Duplicate topic ID: ${topic.id}',
            path: '$topicPath.id',
          ),
        );
      }

      _required(
        topic.title,
        'Topic title is required.',
        '$topicPath.title',
        issues,
      );

      if (topic.subtopics.isEmpty) {
        issues.add(
          ContentImportIssue(
            severity: ContentImportIssueSeverity.warning,
            message: 'Topic contains no subtopics.',
            path: '$topicPath.subtopics',
          ),
        );
      }

      _validateSubtopics(topic, topicPath, subtopicIds, issues);
    }
  }

  void _validateSubtopics(
    StudyTopic topic,
    String topicPath,
    Set<String> subtopicIds,
    List<ContentImportIssue> issues,
  ) {
    for (
      var subtopicIndex = 0;
      subtopicIndex < topic.subtopics.length;
      subtopicIndex++
    ) {
      final subtopic = topic.subtopics[subtopicIndex];
      final subtopicPath = '$topicPath.subtopics[$subtopicIndex]';

      _required(
        subtopic.id,
        'Subtopic ID is required.',
        '$subtopicPath.id',
        issues,
      );

      if (subtopic.id.isNotEmpty && !subtopicIds.add(subtopic.id)) {
        issues.add(
          ContentImportIssue(
            severity: ContentImportIssueSeverity.error,
            message: 'Duplicate subtopic ID: ${subtopic.id}',
            path: '$subtopicPath.id',
          ),
        );
      }

      _required(
        subtopic.title,
        'Subtopic title is required.',
        '$subtopicPath.title',
        issues,
      );

      if (subtopic.learningObjectives.isEmpty) {
        issues.add(
          ContentImportIssue(
            severity: ContentImportIssueSeverity.warning,
            message: 'No learning objectives were supplied.',
            path: '$subtopicPath.learningObjectives',
          ),
        );
      }

      if (subtopic.blocks.isEmpty) {
        issues.add(
          ContentImportIssue(
            severity: ContentImportIssueSeverity.warning,
            message: 'Subtopic contains no content blocks.',
            path: '$subtopicPath.blocks',
          ),
        );
      }

      _validateBlocks(subtopic.blocks, '$subtopicPath.blocks', issues);

      _validateQuizzes(subtopic, subtopicPath, issues);
    }
  }

  void _validateBlocks(
    List<ContentBlock> blocks,
    String path,
    List<ContentImportIssue> issues,
  ) {
    final blockIds = <String>{};

    const supportedTypes = <String>{
      'text',
      'heading',
      'image',
      'table',
      'formula',
      'example',
      'caseStudy',
      'reference',
      'warning',
      'examTip',
      'remember',
      'checklist',
      'quote',
    };

    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      final blockPath = '$path[$i]';

      _required(
        block.id,
        'Content block ID is required.',
        '$blockPath.id',
        issues,
      );

      if (block.id.isNotEmpty && !blockIds.add(block.id)) {
        issues.add(
          ContentImportIssue(
            severity: ContentImportIssueSeverity.error,
            message: 'Duplicate content block ID: ${block.id}',
            path: '$blockPath.id',
          ),
        );
      }

      _required(
        block.type,
        'Content block type is required.',
        '$blockPath.type',
        issues,
      );

      if (block.type.isNotEmpty && !supportedTypes.contains(block.type)) {
        issues.add(
          ContentImportIssue(
            severity: ContentImportIssueSeverity.warning,
            message: 'Unknown block type "${block.type}".',
            path: '$blockPath.type',
          ),
        );
      }

      if (block.data.isEmpty) {
        issues.add(
          ContentImportIssue(
            severity: ContentImportIssueSeverity.warning,
            message: 'Content block contains no data.',
            path: '$blockPath.data',
          ),
        );
      }

      if (block.type == 'image') {
        final imageValue = block.data['image'];
        final imagePath = imageValue?.toString().trim() ?? '';

        if (imagePath.isEmpty) {
          issues.add(
            ContentImportIssue(
              severity: ContentImportIssueSeverity.warning,
              message: 'Image block has no image path.',
              path: '$blockPath.data.image',
            ),
          );
        }
      }
    }
  }

  void _validateQuizzes(
    StudySubtopic subtopic,
    String subtopicPath,
    List<ContentImportIssue> issues,
  ) {
    final quizIds = <String>{};

    for (var i = 0; i < subtopic.quizzes.length; i++) {
      final quiz = subtopic.quizzes[i];
      final path = '$subtopicPath.quizzes[$i]';

      // QuizReference contains quizId, not id.
      // Actual question records remain owned by the question system.
      _required(quiz.quizId, 'Quiz ID is required.', '$path.quizId', issues);

      if (quiz.quizId.isNotEmpty && !quizIds.add(quiz.quizId)) {
        issues.add(
          ContentImportIssue(
            severity: ContentImportIssueSeverity.error,
            message: 'Duplicate quiz reference ID: ${quiz.quizId}',
            path: '$path.quizId',
          ),
        );
      }
    }
  }

  void _required(
    String value,
    String message,
    String path,
    List<ContentImportIssue> issues,
  ) {
    if (value.trim().isEmpty) {
      issues.add(
        ContentImportIssue(
          severity: ContentImportIssueSeverity.error,
          message: message,
          path: path,
        ),
      );
    }
  }
}
