/// Represents a single study note/topic within the CSP Study Notes module.
class Note {
  /// Unique identifier for the note.
  final String id;

  /// Domain identifier.
  /// Example: training
  final String domainId;

  /// Section identifier.
  /// Example: fundamentals
  final String sectionId;

  /// Note title.
  final String title;

  /// Learning objectives displayed at the beginning of the note.
  final List<String> learningObjectives;

  /// Main content of the study note.
  ///
  /// Each item represents one paragraph.
  /// The UI automatically adds spacing between paragraphs.
  final List<String> mainContent;

  /// Important points for quick revision.
  final List<String> keyPoints;

  /// Practical workplace examples.
  final List<String> examples;

  /// CSP examination tips.
  final List<String> examTips;

  /// Common mistakes candidates should avoid.
  final List<String> commonMistakes;

  /// Reference sources used for the note.
  final List<String> references;

  /// Summary points at the end of the note.
  final List<String> keyTakeaways;

  /// IDs of quiz questions related to this study note.
  ///
  /// Used by the "Practice Questions" button.
  final List<String> relatedQuestionIds;

  /// Estimated reading time in minutes.
  final int estimatedReadTime;

  /// Search keywords for this study note.
  ///
  /// Improves search results without affecting the displayed content.
  final List<String> keywords;

  const Note({
    required this.id,
    required this.domainId,
    required this.sectionId,
    required this.title,
    required this.learningObjectives,
    required this.mainContent,
    required this.keyPoints,
    required this.examples,
    required this.examTips,
    required this.commonMistakes,
    required this.references,
    required this.keyTakeaways,
    required this.relatedQuestionIds,
    required this.estimatedReadTime,
    required this.keywords,
  });
}
