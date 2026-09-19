import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';

const fr4SupportedCollections = <String>{
  'contentVersions',
  'questions',
};

class Fr4SourceDocument {
  const Fr4SourceDocument({
    required this.collection,
    required this.id,
    required this.data,
  });

  final String collection;
  final String id;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'collection': collection,
    'id': id,
    'data': data,
  };
}

class Fr4Issue {
  const Fr4Issue({
    required this.kind,
    required this.collection,
    required this.sourceId,
    required this.message,
  });

  final String kind;
  final String collection;
  final String sourceId;
  final String message;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'kind': kind,
    'collection': collection,
    'sourceId': sourceId,
    'message': message,
  };
}

class Fr4TargetRow {
  const Fr4TargetRow({
    required this.sourceCollection,
    required this.sourceId,
    required this.targetTable,
    required this.targetKey,
    required this.sourceChecksumSha256,
    required this.targetChecksumSha256,
    required this.row,
  });

  final String sourceCollection;
  final String sourceId;
  final String targetTable;
  final String targetKey;
  final String sourceChecksumSha256;
  final String targetChecksumSha256;
  final Map<String, dynamic> row;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'sourceCollection': sourceCollection,
    'sourceId': sourceId,
    'targetTable': targetTable,
    'targetKey': targetKey,
    'sourceChecksumSha256': sourceChecksumSha256,
    'targetChecksumSha256': targetChecksumSha256,
    'row': row,
  };

  Map<String, dynamic> pendingLedgerRow() => <String, dynamic>{
    'source_system': 'firestore',
    'source_collection': sourceCollection,
    'source_id': sourceId,
    'target_table': targetTable,
    'target_key': targetKey,
    'source_checksum_sha256': sourceChecksumSha256,
    'target_checksum_sha256': targetChecksumSha256,
    'validation_status': 'pending',
    'failure_reason': null,
    'metadata': <String, dynamic>{
      'phase': 'FR4',
      'toolingSchemaVersion': 1,
    },
  };
}

class Fr4MigrationPlan {
  const Fr4MigrationPlan({
    required this.rows,
    required this.issues,
    required this.sourceCounts,
    required this.targetCounts,
  });

  final List<Fr4TargetRow> rows;
  final List<Fr4Issue> issues;
  final Map<String, int> sourceCounts;
  final Map<String, int> targetCounts;

  bool get readyToApply => issues.isEmpty;

  int get duplicateCount =>
      issues.where((issue) => issue.kind == 'duplicate_target_key').length;

  int get failureCount =>
      issues.where((issue) => issue.kind == 'normalization_failure').length;

  int get unmappedCount =>
      issues.where((issue) => issue.kind == 'unmapped_collection').length;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schemaVersion': 1,
    'phase': 'FR4',
    'readyToApply': readyToApply,
    'sourceCounts': SplayTreeMap<String, int>.from(sourceCounts),
    'targetCounts': SplayTreeMap<String, int>.from(targetCounts),
    'rowCount': rows.length,
    'issueCount': issues.length,
    'duplicateCount': duplicateCount,
    'failureCount': failureCount,
    'unmappedCount': unmappedCount,
    'rows': rows.map((row) => row.toJson()).toList(growable: false),
    'issues': issues.map((issue) => issue.toJson()).toList(growable: false),
  };
}

class Fr4MigrationEngine {
  const Fr4MigrationEngine();

  Fr4MigrationPlan build(Iterable<Fr4SourceDocument> documents) {
    final sorted = documents.toList(growable: false)
      ..sort((left, right) {
        final collectionOrder = left.collection.compareTo(right.collection);
        if (collectionOrder != 0) return collectionOrder;
        return left.id.compareTo(right.id);
      });

    final rows = <Fr4TargetRow>[];
    final issues = <Fr4Issue>[];
    final sourceCounts = <String, int>{};
    final targetCounts = <String, int>{};
    final targetOwners = <String, String>{};

    for (final document in sorted) {
      sourceCounts.update(
        document.collection,
        (count) => count + 1,
        ifAbsent: () => 1,
      );

      if (!fr4SupportedCollections.contains(document.collection)) {
        issues.add(
          Fr4Issue(
            kind: 'unmapped_collection',
            collection: document.collection,
            sourceId: document.id,
            message:
                'No frozen FR4 normalizer exists for this source collection.',
          ),
        );
        continue;
      }

      try {
        final row = switch (document.collection) {
          'contentVersions' => _normalizeContent(document),
          'questions' => _normalizeQuestion(document),
          _ => throw StateError('Unsupported collection.'),
        };

        final ownershipKey = '${row.targetTable}|${row.targetKey}';
        final priorOwner = targetOwners[ownershipKey];

        if (priorOwner != null) {
          issues.add(
            Fr4Issue(
              kind: 'duplicate_target_key',
              collection: document.collection,
              sourceId: document.id,
              message:
                  'Target key ${row.targetKey} in ${row.targetTable} '
                  'is already produced by $priorOwner.',
            ),
          );
          continue;
        }

        targetOwners[ownershipKey] =
            '${document.collection}/${document.id}';
        rows.add(row);
        targetCounts.update(
          row.targetTable,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      } catch (error) {
        issues.add(
          Fr4Issue(
            kind: 'normalization_failure',
            collection: document.collection,
            sourceId: document.id,
            message: error.toString(),
          ),
        );
      }
    }

    return Fr4MigrationPlan(
      rows: List<Fr4TargetRow>.unmodifiable(rows),
      issues: List<Fr4Issue>.unmodifiable(issues),
      sourceCounts: Map<String, int>.unmodifiable(sourceCounts),
      targetCounts: Map<String, int>.unmodifiable(targetCounts),
    );
  }

  Fr4TargetRow _normalizeContent(Fr4SourceDocument document) {
    final decoded = decodeCsp11FirestoreSafe(document.data);
    final source = _withoutServerMetadata(_asStringMap(decoded));

    final contentId = _requiredString(source, 'id');
    final domainId = _requiredString(source, 'domainId');
    final competencyId = _requiredString(source, 'competencyId');
    final competencyNumber = _requiredPositiveInt(source, 'competencyNumber');
    final title = _requiredString(source, 'title');
    final version = _requiredPositiveInt(source, 'version');
    final status = _requiredLifecycle(source, 'status');

    final payload = <String, dynamic>{
      'id': contentId,
      'domainId': domainId,
      'competencyId': competencyId,
      'competencyNumber': competencyNumber,
      'title': title,
      'status': status,
      'version': version,
      'topics': source['topics'] is List ? source['topics'] : const <dynamic>[],
    };

    final sourceChecksum = fr4Sha256(payload);

    final row = <String, dynamic>{
      'content_id': contentId,
      'version': version,
      'domain_id': domainId,
      'competency_id': competencyId,
      'competency_number': competencyNumber,
      'title': title,
      'status': status,
      'source_document_id': document.id,
      'content_payload': payload,
      'source_checksum_sha256': sourceChecksum,
      if (_optionalTimestamp(source['publishedAt']) case final publishedAt?)
        'published_at': publishedAt,
    };

    return _targetRow(
      document: document,
      targetTable: 'content_versions',
      targetKey: '$contentId|v$version',
      sourcePayload: payload,
      row: row,
    );
  }

  Fr4TargetRow _normalizeQuestion(Fr4SourceDocument document) {
    final decoded = decodeCsp11FirestoreSafe(document.data);
    final source = _withoutServerMetadata(_asStringMap(decoded));

    final questionId = _requiredPositiveInt(source, 'id');
    final version = _requiredPositiveInt(source, 'version', fallback: 1);
    final domainNumber = _requiredPositiveInt(source, 'domain');
    final competencyId = _requiredString(source, 'competencyId');
    final stem = _requiredString(source, 'question');
    final status = _requiredLifecycle(source, 'status');

    final options = _requiredStringList(source, 'options');
    final correctAnswer = _requiredInt(source, 'correctAnswer');
    if (status == 'published') {
      if (options.length != 4) {
        throw StateError(
          'Published question $questionId must have exactly four options.',
        );
      }
      if (correctAnswer < 0 || correctAnswer > 3) {
        throw StateError(
          'Published question $questionId has an invalid correctAnswer.',
        );
      }
    }

    final canonicalSource = <String, dynamic>{
      'id': questionId,
      'domain': domainNumber,
      'competencyId': competencyId,
      'subtopicId': _optionalString(source['subtopicId']),
      'topicId': _optionalString(source['topicId']),
      'quizId': _optionalString(source['quizId']),
      'contentPackageId': _optionalString(source['contentPackageId']),
      'question': stem,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': _optionalString(source['explanation']),
      'bestAnswerRationale': _optionalString(source['bestAnswerRationale']),
      'reference': _optionalString(source['reference']),
      'difficulty': _optionalString(source['difficulty']),
      'cognitiveLevel': _optionalString(source['cognitiveLevel']),
      'questionType': _optionalString(source['questionType']),
      'status': status,
      'version': version,
      'tags': _stringList(source['tags']),
    };

    final sourceChecksum = fr4Sha256(canonicalSource);
    final qualityPayload =
        _firstStringMap(source, const <String>[
          'qualityGatePayload',
          'qualityGate',
          'dqg300',
          'dqg',
        ]) ??
        const <String, dynamic>{};

    final row = <String, dynamic>{
      'question_id': questionId,
      'version': version,
      'domain_number': domainNumber,
      'competency_id': competencyId,
      'subtopic_id': canonicalSource['subtopicId'],
      'topic_id': canonicalSource['topicId'],
      'quiz_id': canonicalSource['quizId'],
      'content_package_id': canonicalSource['contentPackageId'],
      'stem': stem,
      'options': options,
      'correct_answer': correctAnswer,
      'explanation': canonicalSource['explanation'],
      'best_answer_rationale': canonicalSource['bestAnswerRationale'],
      'reference_text': canonicalSource['reference'],
      'difficulty': canonicalSource['difficulty'],
      'cognitive_level': canonicalSource['cognitiveLevel'],
      'question_type': canonicalSource['questionType'],
      'status': status,
      'tags': canonicalSource['tags'],
      'quality_gate_payload': qualityPayload,
      'source_document_id': document.id,
      'source_payload': canonicalSource,
      if (_optionalTimestamp(source['publishedAt']) case final publishedAt?)
        'published_at': publishedAt,
    };

    return _targetRow(
      document: document,
      targetTable: 'questions',
      targetKey: '$questionId|v$version',
      sourcePayload: canonicalSource,
      row: row,
    );
  }

  Fr4TargetRow _targetRow({
    required Fr4SourceDocument document,
    required String targetTable,
    required String targetKey,
    required Map<String, dynamic> sourcePayload,
    required Map<String, dynamic> row,
  }) {
    return Fr4TargetRow(
      sourceCollection: document.collection,
      sourceId: document.id,
      targetTable: targetTable,
      targetKey: targetKey,
      sourceChecksumSha256: fr4Sha256(sourcePayload),
      targetChecksumSha256: fr4Sha256(row),
      row: Map<String, dynamic>.unmodifiable(row),
    );
  }
}

String fr4CanonicalJson(dynamic value) => jsonEncode(_canonicalize(value));

String fr4Sha256(dynamic value) =>
    sha256.convert(utf8.encode(fr4CanonicalJson(value))).toString();

dynamic decodeCsp11FirestoreSafe(dynamic value) {
  if (value is Map) {
    final normalized = _asStringMap(value);
    if (normalized['csp11FirestoreNestedListV1'] == true &&
        normalized['items'] is Map) {
      final items = _asStringMap(normalized['items']);
      final ordered = items.entries.toList(growable: false)
        ..sort((left, right) {
          final leftIndex = int.tryParse(left.key) ?? 0;
          final rightIndex = int.tryParse(right.key) ?? 0;
          return leftIndex.compareTo(rightIndex);
        });
      return ordered
          .map((entry) => decodeCsp11FirestoreSafe(entry.value))
          .toList(growable: false);
    }

    return <String, dynamic>{
      for (final entry in normalized.entries)
        entry.key: decodeCsp11FirestoreSafe(entry.value),
    };
  }

  if (value is List) {
    return value
        .map(decodeCsp11FirestoreSafe)
        .toList(growable: false);
  }

  return value;
}

dynamic decodeFirestoreRestValue(dynamic raw) {
  if (raw is! Map) {
    throw const FormatException('Firestore REST value must be an object.');
  }

  final value = _asStringMap(raw);

  if (value.containsKey('nullValue')) return null;
  if (value.containsKey('booleanValue')) return value['booleanValue'];

  if (value.containsKey('integerValue')) {
    final integer = int.tryParse(value['integerValue'].toString());
    if (integer == null) {
      throw const FormatException('Invalid Firestore integerValue.');
    }
    return integer;
  }

  if (value.containsKey('doubleValue')) {
    final rawDouble = value['doubleValue'];
    if (rawDouble is num) return rawDouble.toDouble();
    final parsed = double.tryParse(rawDouble.toString());
    if (parsed == null) {
      throw const FormatException('Invalid Firestore doubleValue.');
    }
    return parsed;
  }

  if (value.containsKey('timestampValue')) {
    return DateTime.parse(value['timestampValue'].toString())
        .toUtc()
        .toIso8601String();
  }

  if (value.containsKey('stringValue')) {
    return value['stringValue']?.toString() ?? '';
  }

  if (value.containsKey('bytesValue')) {
    return <String, dynamic>{
      r'$firestoreBytesBase64': value['bytesValue']?.toString() ?? '',
    };
  }

  if (value.containsKey('referenceValue')) {
    return <String, dynamic>{
      r'$firestoreReference': value['referenceValue']?.toString() ?? '',
    };
  }

  if (value.containsKey('geoPointValue')) {
    final point = _asStringMap(value['geoPointValue']);
    return <String, dynamic>{
      r'$firestoreGeoPoint': <String, dynamic>{
        'latitude': point['latitude'],
        'longitude': point['longitude'],
      },
    };
  }

  if (value.containsKey('arrayValue')) {
    final arrayValue = _asStringMap(value['arrayValue']);
    final values = arrayValue['values'];
    if (values == null) return const <dynamic>[];
    if (values is! List) {
      throw const FormatException('Invalid Firestore arrayValue.');
    }
    return values.map(decodeFirestoreRestValue).toList(growable: false);
  }

  if (value.containsKey('mapValue')) {
    final mapValue = _asStringMap(value['mapValue']);
    final fields = mapValue['fields'];
    if (fields == null) return <String, dynamic>{};
    if (fields is! Map) {
      throw const FormatException('Invalid Firestore mapValue.');
    }
    return decodeFirestoreRestFields(fields);
  }

  throw const FormatException('Unsupported Firestore REST value type.');
}

Map<String, dynamic> decodeFirestoreRestFields(dynamic rawFields) {
  final fields = _asStringMap(rawFields);
  return <String, dynamic>{
    for (final entry in fields.entries)
      entry.key: decodeFirestoreRestValue(entry.value),
  };
}

Fr4SourceDocument decodeFirestoreRestDocument({
  required String collection,
  required dynamic document,
}) {
  if (document is! Map) {
    throw const FormatException('Firestore document must be an object.');
  }
  final map = _asStringMap(document);
  final name = _requiredString(map, 'name');
  final segments = name.split('/');
  final id = segments.isEmpty ? '' : segments.last;
  if (id.isEmpty) {
    throw const FormatException('Firestore document name has no ID.');
  }

  final fields = map['fields'];
  return Fr4SourceDocument(
    collection: collection,
    id: id,
    data: fields is Map
        ? decodeFirestoreRestFields(fields)
        : const <String, dynamic>{},
  );
}

Map<String, dynamic> fr4TargetProjection(
  Fr4TargetRow planned,
  Map<String, dynamic> returnedRow,
) {
  final projected = <String, dynamic>{};
  for (final key in planned.row.keys) {
    if (!returnedRow.containsKey(key)) {
      throw StateError(
        'Target row ${planned.targetKey} is missing required column $key.',
      );
    }
    projected[key] = returnedRow[key];
  }
  return projected;
}

bool fr4TargetMatches(
  Fr4TargetRow planned,
  Map<String, dynamic> returnedRow,
) {
  return fr4Sha256(fr4TargetProjection(planned, returnedRow)) ==
      planned.targetChecksumSha256;
}

dynamic _canonicalize(dynamic value) {
  if (value is Map) {
    final sorted = SplayTreeMap<String, dynamic>();
    for (final entry in value.entries) {
      sorted[entry.key.toString()] = _canonicalize(entry.value);
    }
    return sorted;
  }

  if (value is List) {
    return value.map(_canonicalize).toList(growable: false);
  }

  if (value is DateTime) {
    return value.toUtc().toIso8601String();
  }

  return value;
}

Map<String, dynamic> _withoutServerMetadata(Map<String, dynamic> source) {
  final copy = Map<String, dynamic>.from(source);
  for (final key in const <String>[
    'updatedAt',
    'createdAt',
    'serverUpdatedAt',
  ]) {
    copy.remove(key);
  }
  return copy;
}

Map<String, dynamic> _asStringMap(dynamic value) {
  if (value is! Map) {
    throw const FormatException('Expected an object.');
  }
  return <String, dynamic>{
    for (final entry in value.entries) entry.key.toString(): entry.value,
  };
}

String _requiredString(Map<String, dynamic> source, String key) {
  final value = source[key]?.toString().trim() ?? '';
  if (value.isEmpty) {
    throw StateError('Required field "$key" is empty.');
  }
  return value;
}

String _optionalString(dynamic value) => value?.toString() ?? '';

int _requiredInt(
  Map<String, dynamic> source,
  String key, {
  int? fallback,
}) {
  final value = source[key];
  if (value == null && fallback != null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null) {
    throw StateError('Required integer field "$key" is invalid.');
  }
  return parsed;
}

int _requiredPositiveInt(
  Map<String, dynamic> source,
  String key, {
  int? fallback,
}) {
  final value = _requiredInt(source, key, fallback: fallback);
  if (value <= 0) {
    throw StateError('Required field "$key" must be greater than zero.');
  }
  return value;
}

String _requiredLifecycle(Map<String, dynamic> source, String key) {
  final value = _requiredString(source, key).toLowerCase();
  const allowed = <String>{
    'draft',
    'review',
    'validated',
    'published',
    'archived',
  };
  if (!allowed.contains(value)) {
    throw StateError('Unsupported lifecycle status "$value".');
  }
  return value;
}

List<String> _requiredStringList(
  Map<String, dynamic> source,
  String key,
) {
  final values = _stringList(source[key]);
  if (values.isEmpty) {
    throw StateError('Required list field "$key" is empty.');
  }
  return values;
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const <String>[];
  return value
      .map((item) => item?.toString() ?? '')
      .where((item) => item.trim().isNotEmpty)
      .toList(growable: false);
}

Map<String, dynamic>? _firstStringMap(
  Map<String, dynamic> source,
  Iterable<String> keys,
) {
  for (final key in keys) {
    final value = source[key];
    if (value is Map) return _asStringMap(value);
  }
  return null;
}

String? _optionalTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc().toIso8601String();

  final text = value.toString().trim();
  if (text.isEmpty) return null;

  try {
    return DateTime.parse(text).toUtc().toIso8601String();
  } catch (_) {
    throw StateError('Invalid timestamp "$text".');
  }
}
