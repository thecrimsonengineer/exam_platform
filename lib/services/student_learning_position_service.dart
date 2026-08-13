import 'package:shared_preferences/shared_preferences.dart';

/// Stores the learner's most recently opened CSP11 learning position.
///
/// This is intentionally a small local persistence layer.
/// It can later be replaced by a remote learner-progress repository
/// without changing the student-facing screens.
class StudentLearningPosition {
  final String domainId;
  final int domainNumber;
  final String domainTitle;

  final String competencyId;
  final String competencyTitle;

  /// The most recently selected subtopic ID, when available.
  final String? subtopicId;
  final String? subtopicTitle;

  final DateTime lastOpenedAt;

  const StudentLearningPosition({
    required this.domainId,
    required this.domainNumber,
    required this.domainTitle,
    required this.competencyId,
    required this.competencyTitle,
    this.subtopicId,
    this.subtopicTitle,
    required this.lastOpenedAt,
  });
}

class StudentLearningPositionService {
  const StudentLearningPositionService();

  static const String _domainIdKey =
      'csp11.student.learning_position.domain_id';

  static const String _domainNumberKey =
      'csp11.student.learning_position.domain_number';

  static const String _domainTitleKey =
      'csp11.student.learning_position.domain_title';

  static const String _competencyIdKey =
      'csp11.student.learning_position.competency_id';

  static const String _competencyTitleKey =
      'csp11.student.learning_position.competency_title';

  static const String _subtopicIdKey =
      'csp11.student.learning_position.subtopic_id';

  static const String _subtopicTitleKey =
      'csp11.student.learning_position.subtopic_title';

  static const String _lastOpenedAtKey =
      'csp11.student.learning_position.last_opened_at';

  Future<void> savePosition({
    required String domainId,
    required int domainNumber,
    required String domainTitle,
    required String competencyId,
    required String competencyTitle,
    String? subtopicId,
    String? subtopicTitle,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_domainIdKey, domainId);
    await prefs.setInt(_domainNumberKey, domainNumber);
    await prefs.setString(_domainTitleKey, domainTitle);

    await prefs.setString(_competencyIdKey, competencyId);

    await prefs.setString(_competencyTitleKey, competencyTitle);

    if (subtopicId != null && subtopicId.trim().isNotEmpty) {
      await prefs.setString(_subtopicIdKey, subtopicId);
    } else {
      await prefs.remove(_subtopicIdKey);
    }

    if (subtopicTitle != null && subtopicTitle.trim().isNotEmpty) {
      await prefs.setString(_subtopicTitleKey, subtopicTitle);
    } else {
      await prefs.remove(_subtopicTitleKey);
    }

    await prefs.setString(_lastOpenedAtKey, DateTime.now().toIso8601String());
  }

  Future<StudentLearningPosition?> loadPosition() async {
    final prefs = await SharedPreferences.getInstance();

    final domainId = prefs.getString(_domainIdKey);

    final domainNumber = prefs.getInt(_domainNumberKey);

    final domainTitle = prefs.getString(_domainTitleKey);

    final competencyId = prefs.getString(_competencyIdKey);

    final competencyTitle = prefs.getString(_competencyTitleKey);

    final timestamp = prefs.getString(_lastOpenedAtKey);

    if (domainId == null ||
        domainNumber == null ||
        domainTitle == null ||
        competencyId == null ||
        competencyTitle == null ||
        timestamp == null) {
      return null;
    }

    final lastOpenedAt = DateTime.tryParse(timestamp);

    if (lastOpenedAt == null) {
      return null;
    }

    return StudentLearningPosition(
      domainId: domainId,
      domainNumber: domainNumber,
      domainTitle: domainTitle,
      competencyId: competencyId,
      competencyTitle: competencyTitle,
      subtopicId: prefs.getString(_subtopicIdKey),
      subtopicTitle: prefs.getString(_subtopicTitleKey),
      lastOpenedAt: lastOpenedAt,
    );
  }

  Future<void> clearPosition() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_domainIdKey);
    await prefs.remove(_domainNumberKey);
    await prefs.remove(_domainTitleKey);
    await prefs.remove(_competencyIdKey);
    await prefs.remove(_competencyTitleKey);
    await prefs.remove(_subtopicIdKey);
    await prefs.remove(_subtopicTitleKey);
    await prefs.remove(_lastOpenedAtKey);
  }
}
