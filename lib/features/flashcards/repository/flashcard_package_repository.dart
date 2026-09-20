import 'package:shared_preferences/shared_preferences.dart';

import '../io/flashcard_package_json_codec.dart';
import '../models/flashcard_content_package.dart';

abstract class FlashcardPackageRepository {
  Future<List<String>> listPackageIds();

  Future<FlashcardContentPackage?> loadPackage(String packageId);

  Future<void> savePackage(FlashcardContentPackage contentPackage);

  Future<void> deletePackage(String packageId);
}

class MemoryFlashcardPackageRepository implements FlashcardPackageRepository {
  MemoryFlashcardPackageRepository({
    Iterable<FlashcardContentPackage> seed = const <FlashcardContentPackage>[],
  }) {
    for (final contentPackage in seed) {
      _packages[contentPackage.packageId] = contentPackage;
    }
  }

  final Map<String, FlashcardContentPackage> _packages =
      <String, FlashcardContentPackage>{};

  @override
  Future<List<String>> listPackageIds() async {
    final ids = _packages.keys.toList()..sort();
    return List.unmodifiable(ids);
  }

  @override
  Future<FlashcardContentPackage?> loadPackage(String packageId) async {
    return _packages[packageId];
  }

  @override
  Future<void> savePackage(FlashcardContentPackage contentPackage) async {
    _packages[contentPackage.packageId] = contentPackage;
  }

  @override
  Future<void> deletePackage(String packageId) async {
    _packages.remove(packageId);
  }
}

class SharedPreferencesFlashcardPackageRepository
    implements FlashcardPackageRepository {
  SharedPreferencesFlashcardPackageRepository({
    FlashcardPackageJsonCodec codec = const FlashcardPackageJsonCodec(),
  }) : _codec = codec;

  static const String _indexKey = 'csp11.flashcards.package.index.v1';
  static const String _packagePrefix = 'csp11.flashcards.package.v1.';

  final FlashcardPackageJsonCodec _codec;

  String _packageKey(String packageId) {
    return '$_packagePrefix$packageId';
  }

  @override
  Future<List<String>> listPackageIds() async {
    final preferences = await SharedPreferences.getInstance();
    final ids = preferences.getStringList(_indexKey) ?? const <String>[];
    final normalized = ids.toSet().toList()..sort();
    return List.unmodifiable(normalized);
  }

  @override
  Future<FlashcardContentPackage?> loadPackage(String packageId) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_packageKey(packageId));
    if (raw == null) {
      return null;
    }
    return _codec.decode(raw);
  }

  @override
  Future<void> savePackage(FlashcardContentPackage contentPackage) async {
    final preferences = await SharedPreferences.getInstance();
    final key = _packageKey(contentPackage.packageId);
    final encoded = _codec.encode(contentPackage);
    final packageWritten = await preferences.setString(key, encoded);

    if (!packageWritten) {
      throw StateError(
        'Unable to persist Flashcard package ${contentPackage.packageId}.',
      );
    }

    final existing = preferences.getStringList(_indexKey) ?? <String>[];
    final next = <String>{...existing, contentPackage.packageId}.toList()
      ..sort();
    final indexWritten = await preferences.setStringList(_indexKey, next);

    if (!indexWritten) {
      await preferences.remove(key);
      throw StateError(
        'Unable to persist Flashcard package index for '
        '${contentPackage.packageId}.',
      );
    }
  }

  @override
  Future<void> deletePackage(String packageId) async {
    final preferences = await SharedPreferences.getInstance();
    final removed = await preferences.remove(_packageKey(packageId));
    final existing = preferences.getStringList(_indexKey) ?? <String>[];
    final next = existing.where((id) => id != packageId).toList()..sort();
    final indexWritten = await preferences.setStringList(_indexKey, next);

    if (!removed && existing.contains(packageId)) {
      throw StateError('Unable to delete Flashcard package $packageId.');
    }
    if (!indexWritten) {
      throw StateError(
        'Unable to update Flashcard package index after deleting $packageId.',
      );
    }
  }
}
