import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../fr4_migration/fr4_migration_core.dart';

const String fccBucketId = 'csp11-published-packages';
const String fccSourceFcp1Branch = 'phase-fcp1-d01-closed';
const String fccSourceFcp1Sha = '45d00a95dc6d8cb9e7c06db6df57bb71c5e17fe2';
const String fccSourceFcp2Branch = 'phase-fcp2-d02-closed';
const String fccSourceFcp2Sha = '8719defd9759d65e491170aa8331462869dcfe4f';
const int fccExpectedPackageCount = 21;
const int fccExpectedCardCount = 252;
const int fccExpectedD01CardCount = 78;
const int fccExpectedD02CardCount = 174;

const Map<String, int> fccExpectedCompetencyCardCounts = <String, int>{
  'd01_c01': 8,
  'd01_c02': 11,
  'd01_c03': 14,
  'd01_c04': 9,
  'd01_c05': 9,
  'd01_c06': 14,
  'd01_c07': 13,
  'd02_c01': 8,
  'd02_c02': 5,
  'd02_c03': 10,
  'd02_c04': 12,
  'd02_c05': 12,
  'd02_c06': 12,
  'd02_c07': 12,
  'd02_c08': 12,
  'd02_c09': 13,
  'd02_c10': 15,
  'd02_c11': 15,
  'd02_c12': 14,
  'd02_c13': 16,
  'd02_c14': 18,
};

class FccFrozenFlashcardSource {
  const FccFrozenFlashcardSource({required this.path, required this.payload});

  final String path;
  final Map<String, dynamic> payload;
}

class FccFlashcardArtifact {
  const FccFlashcardArtifact({
    required this.domainId,
    required this.competencyId,
    required this.deckId,
    required this.cardCount,
    required this.canonicalJson,
    required this.compressedBytes,
    required this.checksumSha256,
    required this.uncompressedChecksumSha256,
  });

  final String domainId;
  final String competencyId;
  final String deckId;
  final int cardCount;
  final String canonicalJson;
  final Uint8List compressedBytes;
  final String checksumSha256;
  final String uncompressedChecksumSha256;

  int get compressedByteCount => compressedBytes.length;
}

class FccExistingFlashcardPackage {
  const FccExistingFlashcardPackage({
    required this.packageKey,
    required this.version,
    required this.storageBucket,
    required this.storagePath,
    required this.checksumSha256,
    required this.compressedBytes,
    required this.itemCount,
    required this.isCurrent,
  });

  final String packageKey;
  final int version;
  final String storageBucket;
  final String storagePath;
  final String checksumSha256;
  final int? compressedBytes;
  final int? itemCount;
  final bool isCurrent;

  factory FccExistingFlashcardPackage.fromRow(Map<String, dynamic> row) {
    if (_requiredString(row, 'package_kind') != 'flashcards') {
      throw StateError('FCC package history contains a non-flashcard row.');
    }

    return FccExistingFlashcardPackage(
      packageKey: _requiredString(row, 'package_key'),
      version: _requiredPositiveInt(row, 'version'),
      storageBucket: _requiredString(row, 'storage_bucket'),
      storagePath: _requiredString(row, 'storage_path'),
      checksumSha256: _requiredChecksum(row, 'checksum_sha256'),
      compressedBytes: _optionalNonNegativeInt(row['compressed_bytes']),
      itemCount: _optionalNonNegativeInt(row['item_count']),
      isCurrent: row['is_current'] == true,
    );
  }
}

class FccPlannedFlashcardPackage {
  const FccPlannedFlashcardPackage({
    required this.artifact,
    required this.version,
    required this.storagePath,
    required this.reusesExistingPackage,
  });

  final FccFlashcardArtifact artifact;
  final int version;
  final String storagePath;
  final bool reusesExistingPackage;

  String get competencyId => artifact.competencyId;

  Map<String, dynamic> toEvidenceJson() => <String, dynamic>{
    'domainId': artifact.domainId,
    'competencyId': competencyId,
    'deckId': artifact.deckId,
    'version': version,
    'cardCount': artifact.cardCount,
    'storageBucket': fccBucketId,
    'storagePath': storagePath,
    'checksumSha256': artifact.checksumSha256,
    'uncompressedChecksumSha256': artifact.uncompressedChecksumSha256,
    'compressedBytes': artifact.compressedByteCount,
    'reusesExistingPackage': reusesExistingPackage,
  };
}

class FccFlashcardPublicationPlan {
  const FccFlashcardPublicationPlan({required this.packages});

  final List<FccPlannedFlashcardPackage> packages;

  int get packageCount => packages.length;

  int get cardCount =>
      packages.fold<int>(0, (sum, package) => sum + package.artifact.cardCount);

  int get newPackageCount =>
      packages.where((package) => !package.reusesExistingPackage).length;

  int get reusedPackageCount =>
      packages.where((package) => package.reusesExistingPackage).length;

  int get totalCompressedBytes => packages.fold<int>(
    0,
    (sum, package) => sum + package.artifact.compressedByteCount,
  );

  Map<String, dynamic> toEvidenceJson() => <String, dynamic>{
    'schemaVersion': 1,
    'phase': 'FCC-1',
    'source': <String, dynamic>{
      'fcp1': <String, String>{
        'branch': fccSourceFcp1Branch,
        'sha': fccSourceFcp1Sha,
      },
      'fcp2': <String, String>{
        'branch': fccSourceFcp2Branch,
        'sha': fccSourceFcp2Sha,
      },
    },
    'readyToPublish': true,
    'packageCount': packageCount,
    'cardCount': cardCount,
    'newPackageCount': newPackageCount,
    'reusedPackageCount': reusedPackageCount,
    'totalCompressedBytes': totalCompressedBytes,
    'packages': packages
        .map((package) => package.toEvidenceJson())
        .toList(growable: false),
  };
}

class FccFlashcardPackageBuilder {
  const FccFlashcardPackageBuilder();

  FccFlashcardPublicationPlan build({
    required Iterable<FccFrozenFlashcardSource> sources,
    Iterable<Map<String, dynamic>> existingPackageRows =
        const <Map<String, dynamic>>[],
  }) {
    final artifacts = <String, FccFlashcardArtifact>{};

    for (final source in sources) {
      final artifact = _artifactFromSource(source);
      if (artifacts.containsKey(artifact.competencyId)) {
        throw StateError(
          'FCC frozen source contains duplicate competency '
          '${artifact.competencyId}.',
        );
      }
      artifacts[artifact.competencyId] = artifact;
    }

    final expectedIds = fccExpectedCompetencyCardCounts.keys.toSet();
    final actualIds = artifacts.keys.toSet();
    if (actualIds.length != fccExpectedPackageCount ||
        actualIds.difference(expectedIds).isNotEmpty ||
        expectedIds.difference(actualIds).isNotEmpty) {
      throw StateError(
        'FCC frozen FCP1/FCP2 package inventory mismatch. '
        'expected=${expectedIds.length} actual=${actualIds.length}.',
      );
    }

    final history = <String, List<FccExistingFlashcardPackage>>{};
    for (final raw in existingPackageRows) {
      if (raw['package_kind']?.toString() != 'flashcards') {
        continue;
      }
      final item = FccExistingFlashcardPackage.fromRow(
        Map<String, dynamic>.from(raw),
      );
      history
          .putIfAbsent(item.packageKey, () => <FccExistingFlashcardPackage>[])
          .add(item);
    }
    for (final entries in history.values) {
      _validateHistory(entries);
    }

    final ids = artifacts.keys.toList()..sort();
    final planned = <FccPlannedFlashcardPackage>[];
    for (final competencyId in ids) {
      planned.add(
        _planPackage(
          artifacts[competencyId]!,
          history[competencyId] ?? const <FccExistingFlashcardPackage>[],
        ),
      );
    }

    final plan = FccFlashcardPublicationPlan(
      packages: List<FccPlannedFlashcardPackage>.unmodifiable(planned),
    );
    _validateFrozenTotals(plan);
    return plan;
  }

  FccFlashcardArtifact _artifactFromSource(FccFrozenFlashcardSource source) {
    final payload = Map<String, dynamic>.from(source.payload);
    if (payload['schemaVersion'] != 'csp11.flashcards.package.v1') {
      throw StateError('FCC source package has an unsupported schema.');
    }

    final deck = _requiredMap(payload, 'deck');
    final competencyId = _requiredString(deck, 'competencyId');
    final domainId = _requiredString(deck, 'domainId');
    final deckId = _requiredString(deck, 'id');
    final deckVersion = _requiredPositiveInt(deck, 'version');
    final lifecycle = _requiredString(deck, 'lifecycle');

    if (!RegExp(r'^d0[12]_c\d{2}$').hasMatch(competencyId) ||
        domainId != competencyId.substring(0, 3) ||
        deckId != '${competencyId}_flashcards_v1' ||
        deckVersion != 1 ||
        (lifecycle != 'validated' && lifecycle != 'bundled')) {
      throw StateError(
        'FCC source package identity is invalid for $competencyId.',
      );
    }

    final cards = _requiredList(payload, 'cards');
    final concepts = _requiredList(payload, 'concepts');
    final deckCardIds = _requiredList(deck, 'cardIds');
    final expectedCount = fccExpectedCompetencyCardCounts[competencyId];

    if (expectedCount == null ||
        cards.length != expectedCount ||
        concepts.length != expectedCount ||
        deckCardIds.length != expectedCount) {
      throw StateError(
        'FCC card count mismatch for $competencyId. '
        'expected=$expectedCount cards=${cards.length}.',
      );
    }

    final cardIds = <String>{};
    for (final rawCard in cards) {
      if (rawCard is! Map) {
        throw StateError('FCC card payload must be an object.');
      }
      final card = Map<String, dynamic>.from(rawCard);
      final cardId = _requiredString(card, 'id');
      if (!cardIds.add(cardId)) {
        throw StateError('FCC duplicate card ID $cardId.');
      }

      final placement = _requiredMap(card, 'primaryPlacement');
      if (_requiredString(placement, 'domainId') != domainId ||
          _requiredString(placement, 'competencyId') != competencyId) {
        throw StateError(
          'FCC card placement mismatch in $competencyId: $cardId.',
        );
      }

      final refs = _requiredList(card, 'sourceRefs');
      final primaryCount = refs.where((ref) {
        return ref is Map && ref['primary'] == true;
      }).length;
      if (primaryCount != 1) {
        throw StateError(
          'FCC card $cardId must preserve exactly one primary source.',
        );
      }
    }

    final declaredIds = deckCardIds.map((item) => item.toString()).toSet();
    if (declaredIds.length != expectedCount ||
        declaredIds.difference(cardIds).isNotEmpty ||
        cardIds.difference(declaredIds).isNotEmpty) {
      throw StateError('FCC deck card IDs do not match $competencyId cards.');
    }

    final canonicalJson = fr4CanonicalJson(payload);
    final uncompressed = utf8.encode(canonicalJson);
    final compressed = Uint8List.fromList(gzip.encode(uncompressed));

    return FccFlashcardArtifact(
      domainId: domainId,
      competencyId: competencyId,
      deckId: deckId,
      cardCount: cards.length,
      canonicalJson: canonicalJson,
      compressedBytes: compressed,
      checksumSha256: sha256.convert(compressed).toString(),
      uncompressedChecksumSha256: sha256.convert(uncompressed).toString(),
    );
  }

  FccPlannedFlashcardPackage _planPackage(
    FccFlashcardArtifact artifact,
    List<FccExistingFlashcardPackage> history,
  ) {
    final matches = history
        .where((item) => item.checksumSha256 == artifact.checksumSha256)
        .toList(growable: false);

    if (matches.length > 1) {
      throw StateError(
        'FCC history has duplicate checksum registrations for '
        '${artifact.competencyId}.',
      );
    }

    if (matches.length == 1) {
      final existing = matches.single;
      final expectedPath = fccFlashcardStoragePath(
        artifact.competencyId,
        existing.version,
      );

      if (existing.storageBucket != fccBucketId ||
          existing.storagePath != expectedPath ||
          (existing.compressedBytes != null &&
              existing.compressedBytes != artifact.compressedByteCount) ||
          (existing.itemCount != null &&
              existing.itemCount != artifact.cardCount)) {
        throw StateError(
          'FCC immutable history mismatch for ${artifact.competencyId}.',
        );
      }

      return FccPlannedFlashcardPackage(
        artifact: artifact,
        version: existing.version,
        storagePath: expectedPath,
        reusesExistingPackage: true,
      );
    }

    final maxVersion = history.fold<int>(
      0,
      (current, item) => item.version > current ? item.version : current,
    );
    final version = maxVersion + 1;

    return FccPlannedFlashcardPackage(
      artifact: artifact,
      version: version,
      storagePath: fccFlashcardStoragePath(artifact.competencyId, version),
      reusesExistingPackage: false,
    );
  }

  void _validateFrozenTotals(FccFlashcardPublicationPlan plan) {
    if (plan.packageCount != fccExpectedPackageCount ||
        plan.cardCount != fccExpectedCardCount) {
      throw StateError(
        'FCC FCP1/FCP2 totals are invalid: '
        '${plan.packageCount} packages / ${plan.cardCount} cards.',
      );
    }

    final d01 = plan.packages
        .where((item) => item.artifact.domainId == 'd01')
        .fold<int>(0, (sum, item) => sum + item.artifact.cardCount);
    final d02 = plan.packages
        .where((item) => item.artifact.domainId == 'd02')
        .fold<int>(0, (sum, item) => sum + item.artifact.cardCount);

    if (d01 != fccExpectedD01CardCount || d02 != fccExpectedD02CardCount) {
      throw StateError('FCC domain totals are invalid: d01=$d01 d02=$d02.');
    }
  }
}

List<FccFrozenFlashcardSource> loadFccFrozenFcp12Sources({
  String rootPath = 'assets/flashcards/production',
}) {
  final root = Directory(rootPath);
  if (!root.existsSync()) {
    throw StateError('FCC frozen source root does not exist: $rootPath');
  }

  final matcher = RegExp(
    r'[\\/]d0[12][\\/]d0[12]_c\d{2}[\\/]d0[12]_c\d{2}_flashcards_v1\.json$',
  );
  final files =
      root
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => matcher.hasMatch(file.path))
          .toList()
        ..sort((left, right) => left.path.compareTo(right.path));

  final sources = <FccFrozenFlashcardSource>[];
  for (final file in files) {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map) {
      throw StateError('FCC source package is not an object: ${file.path}');
    }
    sources.add(
      FccFrozenFlashcardSource(
        path: file.path,
        payload: Map<String, dynamic>.from(decoded),
      ),
    );
  }

  return List<FccFrozenFlashcardSource>.unmodifiable(sources);
}

String fccFlashcardStoragePath(String competencyId, int version) {
  if (!RegExp(r'^d0[12]_c\d{2}$').hasMatch(competencyId)) {
    throw StateError('FCC competency ID is invalid: $competencyId');
  }
  if (version <= 0) {
    throw StateError('FCC package version must be positive.');
  }
  return 'flashcards/$competencyId/v$version.json.gz';
}

void _validateHistory(List<FccExistingFlashcardPackage> entries) {
  final versions = <int>{};
  var currentCount = 0;
  for (final item in entries) {
    if (!versions.add(item.version)) {
      throw StateError(
        'FCC history contains duplicate version ${item.version} '
        'for ${item.packageKey}.',
      );
    }
    if (item.isCurrent) currentCount++;
  }
  if (currentCount > 1) {
    throw StateError(
      'FCC history contains multiple current rows for '
      '${entries.first.packageKey}.',
    );
  }
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> source, String key) {
  final value = source[key];
  if (value is! Map) {
    throw StateError('FCC required object field "$key" is missing.');
  }
  return Map<String, dynamic>.from(value);
}

List<dynamic> _requiredList(Map<String, dynamic> source, String key) {
  final value = source[key];
  if (value is! List) {
    throw StateError('FCC required list field "$key" is missing.');
  }
  return value;
}

String _requiredString(Map<String, dynamic> source, String key) {
  final value = source[key]?.toString().trim() ?? '';
  if (value.isEmpty) {
    throw StateError('FCC required field "$key" is empty.');
  }
  return value;
}

String _requiredChecksum(Map<String, dynamic> source, String key) {
  final value = _requiredString(source, key);
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
    throw StateError('FCC field "$key" is not a lowercase SHA-256.');
  }
  return value;
}

int _requiredPositiveInt(Map<String, dynamic> source, String key) {
  final value = source[key];
  final parsed = value is int
      ? value
      : value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '');
  if (parsed == null || parsed <= 0) {
    throw StateError('FCC integer field "$key" must be positive.');
  }
  return parsed;
}

int? _optionalNonNegativeInt(dynamic value) {
  if (value == null) return null;
  final parsed = value is int
      ? value
      : value is num
      ? value.toInt()
      : int.tryParse(value.toString());
  if (parsed == null || parsed < 0) {
    throw StateError('FCC optional integer must be non-negative.');
  }
  return parsed;
}
