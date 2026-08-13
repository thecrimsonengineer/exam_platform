import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/content_source.dart';

class ContentSourceLibraryService {
  const ContentSourceLibraryService();

  static const _key = 'csp11.content_intelligence.sources.v1';

  Future<List<ContentSource>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded.whereType<Map>().map((item) {
        return ContentSource.fromJson(Map<String, dynamic>.from(item));
      }).where((item) => item.id.isNotEmpty).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(ContentSource source) async {
    final items = await loadAll();
    items.removeWhere((item) => item.id == source.id);
    items.insert(0, source);
    await _write(items);
  }

  Future<void> archive(String sourceId) async {
    final items = await loadAll();
    final index = items.indexWhere((item) => item.id == sourceId);
    if (index < 0) return;

    items[index] = items[index].copyWith(
      status: ContentSourceStatus.archived,
      updatedAt: DateTime.now(),
    );
    await _write(items);
  }

  Future<void> _write(List<ContentSource> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}
