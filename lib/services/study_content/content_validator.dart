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
    _validateSubtopics(content, issues);

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

    if (content.subtopics.isEmpty) {
      issues.add(
        const ContentImportIssue(
          severity: ContentImportIssueSeverity.error,
          message: 'At least one subtopic is required.',
          path: 'subtopics',
        ),
      );
    }
  }

  void _validateSubtopics(
    StudyContent content,
    List<ContentImportIssue> issues,
  ) {
    final subtopicIds = <String>{};

    for (var i = 0; i < content.subtopics.length; i++) {
      final subtopic = content.subtopics[i];
      final path = 'subtopics[$i]';

      _required(subtopic.id, 'Subtopic ID is required.', '$path.id', issues);

      if (subtopic.id.isNotEmpty && !subtopicIds.add(subtopic.id)) {
        issues.add(
          ContentImportIssue(
            severity: ContentImportIssueSeverity.error,
            message: 'Duplicate subtopic ID: ${subtopic.id}',
            path: '$path.id',
          ),
        );
      }

      _required(
        subtopic.title,
        'Subtopic title is required.',
        '$path.title',
        issues,
      );

      if (subtopic.learningObjectives.isEmpty) {
        issues.add(
          ContentImportIssue(
            severity: ContentImportIssueSeverity.warning,
            message: 'No learning objectives were supplied.',
            path: '$path.learningObjectives',
          ),
        );
      }

      if (subtopic.mainContent.isEmpty) {
        issues.add(
          ContentImportIssue(
            severity: ContentImportIssueSeverity.warning,
            message: 'No main content topics were supplied.',
            path: '$path.mainContent',
          ),
        );
      }

      _validateTopics(subtopic, path, issues);

      _validateEntries(subtopic, path, issues);

      _validateQuizzes(subtopic, path, issues);
    }
  }

  void _validateTopics(
    StudySubtopic subtopic,
    String subtopicPath,
    List<ContentImportIssue> issues,
  ) {
    final topicIds = <String>{};

    for (var i = 0; i < subtopic.mainContent.length; i++) {
      final topic = subtopic.mainContent[i];
      final path = '$subtopicPath.mainContent[$i]';

      _required(
        topic.id,
        'Main content topic ID is required.',
        '$path.id',
        issues,
      );

      if (topic.id.isNotEmpty && !topicIds.add(topic.id)) {
        issues.add(
          ContentImportIssue(
            severity: ContentImportIssueSeverity.error,
            message: 'Duplicate main content topic ID: ${topic.id}',
            path: '$path.id',
          ),
        );
      }

      _required(
        topic.title,
        'Main content topic title is required.',
        '$path.title',
        issues,
      );

      if (topic.blocks.isEmpty) {
        issues.add(
          ContentImportIssue(
            severity: ContentImportIssueSeverity.warning,
            message: 'Topic contains no content blocks.',
            path: '$path.blocks',
          ),
        );
      }

      _validateBlocks(topic.blocks, '$path.blocks', issues);
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

      if (block.type == 'image' && !block.hasImage) {
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

  void _validateEntries(
    StudySubtopic subtopic,
    String subtopicPath,
    List<ContentImportIssue> issues,
  ) {
    final groups = <String, List<ContentEntry>>{
      'keyPoints': subtopic.keyPoints,
      'examples': subtopic.examples,
      'caseStudies': subtopic.caseStudies,
      'formulas': subtopic.formulas,
      'references': subtopic.references,
      'examTips': subtopic.examTips,
      'commonMistakes': subtopic.commonMistakes,
      'keyTakeaways': subtopic.keyTakeaways,
    };

    for (final entryGroup in groups.entries) {
      final ids = <String>{};

      for (var i = 0; i < entryGroup.value.length; i++) {
        final entry = entryGroup.value[i];
        final path = '$subtopicPath.${entryGroup.key}[$i]';

        _required(
          entry.id,
          'Content entry ID is required.',
          '$path.id',
          issues,
        );

        if (entry.id.isNotEmpty && !ids.add(entry.id)) {
          issues.add(
            ContentImportIssue(
              severity: ContentImportIssueSeverity.error,
              message: 'Duplicate ${entryGroup.key} entry ID: ${entry.id}',
              path: '$path.id',
            ),
          );
        }

        if (entry.title.trim().isEmpty && entry.content.trim().isEmpty) {
          issues.add(
            ContentImportIssue(
              severity: ContentImportIssueSeverity.warning,
              message: 'Entry has neither a title nor text content.',
              path: path,
            ),
          );
        }

        _validateBlocks(entry.blocks, '$path.blocks', issues);
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
      // The actual quiz questions belong to the quiz system.
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
