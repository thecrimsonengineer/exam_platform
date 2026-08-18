import 'study_content.dart';

/// Immutable context for question authoring inside Study Content Studio.
///
/// The selected Studio content and subtopic are the authoritative source for
/// question placement. This keeps domain, competency, subtopic, content
/// package/version, and quiz identity together so individual authoring paths
/// do not rebuild these identifiers independently.
class StudioQuestionContext {
  final int domain;
  final String competencyId;
  final String subtopicId;
  final String topicId;
  final String contentPackageId;
  final int contentVersion;
  final String quizId;

  const StudioQuestionContext({
    required this.domain,
    required this.competencyId,
    required this.subtopicId,
    required this.topicId,
    required this.contentPackageId,
    required this.contentVersion,
    required this.quizId,
  });

  /// Builds the question context from the currently selected Studio location.
  ///
  /// If the subtopic already has a linked quiz, that ID is preserved for
  /// compatibility with existing managed questions. Otherwise the canonical
  /// local quiz ID is generated deterministically.
  factory StudioQuestionContext.fromContent({
    required StudyContent content,
    required StudySubtopic subtopic,
    String topicId = '',
  }) {
    final linkedQuizId = subtopic.quizzes
        .map((quiz) => quiz.quizId.trim())
        .firstWhere((quizId) => quizId.isNotEmpty, orElse: () => '');

    return StudioQuestionContext(
      domain: _domainNumber(content.domainId),
      competencyId: content.competencyId,
      subtopicId: subtopic.id,
      topicId: topicId,
      contentPackageId: content.id,
      contentVersion: content.version,
      quizId: linkedQuizId.isNotEmpty
          ? linkedQuizId
          : canonicalQuizId(content.id, subtopic.id),
    );
  }

  /// Returns the canonical local quiz ID for a content package/subtopic pair.
  ///
  /// This is intentionally deterministic. It must be used instead of
  /// generating quiz IDs in separate screens or dialogs.
  static String canonicalQuizId(String contentPackageId, String subtopicId) {
    final contentId = contentPackageId.trim();
    final subtopic = subtopicId.trim();

    if (contentId.isEmpty || subtopic.isEmpty) {
      return '';
    }

    return '${contentId}_${subtopic}_quiz';
  }

  static int _domainNumber(String domainId) {
    final normalized = domainId.trim();
    final direct = int.tryParse(normalized);

    if (direct != null) {
      return direct;
    }

    final match = RegExp(r'(?:domain_|d)?(\d{1,2})').firstMatch(normalized);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }
}
