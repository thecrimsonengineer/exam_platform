import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/study_content.dart';

/// Local persistent repository for Admin Study Content drafts.
///
/// Drafts are stored as a JSON array in SharedPreferences so they survive
/// application restarts. This is intentionally a local repository; a future
/// API/database repository can replace it without changing the Studio UI.
class LocalStudyContentRepository {
  LocalStudyContentRepository();

  static const String _storageKey = 'csp11.study_content.drafts.v1';

  Future<List<StudyContent>> loadDrafts() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);

    if (raw == null || raw.trim().isEmpty) {
      return <StudyContent>[];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return <StudyContent>[];
      }

      final drafts = <StudyContent>[];

      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }

        try {
          drafts.add(StudyContent.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {
          // Ignore a malformed individual draft rather than losing all drafts.
        }
      }

      return drafts;
    } catch (_) {
      return <StudyContent>[];
    }
  }

  Future<StudyContent?> loadDraft(String contentId) async {
    final drafts = await loadDrafts();

    for (final draft in drafts) {
      if (draft.id == contentId) {
        return draft;
      }
    }

    return null;
  }

  Future<void> saveDraft(StudyContent content) async {
    final preferences = await SharedPreferences.getInstance();
    final drafts = await loadDrafts();

    final updated = <StudyContent>[];
    var replaced = false;

    for (final draft in drafts) {
      if (draft.id == content.id) {
        updated.add(content);
        replaced = true;
      } else {
        updated.add(draft);
      }
    }

    if (!replaced) {
      updated.insert(0, content);
    }

    final encoded = jsonEncode(updated.map((draft) => draft.toJson()).toList());

    final success = await preferences.setString(_storageKey, encoded);

    if (!success) {
      throw StateError('Local draft storage could not be updated.');
    }
  }

  Future<void> deleteDraft(String contentId) async {
    final preferences = await SharedPreferences.getInstance();
    final drafts = await loadDrafts();

    final updated = drafts
        .where((draft) => draft.id != contentId)
        .map((draft) => draft.toJson())
        .toList();

    final success = await preferences.setString(
      _storageKey,
      jsonEncode(updated),
    );

    if (!success) {
      throw StateError('Local draft storage could not be updated.');
    }
  }

  Future<void> clearDrafts() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }
}
