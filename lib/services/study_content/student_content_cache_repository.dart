import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/study_content.dart';

/// Local cache for student-facing published CSP11 study content.
///
/// This cache is deliberately separate from the Admin local repository.
///
/// Firebase remains the authoritative source of content. This class only
/// stores published content that has already been obtained by the student
/// application.
///
/// The cache is not an offline-content repository and must not be used to
/// bypass the published-content boundary.
class StudentContentCacheRepository {
  StudentContentCacheRepository({required SharedPreferences preferences})
    : _preferences = preferences;

  static const String _cacheKey = 'csp11.student_content_cache.v1';

  final SharedPreferences _preferences;

  Future<List<StudyContent>> loadAll() async {
    final raw = _preferences.getString(_cacheKey);

    if (raw == null || raw.trim().isEmpty) {
      return <StudyContent>[];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return <StudyContent>[];
      }

      return decoded
          .whereType<Map>()
          .map((item) => StudyContent.fromJson(Map<String, dynamic>.from(item)))
          .where((content) => content.status.toLowerCase() == 'published')
          .toList();
    } catch (_) {
      return <StudyContent>[];
    }
  }

  Future<StudyContent?> load(String contentId) async {
    final contents = await loadAll();

    for (final content in contents) {
      if (content.id == contentId) {
        return content;
      }
    }

    return null;
  }

  Future<StudyContent?> loadLatestForCompetency(String competencyId) async {
    final contents = await loadAll();

    final matching = contents
        .where((content) => content.competencyId == competencyId)
        .toList();

    if (matching.isEmpty) {
      return null;
    }

    matching.sort((a, b) => b.version.compareTo(a.version));

    return matching.first;
  }

  Future<int?> cachedVersionForCompetency(String competencyId) async {
    final content = await loadLatestForCompetency(competencyId);

    return content?.version;
  }

  Future<void> save(StudyContent content) async {
    if (content.status.toLowerCase() != 'published') {
      throw ArgumentError(
        'Only published content can be stored in the student cache.',
      );
    }

    final contents = await loadAll();

    final sameCompetency = contents
        .where((item) => item.competencyId == content.competencyId)
        .toList();

    final latestForCompetency = sameCompetency.isEmpty
        ? null
        : sameCompetency.reduce(
            (current, candidate) =>
                candidate.version > current.version ? candidate : current,
          );

    if (latestForCompetency != null) {
      if (content.version < latestForCompetency.version) {
        return;
      }

      if (content.version == latestForCompetency.version &&
          content.id != latestForCompetency.id) {
        return;
      }
    }

    final updated = contents
        .where((item) => item.competencyId != content.competencyId)
        .toList();

    updated.add(content);

    await _write(updated);
  }

  Future<void> remove(String contentId) async {
    final contents = await loadAll();

    final updated = contents
        .where((content) => content.id != contentId)
        .toList();

    await _write(updated);
  }

  Future<void> clear() async {
    await _preferences.remove(_cacheKey);
  }

  Future<void> _write(List<StudyContent> contents) async {
    final encoded = jsonEncode(
      contents.map((content) => content.toJson()).toList(),
    );

    await _preferences.setString(_cacheKey, encoded);
  }
}
