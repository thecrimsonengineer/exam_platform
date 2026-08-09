import 'note_section.dart';

/// Represents a CSP Study Notes domain.
///
/// Example:
/// Training
/// ├── Fundamentals
/// ├── Planning & Design
/// ├── Delivery
/// ├── Evaluation
/// └── Documentation
class NoteDomain {
  /// Unique domain identifier.
  /// Example: training
  final String id;

  /// Domain title displayed in the UI.
  /// Example: Training
  final String title;

  /// Short description displayed under the title.
  final String description;

  /// Icon name or asset path.
  ///
  /// Examples:
  /// assets/icons/training.png
  /// assets/icons/risk_management.png
  final String icon;

  /// Sections belonging to this domain.
  final List<NoteSection> sections;

  const NoteDomain({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.sections,
  });

  /// Number of sections in this domain.
  int get sectionCount => sections.length;

  /// Total number of study notes in this domain.
  int get noteCount =>
      sections.fold(0, (total, section) => total + section.noteCount);

  /// Returns true if the domain contains no sections.
  bool get isEmpty => sections.isEmpty;
}
