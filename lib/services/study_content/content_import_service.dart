import 'dart:convert';

import '../../models/study_content.dart';

class ContentImportResult {
  final StudyContent? content;
  final List<ContentImportIssue> issues;

  const ContentImportResult({required this.content, required this.issues});

  bool get hasErrors {
    return issues.any(
      (issue) => issue.severity == ContentImportIssueSeverity.error,
    );
  }

  bool get hasWarnings {
    return issues.any(
      (issue) => issue.severity == ContentImportIssueSeverity.warning,
    );
  }

  bool get isSuccessful {
    return content != null && !hasErrors;
  }

  int get errorCount {
    return issues
        .where((issue) => issue.severity == ContentImportIssueSeverity.error)
        .length;
  }

  int get warningCount {
    return issues
        .where((issue) => issue.severity == ContentImportIssueSeverity.warning)
        .length;
  }
}

enum ContentImportIssueSeverity { error, warning }

class ContentImportIssue {
  final ContentImportIssueSeverity severity;
  final String message;
  final String? path;

  const ContentImportIssue({
    required this.severity,
    required this.message,
    this.path,
  });
}

class ContentImportService {
  const ContentImportService();

  ContentImportResult importJson(String source) {
    final trimmed = source.trim();

    if (trimmed.isEmpty) {
      return const ContentImportResult(
        content: null,
        issues: [
          ContentImportIssue(
            severity: ContentImportIssueSeverity.error,
            message: 'The imported content is empty.',
          ),
        ],
      );
    }

    dynamic decoded;

    try {
      decoded = json.decode(trimmed);
    } on FormatException catch (error) {
      return ContentImportResult(
        content: null,
        issues: [
          ContentImportIssue(
            severity: ContentImportIssueSeverity.error,
            message: 'Invalid JSON: ${error.message}',
          ),
        ],
      );
    } catch (error) {
      return ContentImportResult(
        content: null,
        issues: [
          ContentImportIssue(
            severity: ContentImportIssueSeverity.error,
            message: 'Unable to decode JSON: $error',
          ),
        ],
      );
    }

    if (decoded is! Map) {
      return const ContentImportResult(
        content: null,
        issues: [
          ContentImportIssue(
            severity: ContentImportIssueSeverity.error,
            message: 'The JSON root must be an object.',
          ),
        ],
      );
    }

    final root = Map<String, dynamic>.from(decoded);

    StudyContent content;

    try {
      content = StudyContent.fromJson(root);
    } catch (error) {
      return ContentImportResult(
        content: null,
        issues: [
          ContentImportIssue(
            severity: ContentImportIssueSeverity.error,
            message:
                'The content could not be converted into StudyContent: $error',
          ),
        ],
      );
    }

    final issues = <ContentImportIssue>[];

    _validateRoot(content, root, issues);

    _validateSubtopics(content, issues);

    return ContentImportResult(
      content: content,
      issues: List.unmodifiable(issues),
    );
  }

  void _validateRoot(
    StudyContent content,
    Map<String, dynamic> root,
    List<ContentImportIssue> issues,
  ) {
    if (content.id.trim().isEmpty) {
      issues.add(
        const ContentImportIssue(
          severity: ContentImportIssueSeverity.error,
          message: 'Content ID is required.',
          path: 'id',
        ),
      );
    }

    if (content.domainId.trim().isEmpty) {
      issues.add(
        const ContentImportIssue(
          severity: ContentImportIssueSeverity.error,
          message: 'Domain ID is required.',
          path: 'domainId',
        ),
      );
    }

    if (content.competencyId.trim().isEmpty) {
      issues.add(
        const ContentImportIssue(
          severity: ContentImportIssueSeverity.error,
          message: 'Competency ID is required.',
          path: 'competencyId',
        ),
      );
    }

    if (content.title.trim().isEmpty) {
      issues.add(
        const ContentImportIssue(
          severity: ContentImportIssueSeverity.error,
          message: 'Competency title is required.',
          path: 'title',
        ),
      );
    }

    if (content.competencyNumber <= 0) {
      issues.add(
        const ContentImportIssue(
          severity: ContentImportIssueSeverity.warning,
          message: 'Competency number is missing or zero.',
          path: 'competencyNumber',
        ),
      );
    }

    if (content.version <= 0) {
      issues.add(
        const ContentImportIssue(
          severity: ContentImportIssueSeverity.warning,
          message: 'Content version should normally be greater than zero.',
          path: 'version',
        ),
      );
    }

    if (!root.containsKey('subtopics')) {
      issues.add(
        const ContentImportIssue(
          severity: ContentImportIssueSeverity.warning,
          message: 'No subtopics array was supplied.',
          path: 'subtopics',
        ),
      );
    }
  }

  void _validateSubtopics(
    StudyContent content,
    List<ContentImportIssue> issues,
  ) {
    if (content.subtopics.isEmpty) {
      issues.add(
        const ContentImportIssue(
          severity: ContentImportIssueSeverity.warning,
          message: 'The competency contains no subtopics.',
          path: 'subtopics',
        ),
      );

      return;
    }

    final subtopicIds = <String>{};

    for (
      var subtopicIndex = 0;
      subtopicIndex < content.subtopics.length;
      subtopicIndex++
    ) {
      final subtopic = content.subtopics[subtopicIndex];

      final subtopicPath = 'subtopics[$subtopicIndex]';

      if (subtopic.id.trim().isEmpty) {
        issues.add(
          ContentImportIssue(
            severity: ContentImportIssueSeverity.error,
            message: 'Subtopic ID is required.',
            path: '$subtopicPath.id',
          ),
        );
      } else if (!subtopicIds.add(subtopic.id)) {
        issues.add(
          ContentImportIssue(
            severity: ContentImportIssueSeverity.error,
            message: 'Duplicate subtopic ID: ${subtopic.id}',
            path: '$subtopicPath.id',
          ),
        );
      }

      if (subtopic.title.trim().isEmpty) {
        issues.add(
          ContentImportIssue(
            severity: ContentImportIssueSeverity.error,
            message: 'Subtopic title is required.',
            path: '$subtopicPath.title',
          ),
        );
      }

      _validateMainContent(subtopic, subtopicPath, issues);

      _validateQuizReferences(
        subtopic.quizzes,
        '$subtopicPath.quizzes',
        issues,
      );
    }
  }

  void _validateMainContent(
    StudySubtopic subtopic,
    String subtopicPath,
    List<ContentImportIssue> issues,
  ) {
    final topicIds = <String>{};

    for (
      var topicIndex = 0;
      topicIndex < subtopic.mainContent.length;
      topicIndex++
    ) {
      final topic = subtopic.mainContent[topicIndex];

      final topicPath = '$subtopicPath.mainContent[$topicIndex]';

      if (topic.id.trim().isEmpty) {
        issues.add(
          ContentImportIssue(
            severity: ContentImportIssueSeverity.error,
            message: 'Main content topic ID is required.',
            path: '$topicPath.id',
          ),
        );
      } else if (!topicIds.add(topic.id)) {
        issues.add(
          ContentImportIssue(
            severity: ContentImportIssueSeverity.error,
            message: 'Duplicate main content topic ID: ${topic.id}',
            path: '$topicPath.id',
          ),
        );
      }

      if (topic.title.trim().isEmpty) {
        issues.add(
          ContentImportIssue(
            severity: ContentImportIssueSeverity.error,
            message: 'Main content topic title is required.',
            path: '$topicPath.title',
          ),
        );
      }

      _validateBlocks(topic.blocks, '$topicPath.blocks', issues);

      _validateQuizReferences(topic.quizzes, '$topicPath.quizzes', issues);
    }
  }

  void _validateBlocks(
    List<ContentBlock> blocks,
    String blocksPath,
    List<ContentImportIssue> issues,
  ) {
    final blockIds = <String>{};

    for (var blockIndex = 0; blockIndex < blocks.length; blockIndex++) {
      final block = blocks[blockIndex];

      final blockPath = '$blocksPath[$blockIndex]';

      if (block.id.trim().isEmpty) {
        issues.add(
          ContentImportIssue(
            severity: ContentImportIssueSeverity.error,
            message: 'Content block ID is required.',
            path: '$blockPath.id',
          ),
        );
      } else if (!blockIds.add(block.id)) {
        issues.add(
          ContentImportIssue(
            severity: ContentImportIssueSeverity.error,
            message: 'Duplicate content block ID: ${block.id}',
            path: '$blockPath.id',
          ),
        );
      }

      if (block.type.trim().isEmpty) {
        issues.add(
          ContentImportIssue(
            severity: ContentImportIssueSeverity.error,
            message: 'Content block type is required.',
            path: '$blockPath.type',
          ),
        );
      }

      if (block.type.trim().isNotEmpty && block.data.isEmpty) {
        issues.add(
          ContentImportIssue(
            severity: ContentImportIssueSeverity.warning,
            message: 'Content block has no data.',
            path: '$blockPath.data',
          ),
        );
      }
    }
  }

  void _validateQuizReferences(
    List<QuizReference> quizzes,
    String quizzesPath,
    List<ContentImportIssue> issues,
  ) {
    for (var index = 0; index < quizzes.length; index++) {
      final quiz = quizzes[index];

      if (quiz.quizId.trim().isEmpty) {
        issues.add(
          ContentImportIssue(
            severity: ContentImportIssueSeverity.error,
            message: 'Quiz ID is required.',
            path: '$quizzesPath[$index].quizId',
          ),
        );
      }
    }
  }
}
