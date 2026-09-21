import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../fr4_migration/fr4_migration_core.dart';

const fr7BucketId = 'csp11-published-packages';
const fr7SupportedKinds = <String>{'content', 'questions'};

class Fr7PackageArtifact {
  const Fr7PackageArtifact({
    required this.kind,
    required this.competencyId,
    required this.canonicalJson,
    required this.compressedBytes,
    required this.checksumSha256,
    required this.uncompressedChecksumSha256,
    required this.itemCount,
    required this.sourceMetadata,
  });

  final String kind;
  final String competencyId;
  final String canonicalJson;
  final Uint8List compressedBytes;
  final String checksumSha256;
  final String uncompressedChecksumSha256;
  final int itemCount;
  final Map<String, dynamic> sourceMetadata;

  int get compressedByteCount => compressedBytes.length;

  Map<String, dynamic> toEvidenceJson() => <String, dynamic>{
    'kind': kind,
    'competencyId': competencyId,
    'checksumSha256': checksumSha256,
    'uncompressedChecksumSha256': uncompressedChecksumSha256,
    'compressedBytes': compressedByteCount,
    'itemCount': itemCount,
    'sourceMetadata': sourceMetadata,
  };
}

class Fr7ExistingPackage {
  const Fr7ExistingPackage({
    required this.kind,
    required this.packageKey,
    required this.version,
    required this.storageBucket,
    required this.storagePath,
    required this.checksumSha256,
    required this.compressedBytes,
    required this.itemCount,
    required this.isCurrent,
  });

  final String kind;
  final String packageKey;
  final int version;
  final String storageBucket;
  final String storagePath;
  final String checksumSha256;
  final int? compressedBytes;
  final int? itemCount;
  final bool isCurrent;

  factory Fr7ExistingPackage.fromRow(Map<String, dynamic> row) {
    final kind = _requiredString(row, 'package_kind');
    if (!fr7SupportedKinds.contains(kind)) {
      throw StateError('Unsupported FR7 package kind "$kind".');
    }

    return Fr7ExistingPackage(
      kind: kind,
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

class Fr7PlannedPackage {
  const Fr7PlannedPackage({
    required this.artifact,
    required this.version,
    required this.storagePath,
    required this.reusesExistingPackage,
  });

  final Fr7PackageArtifact artifact;
  final int version;
  final String storagePath;
  final bool reusesExistingPackage;

  String get kind => artifact.kind;
  String get competencyId => artifact.competencyId;

  Map<String, dynamic> toEvidenceJson() => <String, dynamic>{
    ...artifact.toEvidenceJson(),
    'version': version,
    'storageBucket': fr7BucketId,
    'storagePath': storagePath,
    'reusesExistingPackage': reusesExistingPackage,
  };
}

class Fr7PlannedCompetency {
  const Fr7PlannedCompetency({
    required this.competencyId,
    required this.content,
    required this.questions,
  });

  final String competencyId;
  final Fr7PlannedPackage content;
  final Fr7PlannedPackage questions;

  Map<String, dynamic> toEvidenceJson() => <String, dynamic>{
    'competencyId': competencyId,
    'content': content.toEvidenceJson(),
    'questions': questions.toEvidenceJson(),
  };
}

class Fr7PublicationPlan {
  const Fr7PublicationPlan({required this.competencies});

  final List<Fr7PlannedCompetency> competencies;

  List<Fr7PlannedPackage> get packages => <Fr7PlannedPackage>[
    for (final competency in competencies) competency.content,
    for (final competency in competencies) competency.questions,
  ]..sort((left, right) {
      final key = left.competencyId.compareTo(right.competencyId);
      if (key != 0) return key;
      return left.kind.compareTo(right.kind);
    });

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
    'phase': 'FR7',
    'readyToPublish': true,
    'competencyCount': competencies.length,
    'packageCount': packages.length,
    'newPackageCount': newPackageCount,
    'reusedPackageCount': reusedPackageCount,
    'totalCompressedBytes': totalCompressedBytes,
    'competencies': competencies
        .map((competency) => competency.toEvidenceJson())
        .toList(growable: false),
  };
}

class Fr7PackageBuilder {
  const Fr7PackageBuilder();

  Fr7PublicationPlan build({
    required Iterable<Map<String, dynamic>> contentRows,
    required Iterable<Map<String, dynamic>> questionRows,
    Iterable<Map<String, dynamic>> existingPackageRows = const [],
  }) {
    final contentByCompetency = <String, List<Map<String, dynamic>>>{};
    for (final source in contentRows) {
      final row = Map<String, dynamic>.from(source);
      _requirePublished(row, 'content');
      final competencyId = _requiredString(row, 'competency_id');
      contentByCompetency
          .putIfAbsent(competencyId, () => <Map<String, dynamic>>[])
          .add(row);
    }

    final questionByCompetency = <String, List<Map<String, dynamic>>>{};
    for (final source in questionRows) {
      final row = Map<String, dynamic>.from(source);
      _requirePublished(row, 'question');
      final competencyId = _requiredString(row, 'competency_id');
      questionByCompetency
          .putIfAbsent(competencyId, () => <Map<String, dynamic>>[])
          .add(row);
    }

    final contentKeys = contentByCompetency.keys.toSet();
    final questionKeys = questionByCompetency.keys.toSet();
    if (contentKeys.difference(questionKeys).isNotEmpty ||
        questionKeys.difference(contentKeys).isNotEmpty) {
      final contentOnly = contentKeys.difference(questionKeys).toList()..sort();
      final questionsOnly = questionKeys.difference(contentKeys).toList()
        ..sort();
      throw StateError(
        'FR7 requires both published content and published questions for every '
        'competency. contentOnly=$contentOnly questionsOnly=$questionsOnly',
      );
    }
    if (contentKeys.isEmpty) {
      throw StateError('FR7 source contains no publishable competencies.');
    }

    final history = <String, List<Fr7ExistingPackage>>{};
    for (final source in existingPackageRows) {
      final rawKind = source['package_kind']?.toString() ?? '';
      if (!fr7SupportedKinds.contains(rawKind)) continue;
      final existing = Fr7ExistingPackage.fromRow(
        Map<String, dynamic>.from(source),
      );
      history
          .putIfAbsent(
            _historyKey(existing.kind, existing.packageKey),
            () => <Fr7ExistingPackage>[],
          )
          .add(existing);
    }
    for (final entries in history.values) {
      _validateHistory(entries);
    }

    final competencies = contentKeys.toList()..sort();
    final planned = <Fr7PlannedCompetency>[];

    for (final competencyId in competencies) {
      final contentRow = _latestContent(
        competencyId,
        contentByCompetency[competencyId]!,
      );
      final selectedQuestions = _latestQuestions(
        competencyId,
        questionByCompetency[competencyId]!,
      );

      final contentArtifact = _contentArtifact(competencyId, contentRow);
      final questionsArtifact = _questionsArtifact(
        competencyId,
        selectedQuestions,
      );

      planned.add(
        Fr7PlannedCompetency(
          competencyId: competencyId,
          content: _planPackage(
            contentArtifact,
            history[_historyKey('content', competencyId)] ?? const [],
          ),
          questions: _planPackage(
            questionsArtifact,
            history[_historyKey('questions', competencyId)] ?? const [],
          ),
        ),
      );
    }

    return Fr7PublicationPlan(
      competencies: List<Fr7PlannedCompetency>.unmodifiable(planned),
    );
  }

  Map<String, dynamic> _latestContent(
    String competencyId,
    List<Map<String, dynamic>> rows,
  ) {
    final sorted = rows.toList(growable: false)
      ..sort(
        (left, right) =>
            _requiredPositiveInt(right, 'version').compareTo(
              _requiredPositiveInt(left, 'version'),
            ),
      );

    final topVersion = _requiredPositiveInt(sorted.first, 'version');
    final duplicates = sorted
        .where((row) => _requiredPositiveInt(row, 'version') == topVersion)
        .length;
    if (duplicates != 1) {
      throw StateError(
        'FR7 content competency $competencyId has $duplicates rows at latest '
        'version $topVersion.',
      );
    }
    return sorted.first;
  }

  List<Map<String, dynamic>> _latestQuestions(
    String competencyId,
    List<Map<String, dynamic>> rows,
  ) {
    final byQuestion = <int, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final questionId = _requiredPositiveInt(row, 'question_id');
      byQuestion
          .putIfAbsent(questionId, () => <Map<String, dynamic>>[])
          .add(row);
    }

    final selected = <Map<String, dynamic>>[];
    final ids = byQuestion.keys.toList()..sort();
    for (final questionId in ids) {
      final versions = byQuestion[questionId]!.toList(growable: false)
        ..sort(
          (left, right) =>
              _requiredPositiveInt(right, 'version').compareTo(
                _requiredPositiveInt(left, 'version'),
              ),
        );
      final topVersion = _requiredPositiveInt(versions.first, 'version');
      final duplicates = versions
          .where((row) => _requiredPositiveInt(row, 'version') == topVersion)
          .length;
      if (duplicates != 1) {
        throw StateError(
          'FR7 question $questionId in $competencyId has $duplicates rows at '
          'latest version $topVersion.',
        );
      }
      selected.add(versions.first);
    }
    return selected;
  }

  Fr7PackageArtifact _contentArtifact(
    String competencyId,
    Map<String, dynamic> row,
  ) {
    final payload = _requiredMap(row, 'content_payload');
    final sourceVersion = _requiredPositiveInt(row, 'version');
    return _artifact(
      kind: 'content',
      competencyId: competencyId,
      itemCount: 1,
      envelope: <String, dynamic>{
        'schemaVersion': 1,
        'kind': 'content',
        'competencyId': competencyId,
        'sourceVersion': sourceVersion,
        'content': payload,
      },
      sourceMetadata: <String, dynamic>{'sourceVersion': sourceVersion},
    );
  }

  Fr7PackageArtifact _questionsArtifact(
    String competencyId,
    List<Map<String, dynamic>> rows,
  ) {
    final payloads = <Map<String, dynamic>>[];
    var maxSourceVersion = 1;

    for (final row in rows) {
      final sourceVersion = _requiredPositiveInt(row, 'version');
      if (sourceVersion > maxSourceVersion) maxSourceVersion = sourceVersion;
      final payload = _requiredMap(row, 'source_payload');
      final payloadCompetency = _requiredString(payload, 'competencyId');
      if (payloadCompetency != competencyId) {
        throw StateError(
          'FR7 question payload competency "$payloadCompetency" does not match '
          '"$competencyId".',
        );
      }
      final rowQuestionId = _requiredPositiveInt(row, 'question_id');
      final payloadQuestionId = _requiredPositiveInt(payload, 'id');
      if (rowQuestionId != payloadQuestionId) {
        throw StateError(
          'FR7 question row/payload ID mismatch: $rowQuestionId vs '
          '$payloadQuestionId.',
        );
      }
      payloads.add(payload);
    }

    payloads.sort(
      (left, right) =>
          _requiredPositiveInt(left, 'id').compareTo(
            _requiredPositiveInt(right, 'id'),
          ),
    );

    return _artifact(
      kind: 'questions',
      competencyId: competencyId,
      itemCount: payloads.length,
      envelope: <String, dynamic>{
        'schemaVersion': 1,
        'kind': 'questions',
        'competencyId': competencyId,
        'sourceRecordMaxVersion': maxSourceVersion,
        'questionCount': payloads.length,
        'questions': payloads,
      },
      sourceMetadata: <String, dynamic>{
        'sourceRecordMaxVersion': maxSourceVersion,
        'questionCount': payloads.length,
      },
    );
  }

  Fr7PackageArtifact _artifact({
    required String kind,
    required String competencyId,
    required int itemCount,
    required Map<String, dynamic> envelope,
    required Map<String, dynamic> sourceMetadata,
  }) {
    final canonicalJson = fr4CanonicalJson(envelope);
    final uncompressed = utf8.encode(canonicalJson);
    final compressed = Uint8List.fromList(gzip.encode(uncompressed));

    return Fr7PackageArtifact(
      kind: kind,
      competencyId: competencyId,
      canonicalJson: canonicalJson,
      compressedBytes: compressed,
      checksumSha256: sha256.convert(compressed).toString(),
      uncompressedChecksumSha256: sha256.convert(uncompressed).toString(),
      itemCount: itemCount,
      sourceMetadata: Map<String, dynamic>.unmodifiable(sourceMetadata),
    );
  }

  Fr7PlannedPackage _planPackage(
    Fr7PackageArtifact artifact,
    List<Fr7ExistingPackage> history,
  ) {
    final matches = history
        .where((existing) => existing.checksumSha256 == artifact.checksumSha256)
        .toList(growable: false);

    if (matches.length > 1) {
      throw StateError(
        'FR7 history contains duplicate checksum registrations for '
        '${artifact.kind}/${artifact.competencyId}.',
      );
    }

    if (matches.length == 1) {
      final existing = matches.single;
      final expectedPath = fr7StoragePath(
        artifact.kind,
        artifact.competencyId,
        existing.version,
      );
      if (existing.storageBucket != fr7BucketId ||
          existing.storagePath != expectedPath) {
        throw StateError(
          'FR7 immutable package registration path mismatch for '
          '${artifact.kind}/${artifact.competencyId} v${existing.version}.',
        );
      }
      if (existing.compressedBytes != null &&
          existing.compressedBytes != artifact.compressedByteCount) {
        throw StateError(
          'FR7 immutable package size mismatch for '
          '${artifact.kind}/${artifact.competencyId}.',
        );
      }
      if (existing.itemCount != null &&
          existing.itemCount != artifact.itemCount) {
        throw StateError(
          'FR7 immutable package item-count mismatch for '
          '${artifact.kind}/${artifact.competencyId}.',
        );
      }

      return Fr7PlannedPackage(
        artifact: artifact,
        version: existing.version,
        storagePath: expectedPath,
        reusesExistingPackage: true,
      );
    }

    final maxVersion = history.fold<int>(
      0,
      (value, existing) =>
          existing.version > value ? existing.version : value,
    );
    final nextVersion = maxVersion + 1;

    return Fr7PlannedPackage(
      artifact: artifact,
      version: nextVersion,
      storagePath: fr7StoragePath(
        artifact.kind,
        artifact.competencyId,
        nextVersion,
      ),
      reusesExistingPackage: false,
    );
  }
}

String fr7StoragePath(String kind, String competencyId, int version) {
  if (!fr7SupportedKinds.contains(kind)) {
    throw StateError('Unsupported FR7 package kind "$kind".');
  }
  if (competencyId.trim().isEmpty) {
    throw StateError('FR7 competency ID cannot be empty.');
  }
  if (version <= 0) {
    throw StateError('FR7 package version must be positive.');
  }
  return '$kind/$competencyId/v$version.json.gz';
}

String _historyKey(String kind, String packageKey) => '$kind|$packageKey';

void _validateHistory(List<Fr7ExistingPackage> entries) {
  final versions = <int>{};
  var currentCount = 0;

  for (final entry in entries) {
    if (!versions.add(entry.version)) {
      throw StateError(
        'FR7 package history contains duplicate version ${entry.version} for '
        '${entry.kind}/${entry.packageKey}.',
      );
    }
    if (entry.isCurrent) currentCount++;
  }

  if (currentCount > 1) {
    throw StateError(
      'FR7 package history contains $currentCount current rows for '
      '${entries.first.kind}/${entries.first.packageKey}.',
    );
  }
}

void _requirePublished(Map<String, dynamic> row, String label) {
  if (_requiredString(row, 'status') != 'published') {
    throw StateError('FR7 $label source row is not published.');
  }
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> source, String key) {
  final value = source[key];
  if (value is! Map) {
    throw StateError('FR7 required object field "$key" is missing.');
  }
  return <String, dynamic>{
    for (final entry in value.entries) entry.key.toString(): entry.value,
  };
}

String _requiredString(Map<String, dynamic> source, String key) {
  final value = source[key]?.toString().trim() ?? '';
  if (value.isEmpty) {
    throw StateError('FR7 required field "$key" is empty.');
  }
  return value;
}

String _requiredChecksum(Map<String, dynamic> source, String key) {
  final value = _requiredString(source, key);
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
    throw StateError('FR7 field "$key" is not a SHA-256 checksum.');
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
    throw StateError('FR7 required integer field "$key" must be positive.');
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
    throw StateError('FR7 optional integer must be non-negative.');
  }
  return parsed;
}
