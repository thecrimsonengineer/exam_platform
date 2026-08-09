import 'note.dart';

/// Represents a section within a CSP study note domain.
///
/// Example:
/// Training
/// └── Fundamentals
///     ├── Introduction to Training
///     ├── Strategic Role of Training
///     └── Adult Learning Principles
class NoteSection {
  /// Unique section identifier.
  /// Example: fundamentals
  final String id;

  /// Parent domain identifier.
  /// Example: training
  final String domainId;

  /// Section title displayed in the UI.
  final String title;

  /// Optional short description of the section.
  final String description;

  /// Notes belonging to this section.
  final List<Note> notes;

  const NoteSection({
    required this.id,
    required this.domainId,
    required this.title,
    required this.description,
    required this.notes,
  });

  /// Number of notes in this section.
  int get noteCount => notes.length;

  /// Returns true if the section contains no notes.
  bool get isEmpty => notes.isEmpty;
}
