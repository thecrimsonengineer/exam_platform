import '../models/note.dart';
import '../models/note_domain.dart';
import '../models/note_section.dart';

import '../data/notes/training/fundamentals.dart';
import '../data/notes/training/planning_design.dart';
import '../data/notes/training/delivery.dart';
import '../data/notes/training/evaluation.dart';
import '../data/notes/training/documentation.dart';

/// Central service responsible for providing all CSP Study Notes.
///
/// This service is read-only and contains no UI logic or state management.
/// It builds the domain hierarchy using the data files found under
/// lib/data/notes/.
class NoteService {
  const NoteService();

  /// Returns every available study note domain.
  List<NoteDomain> getDomains() {
    return [_trainingDomain];
  }

  /// Returns a domain by its ID.
  ///
  /// Returns null if the domain cannot be found.
  NoteDomain? getDomain(String domainId) {
    try {
      return getDomains().firstWhere((domain) => domain.id == domainId);
    } catch (_) {
      return null;
    }
  }

  /// Returns all sections belonging to a domain.
  ///
  /// Returns an empty list if the domain is not found.
  List<NoteSection> getSections(String domainId) {
    final domain = getDomain(domainId);

    if (domain == null) {
      return [];
    }

    return domain.sections;
  }

  /// Returns all notes for a given section.
  ///
  /// Returns an empty list if either the domain or section does not exist.
  List<Note> getNotes(String domainId, String sectionId) {
    final domain = getDomain(domainId);

    if (domain == null) {
      return [];
    }

    try {
      return domain.sections
          .firstWhere((section) => section.id == sectionId)
          .notes;
    } catch (_) {
      return [];
    }
  }

  /// Finds a note anywhere in the application by its unique ID.
  ///
  /// Returns null if the note cannot be found.
  Note? getNoteById(String noteId) {
    for (final domain in getDomains()) {
      for (final section in domain.sections) {
        for (final note in section.notes) {
          if (note.id == noteId) {
            return note;
          }
        }
      }
    }

    return null;
  }

  /// Returns every note within a domain.
  ///
  /// Useful for search, bookmarks, and statistics.
  List<Note> getAllNotes(String domainId) {
    final domain = getDomain(domainId);

    if (domain == null) {
      return [];
    }

    return domain.sections.expand((section) => section.notes).toList();
  }

  /// Returns every note from every domain.
  ///
  /// Useful for global search.
  List<Note> getAllNotesInApp() {
    return getDomains()
        .expand((domain) => domain.sections)
        .expand((section) => section.notes)
        .toList();
  }

  // ==========================================================
  // Training Domain
  // ==========================================================

  NoteDomain get _trainingDomain {
    return NoteDomain(
      id: 'training',
      title: 'Training',
      description:
          'Study notes covering training principles, design, delivery, evaluation, and documentation.',
      icon: 'assets/icons/training.png',
      sections: [
        NoteSection(
          id: 'fundamentals',
          domainId: 'training',
          title: 'Fundamentals',
          description: 'Core concepts and principles of workplace training.',
          notes: fundamentalsNotes,
        ),
        NoteSection(
          id: 'planning_design',
          domainId: 'training',
          title: 'Planning & Design',
          description:
              'Planning, analysis, objectives, and instructional design.',
          notes: planningDesignNotes,
        ),
        NoteSection(
          id: 'delivery',
          domainId: 'training',
          title: 'Delivery',
          description:
              'Training methods, facilitation, and learning resources.',
          notes: deliveryNotes,
        ),
        NoteSection(
          id: 'evaluation',
          domainId: 'training',
          title: 'Evaluation',
          description: 'Competency assessment and training effectiveness.',
          notes: evaluationNotes,
        ),
        NoteSection(
          id: 'documentation',
          domainId: 'training',
          title: 'Documentation',
          description: 'Training records, regulatory requirements, and review.',
          notes: documentationNotes,
        ),
      ],
    );
  }
}
