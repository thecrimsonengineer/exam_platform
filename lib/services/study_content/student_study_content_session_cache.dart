import 'dart:collection';

import '../../models/study_content.dart';

/// Small in-memory LRU cache for published StudyContent verified during the
/// current app process.
///
/// This is intentionally not an offline repository. It is process memory only,
/// capped to a handful of competencies, and is repopulated only after a
/// successful published-content load.
class StudentStudyContentSessionCache {
  StudentStudyContentSessionCache._();

  static const int maxEntries = 5;

  static final LinkedHashMap<String, StudyContent> _entries =
      LinkedHashMap<String, StudyContent>();

  static String _key({required String domainId, required String competencyId}) {
    return '${domainId.trim().toLowerCase()}::'
        '${competencyId.trim().toLowerCase()}';
  }

  static bool contains({
    required String domainId,
    required String competencyId,
  }) {
    return _entries.containsKey(
      _key(domainId: domainId, competencyId: competencyId),
    );
  }

  static StudyContent? get({
    required String domainId,
    required String competencyId,
  }) {
    final key = _key(domainId: domainId, competencyId: competencyId);

    final content = _entries.remove(key);

    if (content == null) {
      return null;
    }

    // Reinsert to mark as most recently used.
    _entries[key] = content;
    return content;
  }

  static void put(StudyContent content) {
    if (content.status.toLowerCase() != 'published') {
      return;
    }

    final key = _key(
      domainId: content.domainId,
      competencyId: content.competencyId,
    );

    _entries.remove(key);
    _entries[key] = content;

    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  static void remove({required String domainId, required String competencyId}) {
    _entries.remove(_key(domainId: domainId, competencyId: competencyId));
  }

  static void clear() {
    _entries.clear();
  }

  static int get length => _entries.length;
}
