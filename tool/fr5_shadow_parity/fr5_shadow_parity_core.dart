import '../fr4_migration/fr4_migration_core.dart';

const fr5SupportedTargetTables = <String>{
  'content_versions',
  'questions',
};

class Fr5ExpectedRow {
  const Fr5ExpectedRow({
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

  factory Fr5ExpectedRow.fromJson(Map<String, dynamic> json) {
    final row = _stringMap(json['row']);
    final targetTable = _requiredString(json, 'targetTable');
    if (!fr5SupportedTargetTables.contains(targetTable)) {
      throw StateError('Unsupported FR5 target table "$targetTable".');
    }

    final expected = Fr5ExpectedRow(
      sourceCollection: _requiredString(json, 'sourceCollection'),
      sourceId: _requiredString(json, 'sourceId'),
      targetTable: targetTable,
      targetKey: _requiredString(json, 'targetKey'),
      sourceChecksumSha256: _requiredChecksum(json, 'sourceChecksumSha256'),
      targetChecksumSha256: _requiredChecksum(json, 'targetChecksumSha256'),
      row: Map<String, dynamic>.unmodifiable(row),
    );

    final derived = fr5TargetKey(targetTable, row);
    if (derived != expected.targetKey) {
      throw StateError(
        'FR4 evidence target key mismatch: expected '
        '${expected.targetKey}, derived $derived.',
      );
    }

    final planned = expected.toFr4TargetRow();
    if (fr4Sha256(row) != planned.targetChecksumSha256) {
      throw StateError(
        'FR4 evidence checksum mismatch for ${expected.targetKey}.',
      );
    }

    return expected;
  }

  Fr4TargetRow toFr4TargetRow() => Fr4TargetRow(
    sourceCollection: sourceCollection,
    sourceId: sourceId,
    targetTable: targetTable,
    targetKey: targetKey,
    sourceChecksumSha256: sourceChecksumSha256,
    targetChecksumSha256: targetChecksumSha256,
    row: row,
  );
}

class Fr5ExpectedPlan {
  const Fr5ExpectedPlan({
    required this.rows,
    required this.sourceCounts,
    required this.targetCounts,
  });

  final List<Fr5ExpectedRow> rows;
  final Map<String, int> sourceCounts;
  final Map<String, int> targetCounts;

  factory Fr5ExpectedPlan.fromFr4Evidence(Map<String, dynamic> json) {
    if (json['phase']?.toString() != 'FR4') {
      throw StateError('FR5 requires frozen FR4 migration evidence.');
    }
    if (json['readyToApply'] != true) {
      throw StateError('FR4 evidence is not ready to apply.');
    }

    final issueCount = _intValue(json['issueCount']);
    if (issueCount != 0) {
      throw StateError('FR4 evidence contains $issueCount issue(s).');
    }

    final rawRows = json['rows'];
    if (rawRows is! List) {
      throw StateError('FR4 evidence rows are missing.');
    }

    final rows = rawRows
        .map((item) => Fr5ExpectedRow.fromJson(_stringMap(item)))
        .toList(growable: false);

    final seen = <String>{};
    for (final row in rows) {
      final key = '${row.targetTable}|${row.targetKey}';
      if (!seen.add(key)) {
        throw StateError('Duplicate expected FR5 target identity $key.');
      }
    }

    return Fr5ExpectedPlan(
      rows: List<Fr5ExpectedRow>.unmodifiable(rows),
      sourceCounts: Map<String, int>.unmodifiable(
        _intMap(json['sourceCounts']),
      ),
      targetCounts: Map<String, int>.unmodifiable(
        _intMap(json['targetCounts']),
      ),
    );
  }
}

class Fr5TargetRow {
  const Fr5TargetRow({
    required this.table,
    required this.row,
  });

  final String table;
  final Map<String, dynamic> row;

  String get targetKey => fr5TargetKey(table, row);
}

class Fr5ParityIssue {
  const Fr5ParityIssue({
    required this.kind,
    required this.targetTable,
    required this.targetKey,
    required this.message,
  });

  final String kind;
  final String targetTable;
  final String targetKey;
  final String message;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'kind': kind,
    'targetTable': targetTable,
    'targetKey': targetKey,
    'message': message,
  };
}

class Fr5ParityReport {
  const Fr5ParityReport({
    required this.expectedRowCount,
    required this.targetRowCount,
    required this.matchedRowCount,
    required this.learnerVisibleMatchedCount,
    required this.ledgerMatchedCount,
    required this.issues,
  });

  final int expectedRowCount;
  final int targetRowCount;
  final int matchedRowCount;
  final int learnerVisibleMatchedCount;
  final int ledgerMatchedCount;
  final List<Fr5ParityIssue> issues;

  int countKind(String kind) =>
      issues.where((issue) => issue.kind == kind).length;

  bool get completeParity =>
      expectedRowCount == targetRowCount &&
      expectedRowCount == matchedRowCount &&
      expectedRowCount == learnerVisibleMatchedCount &&
      expectedRowCount == ledgerMatchedCount &&
      issues.isEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schemaVersion': 1,
    'phase': 'FR5',
    'completeParity': completeParity,
    'expectedRowCount': expectedRowCount,
    'targetRowCount': targetRowCount,
    'matchedRowCount': matchedRowCount,
    'learnerVisibleMatchedCount': learnerVisibleMatchedCount,
    'ledgerMatchedCount': ledgerMatchedCount,
    'missingCount': countKind('missing_target'),
    'checksumMismatchCount': countKind('checksum_mismatch'),
    'learnerVisibleMismatchCount': countKind('learner_visible_mismatch'),
    'extraCount': countKind('extra_target'),
    'duplicateTargetCount': countKind('duplicate_target'),
    'missingLedgerCount': countKind('missing_ledger'),
    'ledgerMismatchCount': countKind('ledger_mismatch'),
    'extraLedgerCount': countKind('extra_ledger'),
    'issues': issues.map((issue) => issue.toJson()).toList(growable: false),
  };
}

class Fr5ShadowParityEngine {
  const Fr5ShadowParityEngine();

  Fr5ParityReport compare({
    required Fr5ExpectedPlan expected,
    required Iterable<Fr5TargetRow> targetRows,
    required Iterable<Map<String, dynamic>> ledgerRows,
  }) {
    final issues = <Fr5ParityIssue>[];
    final expectedByKey = <String, Fr5ExpectedRow>{
      for (final row in expected.rows)
        '${row.targetTable}|${row.targetKey}': row,
    };

    final targetByKey = <String, Fr5TargetRow>{};
    for (final target in targetRows) {
      if (!fr5SupportedTargetTables.contains(target.table)) {
        continue;
      }

      final key = '${target.table}|${target.targetKey}';
      if (targetByKey.containsKey(key)) {
        issues.add(
          Fr5ParityIssue(
            kind: 'duplicate_target',
            targetTable: target.table,
            targetKey: target.targetKey,
            message: 'Supabase returned the same target identity more than once.',
          ),
        );
        continue;
      }
      targetByKey[key] = target;
    }

    var matched = 0;
    var learnerMatched = 0;

    for (final entry in expectedByKey.entries) {
      final planned = entry.value;
      final actual = targetByKey[entry.key];

      if (actual == null) {
        issues.add(
          Fr5ParityIssue(
            kind: 'missing_target',
            targetTable: planned.targetTable,
            targetKey: planned.targetKey,
            message: 'Expected FR4 row is missing from Supabase shadow data.',
          ),
        );
        continue;
      }

      var targetMatches = false;
      try {
        targetMatches = fr4TargetMatches(
          planned.toFr4TargetRow(),
          actual.row,
        );
      } catch (error) {
        issues.add(
          Fr5ParityIssue(
            kind: 'checksum_mismatch',
            targetTable: planned.targetTable,
            targetKey: planned.targetKey,
            message: error.toString(),
          ),
        );
      }

      if (!targetMatches) {
        if (!issues.any(
          (issue) =>
              issue.kind == 'checksum_mismatch' &&
              issue.targetTable == planned.targetTable &&
              issue.targetKey == planned.targetKey,
        )) {
          issues.add(
            Fr5ParityIssue(
              kind: 'checksum_mismatch',
              targetTable: planned.targetTable,
              targetKey: planned.targetKey,
              message: 'Target row checksum does not match frozen FR4 evidence.',
            ),
          );
        }
      } else {
        matched++;
      }

      if (fr5LearnerVisibleMatches(planned, actual.row)) {
        learnerMatched++;
      } else {
        issues.add(
          Fr5ParityIssue(
            kind: 'learner_visible_mismatch',
            targetTable: planned.targetTable,
            targetKey: planned.targetKey,
            message:
                'Learner-visible source projection differs from Supabase row.',
          ),
        );
      }
    }

    for (final entry in targetByKey.entries) {
      if (!expectedByKey.containsKey(entry.key)) {
        issues.add(
          Fr5ParityIssue(
            kind: 'extra_target',
            targetTable: entry.value.table,
            targetKey: entry.value.targetKey,
            message:
                'Supabase shadow data contains a row absent from FR4 evidence.',
          ),
        );
      }
    }

    final ledgerByKey = <String, Map<String, dynamic>>{};
    for (final raw in ledgerRows) {
      final row = Map<String, dynamic>.from(raw);
      if (row['source_system']?.toString() != 'firestore') {
        continue;
      }

      final collection = row['source_collection']?.toString() ?? '';
      final sourceId = row['source_id']?.toString() ?? '';
      if (collection.isEmpty || sourceId.isEmpty) {
        continue;
      }

      final key = '$collection|$sourceId';
      if (ledgerByKey.containsKey(key)) {
        issues.add(
          Fr5ParityIssue(
            kind: 'ledger_mismatch',
            targetTable: 'fr_migration_ledger',
            targetKey: key,
            message: 'Duplicate migration-ledger identity.',
          ),
        );
        continue;
      }
      ledgerByKey[key] = row;
    }

    var ledgerMatched = 0;
    final expectedLedgerKeys = <String>{};

    for (final planned in expected.rows) {
      final ledgerKey = '${planned.sourceCollection}|${planned.sourceId}';
      expectedLedgerKeys.add(ledgerKey);
      final ledger = ledgerByKey[ledgerKey];

      if (ledger == null) {
        issues.add(
          Fr5ParityIssue(
            kind: 'missing_ledger',
            targetTable: 'fr_migration_ledger',
            targetKey: ledgerKey,
            message: 'Expected migration-ledger evidence is missing.',
          ),
        );
        continue;
      }

      final valid =
          ledger['target_table']?.toString() == planned.targetTable &&
          ledger['target_key']?.toString() == planned.targetKey &&
          ledger['source_checksum_sha256']?.toString() ==
              planned.sourceChecksumSha256 &&
          ledger['target_checksum_sha256']?.toString() ==
              planned.targetChecksumSha256 &&
          ledger['validation_status']?.toString() == 'matched';

      if (valid) {
        ledgerMatched++;
      } else {
        issues.add(
          Fr5ParityIssue(
            kind: 'ledger_mismatch',
            targetTable: 'fr_migration_ledger',
            targetKey: ledgerKey,
            message:
                'Migration ledger does not prove the frozen source/target checksum pair.',
          ),
        );
      }
    }

    for (final entry in ledgerByKey.entries) {
      final collection = entry.value['source_collection']?.toString() ?? '';
      if (fr4SupportedCollections.contains(collection) &&
          !expectedLedgerKeys.contains(entry.key)) {
        issues.add(
          Fr5ParityIssue(
            kind: 'extra_ledger',
            targetTable: 'fr_migration_ledger',
            targetKey: entry.key,
            message:
                'Migration ledger contains supported-source evidence absent from the frozen FR4 plan.',
          ),
        );
      }
    }

    return Fr5ParityReport(
      expectedRowCount: expected.rows.length,
      targetRowCount: targetByKey.length,
      matchedRowCount: matched,
      learnerVisibleMatchedCount: learnerMatched,
      ledgerMatchedCount: ledgerMatched,
      issues: List<Fr5ParityIssue>.unmodifiable(issues),
    );
  }
}

String fr5TargetKey(String table, Map<String, dynamic> row) {
  switch (table) {
    case 'content_versions':
      return '${_requiredString(row, 'content_id')}|v'
          '${_requiredPositiveInt(row, 'version')}';
    case 'questions':
      return '${_requiredPositiveInt(row, 'question_id')}|v'
          '${_requiredPositiveInt(row, 'version')}';
    default:
      throw StateError('No FR5 identity rule for target table "$table".');
  }
}

bool fr5LearnerVisibleMatches(
  Fr5ExpectedRow expected,
  Map<String, dynamic> actual,
) {
  if (expected.targetTable == 'content_versions') {
    if (!actual.containsKey('content_payload')) {
      return false;
    }
    return fr4Sha256(actual['content_payload']) ==
        fr4Sha256(expected.row['content_payload']);
  }

  if (expected.targetTable == 'questions') {
    final reconstructed = <String, dynamic>{
      'id': actual['question_id'],
      'domain': actual['domain_number'],
      'competencyId': actual['competency_id'],
      'subtopicId': actual['subtopic_id'],
      'topicId': actual['topic_id'],
      'quizId': actual['quiz_id'],
      'contentPackageId': actual['content_package_id'],
      'question': actual['stem'],
      'options': actual['options'],
      'correctAnswer': actual['correct_answer'],
      'explanation': actual['explanation'],
      'bestAnswerRationale': actual['best_answer_rationale'],
      'reference': actual['reference_text'],
      'difficulty': actual['difficulty'],
      'cognitiveLevel': actual['cognitive_level'],
      'questionType': actual['question_type'],
      'status': actual['status'],
      'version': actual['version'],
      'tags': actual['tags'],
    };
    return fr4Sha256(reconstructed) ==
        fr4Sha256(expected.row['source_payload']);
  }

  return false;
}

Map<String, dynamic> fr5MatchedLedgerRow(Fr5ExpectedRow planned) {
  final now = DateTime.now().toUtc().toIso8601String();
  return <String, dynamic>{
    'source_system': 'firestore',
    'source_collection': planned.sourceCollection,
    'source_id': planned.sourceId,
    'target_table': planned.targetTable,
    'target_key': planned.targetKey,
    'source_checksum_sha256': planned.sourceChecksumSha256,
    'target_checksum_sha256': planned.targetChecksumSha256,
    'validation_status': 'matched',
    'failure_reason': null,
    'migrated_at': now,
    'validated_at': now,
    'metadata': <String, dynamic>{
      'phase': 'FR5',
      'toolingSchemaVersion': 1,
      'parity': 'shadow',
    },
  };
}

Map<String, dynamic> _stringMap(dynamic value) {
  if (value is! Map) {
    throw const FormatException('Expected an object.');
  }
  return <String, dynamic>{
    for (final entry in value.entries) entry.key.toString(): entry.value,
  };
}

Map<String, int> _intMap(dynamic value) {
  if (value is! Map) return const <String, int>{};
  return <String, int>{
    for (final entry in value.entries)
      entry.key.toString(): _intValue(entry.value),
  };
}

String _requiredString(Map<String, dynamic> source, String key) {
  final value = source[key]?.toString().trim() ?? '';
  if (value.isEmpty) {
    throw StateError('Required field "$key" is empty.');
  }
  return value;
}

int _requiredPositiveInt(Map<String, dynamic> source, String key) {
  final value = _intValue(source[key]);
  if (value <= 0) {
    throw StateError('Required field "$key" must be greater than zero.');
  }
  return value;
}

int _intValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _requiredChecksum(Map<String, dynamic> source, String key) {
  final value = _requiredString(source, key).toLowerCase();
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
    throw StateError('Required checksum "$key" is invalid.');
  }
  return value;
}
