import '../models/note.dart';
import '../models/note_domain.dart';
import '../models/note_section.dart';
import '../services/note_service.dart';

/// Controls navigation and state for the CSP Study Notes module.
///
/// This controller keeps track of:
/// - Selected domain
/// - Selected section
/// - Selected note
///
/// It contains no UI code.
class NoteController {
  final NoteService _service = const NoteService();

  NoteDomain? _selectedDomain;
  NoteSection? _selectedSection;
  Note? _selectedNote;

  // ==========================================================
  // Getters
  // ==========================================================

  List<NoteDomain> get domains => _service.getDomains();

  NoteDomain? get selectedDomain => _selectedDomain;

  NoteSection? get selectedSection => _selectedSection;

  Note? get selectedNote => _selectedNote;

  // ==========================================================
  // Domain
  // ==========================================================

  void selectDomain(String domainId) {
    _selectedDomain = _service.getDomain(domainId);

    _selectedSection = null;
    _selectedNote = null;
  }

  // ==========================================================
  // Section
  // ==========================================================

  List<NoteSection> getSections() {
    if (_selectedDomain == null) {
      return [];
    }

    return _service.getSections(_selectedDomain!.id);
  }

  void selectSection(String sectionId) {
    if (_selectedDomain == null) {
      return;
    }

    try {
      _selectedSection = getSections().firstWhere(
        (section) => section.id == sectionId,
      );
    } catch (_) {
      _selectedSection = null;
    }

    _selectedNote = null;
  }

  // ==========================================================
  // Notes
  // ==========================================================

  List<Note> getNotes() {
    if (_selectedDomain == null || _selectedSection == null) {
      return [];
    }

    return _service.getNotes(_selectedDomain!.id, _selectedSection!.id);
  }

  void selectNote(String noteId) {
    _selectedNote = _service.getNoteById(noteId);
  }

  // ==========================================================
  // Search Helpers
  // ==========================================================

  List<Note> getAllNotes() {
    return _service.getAllNotesInApp();
  }

  List<Note> getDomainNotes() {
    if (_selectedDomain == null) {
      return [];
    }

    return _service.getAllNotes(_selectedDomain!.id);
  }

  // ==========================================================
  // Reset
  // ==========================================================

  void clearSelection() {
    _selectedDomain = null;
    _selectedSection = null;
    _selectedNote = null;
  }
}
