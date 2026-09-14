import 'package:shared_preferences/shared_preferences.dart';

import 'auth/learner_local_identity.dart';

/// Stores one learner's most recently opened CSP11 learning position.
///
/// Every key is scoped by Firebase UID, so two accounts using the same device
/// have independent Continue Learning state.
///
/// The former device-global V1 keys are intentionally ignored. They cannot be
/// assigned safely to an account because their creator UID was never stored.
class StudentLearningPosition {
  final String domainId;
  final int domainNumber;
  final String domainTitle;

  final String competencyId;
  final String competencyTitle;

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
  const StudentLearningPositionService({this.userIdOverride});

  final String? userIdOverride;

  static const String legacyPrefix = 'csp11.student.learning_position.';

  static String storagePrefixForUser(String userId) =>
      'csp11.student.$userId.learning_position.v2';

  String _requireUserId() {
    return LearnerLocalIdentity.requireCurrentUserId(
      userIdOverride: userIdOverride,
    );
  }

  String _key(String userId, String field) =>
      '${storagePrefixForUser(userId)}.$field';

  Future<void> savePosition({
    required String domainId,
    required int domainNumber,
    required String domainTitle,
    required String competencyId,
    required String competencyTitle,
    String? subtopicId,
    String? subtopicTitle,
  }) async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_key(userId, 'domain_id'), domainId);
    await prefs.setInt(_key(userId, 'domain_number'), domainNumber);
    await prefs.setString(_key(userId, 'domain_title'), domainTitle);
    await prefs.setString(_key(userId, 'competency_id'), competencyId);
    await prefs.setString(_key(userId, 'competency_title'), competencyTitle);

    if (subtopicId != null && subtopicId.trim().isNotEmpty) {
      await prefs.setString(_key(userId, 'subtopic_id'), subtopicId);
    } else {
      await prefs.remove(_key(userId, 'subtopic_id'));
    }

    if (subtopicTitle != null && subtopicTitle.trim().isNotEmpty) {
      await prefs.setString(_key(userId, 'subtopic_title'), subtopicTitle);
    } else {
      await prefs.remove(_key(userId, 'subtopic_title'));
    }

    await prefs.setString(
      _key(userId, 'last_opened_at'),
      DateTime.now().toIso8601String(),
    );
  }

  Future<StudentLearningPosition?> loadPosition() async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();

    final domainId = prefs.getString(_key(userId, 'domain_id'));
    final domainNumber = prefs.getInt(_key(userId, 'domain_number'));
    final domainTitle = prefs.getString(_key(userId, 'domain_title'));
    final competencyId = prefs.getString(_key(userId, 'competency_id'));
    final competencyTitle = prefs.getString(_key(userId, 'competency_title'));
    final timestamp = prefs.getString(_key(userId, 'last_opened_at'));

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
      subtopicId: prefs.getString(_key(userId, 'subtopic_id')),
      subtopicTitle: prefs.getString(_key(userId, 'subtopic_title')),
      lastOpenedAt: lastOpenedAt,
    );
  }

  /// Clears only the currently active learner's Continue Learning position.
  Future<void> clearPosition() async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();

    for (final field in const <String>[
      'domain_id',
      'domain_number',
      'domain_title',
      'competency_id',
      'competency_title',
      'subtopic_id',
      'subtopic_title',
      'last_opened_at',
    ]) {
      await prefs.remove(_key(userId, field));
    }
  }
}
