import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/source_traceability.dart';

class SourceTraceabilityService {
  const SourceTraceabilityService();

  static const _key =
      'csp11.content_intelligence.traceability.v1';

  Future<List<SourceTraceability>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return decoded.whereType<Map>().map((item) {
        return SourceTraceability.fromJson(
          Map<String, dynamic>.from(item),
        );
      }).where((item) => item.id.isNotEmpty).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(SourceTraceability record) async {
    final items = await loadAll();
    items.removeWhere((item) => item.id == record.id);
    items.add(record);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }

  Future<List<SourceTraceability>> forTarget({
    required String targetType,
    required String targetId,
  }) async {
    final items = await loadAll();
    return items
        .where(
          (item) =>
              item.targetType == targetType &&
              item.targetId == targetId,
        )
        .toList();
  }
}
