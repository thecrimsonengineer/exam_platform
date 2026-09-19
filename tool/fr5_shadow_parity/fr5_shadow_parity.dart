import 'dart:convert';
import 'dart:io';

import 'fr5_shadow_parity_core.dart';

Future<void> main(List<String> args) async {
  final options = _Arguments.parse(args);

  if (options.help) {
    stdout.writeln(_usage);
    return;
  }

  final expected = Fr5ExpectedPlan.fromFr4Evidence(
    _readJsonObject(options.fr4EvidencePath),
  );

  if (options.targetPath != null) {
    if (options.applyShadow) {
      throw StateError('FR5 local-target mode is read-only.');
    }

    final fixture = _readJsonObject(options.targetPath!);
    final snapshot = _snapshotFromFixture(fixture, expected);
    final report = const Fr5ShadowParityEngine().compare(
      expected: expected,
      targetRows: snapshot.targetRows,
      ledgerRows: snapshot.ledgerRows,
    );

    await _writeEvidence(options.evidencePath, <String, dynamic>{
      ...report.toJson(),
      'sourceMode': 'fr4-evidence',
      'targetMode': 'local-fixture',
      'applyRequested': false,
    });

    if (!report.completeParity) {
      stderr.writeln(
        'FR5 FIXTURE PARITY FAILED: ${report.issues.length} issue(s).',
      );
      exitCode = 2;
      return;
    }

    stdout.writeln(
      'FR5 FIXTURE PARITY PASS: ${report.expectedRowCount} row(s) match.',
    );
    return;
  }

  final config = _SupabaseServerConfig.fromEnvironment();
  final client = _SupabaseRestClient(config);

  var targetRows = await client.fetchShadowRows();
  var ledgerRows = await client.fetchLedgerRows();

  if (options.preflightOnly) {
    if (options.applyShadow) {
      throw StateError('FR5 preflight and apply-shadow cannot run together.');
    }

    final extras = _unexpectedTargetKeys(expected, targetRows);
    await _writeEvidence(options.evidencePath, <String, dynamic>{
      'schemaVersion': 1,
      'phase': 'FR5',
      'preflightOnly': true,
      'safeToApply': extras.isEmpty,
      'expectedRowCount': expected.rows.length,
      'currentTargetRowCount': targetRows.length,
      'unexpectedTargetKeys': extras,
      'credentialKind': config.credentialKind,
    });

    if (extras.isNotEmpty) {
      stderr.writeln(
        'FR5 PREFLIGHT FAILED: ${extras.length} unexpected target row(s).',
      );
      exitCode = 4;
      return;
    }

    stdout.writeln(
      'FR5 PREFLIGHT PASS: no unexpected shadow target rows detected.',
    );
    return;
  }

  if (options.applyShadow) {
    if (options.confirmation != 'FR5_SHADOW_ONLY') {
      stderr.writeln(
        'FR5 shadow apply is blocked. Pass '
        '--confirm=FR5_SHADOW_ONLY explicitly.',
      );
      exitCode = 3;
      return;
    }

    final extras = _unexpectedTargetKeys(expected, targetRows);
    if (extras.isNotEmpty) {
      await _writeEvidence(options.evidencePath, <String, dynamic>{
        'schemaVersion': 1,
        'phase': 'FR5',
        'completeParity': false,
        'applyRequested': true,
        'blockedBeforeWrite': true,
        'unexpectedTargetKeys': extras,
      });
      stderr.writeln(
        'FR5 FAIL-CLOSED: shadow target contains ${extras.length} '
        'unexpected row(s). No write performed.',
      );
      exitCode = 4;
      return;
    }

    await client.upsertExpectedRows(expected.rows);

    targetRows = await client.fetchShadowRows();
    final preLedger = const Fr5ShadowParityEngine().compare(
      expected: expected,
      targetRows: targetRows,
      ledgerRows: expected.rows
          .map(fr5MatchedLedgerRow)
          .toList(growable: false),
    );

    final dataIssues = preLedger.issues
        .where(
          (issue) =>
              issue.kind != 'missing_ledger' &&
              issue.kind != 'ledger_mismatch' &&
              issue.kind != 'extra_ledger',
        )
        .toList(growable: false);

    if (dataIssues.isNotEmpty ||
        preLedger.matchedRowCount != expected.rows.length ||
        preLedger.learnerVisibleMatchedCount != expected.rows.length) {
      await _writeEvidence(options.evidencePath, <String, dynamic>{
        ...preLedger.toJson(),
        'applyRequested': true,
        'blockedBeforeLedgerWrite': true,
      });
      stderr.writeln(
        'FR5 SHADOW APPLY FAILED before ledger commit: '
        '${dataIssues.length} data parity issue(s).',
      );
      exitCode = 5;
      return;
    }

    await client.upsertLedgerRows(
      expected.rows.map(fr5MatchedLedgerRow).toList(growable: false),
    );

    targetRows = await client.fetchShadowRows();
    ledgerRows = await client.fetchLedgerRows();
  }

  final report = const Fr5ShadowParityEngine().compare(
    expected: expected,
    targetRows: targetRows,
    ledgerRows: ledgerRows,
  );

  await _writeEvidence(options.evidencePath, <String, dynamic>{
    ...report.toJson(),
    'sourceMode': 'fr4-evidence',
    'targetMode': 'supabase-shadow',
    'applyRequested': options.applyShadow,
    'credentialKind': config.credentialKind,
  });

  if (!report.completeParity) {
    stderr.writeln(
      'FR5 SHADOW PARITY FAILED: ${report.issues.length} issue(s).',
    );
    exitCode = 6;
    return;
  }

  stdout.writeln(
    'FR5 SHADOW PARITY PASS: ${report.expectedRowCount} row(s), '
    'learner-visible parity and ledger evidence all match.',
  );
}

class _Snapshot {
  const _Snapshot({required this.targetRows, required this.ledgerRows});

  final List<Fr5TargetRow> targetRows;
  final List<Map<String, dynamic>> ledgerRows;
}

_Snapshot _snapshotFromFixture(
  Map<String, dynamic> fixture,
  Fr5ExpectedPlan expected,
) {
  final rawTables = fixture['tables'];
  if (rawTables is! Map) {
    throw const FormatException('FR5 target fixture requires "tables".');
  }

  final tables = Map<String, dynamic>.from(rawTables);
  final targetRows = <Fr5TargetRow>[];

  for (final table in fr5SupportedTargetTables) {
    final rows = tables[table];
    if (rows == null) continue;
    if (rows is! List) {
      throw FormatException('Fixture table "$table" must be a list.');
    }

    for (final row in rows) {
      if (row is! Map) {
        throw FormatException('Fixture table "$table" contains a non-object.');
      }
      targetRows.add(
        Fr5TargetRow(table: table, row: Map<String, dynamic>.from(row)),
      );
    }
  }

  final ledgerRows = <Map<String, dynamic>>[];
  final rawLedger = fixture['ledger'];

  if (rawLedger is List) {
    for (final row in rawLedger) {
      if (row is! Map) {
        throw const FormatException('Fixture ledger contains a non-object.');
      }
      ledgerRows.add(Map<String, dynamic>.from(row));
    }
  } else if (fixture['ledgerFromPlan'] == true) {
    ledgerRows.addAll(expected.rows.map(fr5MatchedLedgerRow));
  } else {
    throw const FormatException(
      'FR5 target fixture requires ledger rows or ledgerFromPlan=true.',
    );
  }

  return _Snapshot(
    targetRows: List<Fr5TargetRow>.unmodifiable(targetRows),
    ledgerRows: List<Map<String, dynamic>>.unmodifiable(ledgerRows),
  );
}

List<String> _unexpectedTargetKeys(
  Fr5ExpectedPlan expected,
  Iterable<Fr5TargetRow> actual,
) {
  final expectedKeys = <String>{
    for (final row in expected.rows) '${row.targetTable}|${row.targetKey}',
  };

  final extras = <String>[];
  for (final row in actual) {
    final key = '${row.table}|${row.targetKey}';
    if (!expectedKeys.contains(key)) {
      extras.add(key);
    }
  }
  extras.sort();
  return extras;
}

class _SupabaseServerConfig {
  const _SupabaseServerConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.credentialKind,
  });

  final String baseUrl;
  final String apiKey;
  final String credentialKind;

  factory _SupabaseServerConfig.fromEnvironment() {
    final baseUrl = Platform.environment['SUPABASE_URL']?.trim() ?? '';
    final secretKey = Platform.environment['SUPABASE_SECRET_KEY']?.trim() ?? '';
    final legacyServiceRole =
        Platform.environment['SUPABASE_SERVICE_ROLE_KEY']?.trim() ?? '';

    if (baseUrl.isEmpty) {
      throw StateError('FR5 remote mode requires SUPABASE_URL.');
    }

    if (secretKey.isNotEmpty) {
      return _SupabaseServerConfig(
        baseUrl: baseUrl,
        apiKey: secretKey,
        credentialKind: 'secret_key',
      );
    }

    if (legacyServiceRole.isNotEmpty) {
      return _SupabaseServerConfig(
        baseUrl: baseUrl,
        apiKey: legacyServiceRole,
        credentialKind: 'legacy_service_role',
      );
    }

    throw StateError(
      'FR5 remote mode requires SUPABASE_SECRET_KEY. '
      'SUPABASE_SERVICE_ROLE_KEY is accepted only for migration compatibility.',
    );
  }
}

class _SupabaseRestClient {
  _SupabaseRestClient(_SupabaseServerConfig config)
    : baseUri = Uri.parse(config.baseUrl),
      apiKey = config.apiKey,
      legacyJwt = config.credentialKind == 'legacy_service_role';

  final Uri baseUri;
  final String apiKey;
  final bool legacyJwt;

  Future<List<Fr5TargetRow>> fetchShadowRows() async {
    final rows = <Fr5TargetRow>[];
    for (final table in fr5SupportedTargetTables.toList()..sort()) {
      final pageRows = await _fetchAll(table);
      rows.addAll(pageRows.map((row) => Fr5TargetRow(table: table, row: row)));
    }
    return rows;
  }

  Future<List<Map<String, dynamic>>> fetchLedgerRows() =>
      _fetchAll('fr_migration_ledger');

  Future<void> upsertExpectedRows(List<Fr5ExpectedRow> rows) async {
    final byTable = <String, List<Map<String, dynamic>>>{};
    for (final planned in rows) {
      byTable
          .putIfAbsent(planned.targetTable, () => <Map<String, dynamic>>[])
          .add(planned.row);
    }

    for (final entry in byTable.entries) {
      final conflict = switch (entry.key) {
        'content_versions' => 'content_id,version',
        'questions' => 'question_id,version',
        _ => throw StateError('No FR5 conflict key for ${entry.key}.'),
      };
      await _upsertBatches(
        table: entry.key,
        conflictColumns: conflict,
        rows: entry.value,
      );
    }
  }

  Future<void> upsertLedgerRows(List<Map<String, dynamic>> rows) =>
      _upsertBatches(
        table: 'fr_migration_ledger',
        conflictColumns: 'source_system,source_collection,source_id',
        rows: rows,
      );

  Future<void> _upsertBatches({
    required String table,
    required String conflictColumns,
    required List<Map<String, dynamic>> rows,
  }) async {
    const batchSize = 200;

    for (var start = 0; start < rows.length; start += batchSize) {
      final end = (start + batchSize < rows.length)
          ? start + batchSize
          : rows.length;
      final batch = rows.sublist(start, end);
      final uri = _tableUri(table, <String, String>{
        'on_conflict': conflictColumns,
      });

      final response = await _request(
        'POST',
        uri,
        body: batch,
        prefer: 'resolution=merge-duplicates,return=minimal',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Supabase FR5 upsert failed for $table '
          '(${response.statusCode}): ${response.body}',
          uri: uri,
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAll(String table) async {
    const pageSize = 1000;
    final output = <Map<String, dynamic>>[];

    for (var offset = 0; ; offset += pageSize) {
      final uri = _tableUri(table, <String, String>{
        'select': '*',
        'limit': '$pageSize',
        'offset': '$offset',
      });

      final response = await _request('GET', uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Supabase FR5 fetch failed for $table '
          '(${response.statusCode}): ${response.body}',
          uri: uri,
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw FormatException('Supabase table "$table" did not return a list.');
      }

      for (final row in decoded) {
        if (row is! Map) {
          throw FormatException(
            'Supabase table "$table" returned a non-object row.',
          );
        }
        output.add(Map<String, dynamic>.from(row));
      }

      if (decoded.length < pageSize) {
        break;
      }
    }

    return output;
  }

  Uri _tableUri(String table, Map<String, String> query) {
    return baseUri.replace(
      path: '${baseUri.path}/rest/v1/$table'.replaceAll('//', '/'),
      queryParameters: query,
    );
  }

  Future<_HttpResult> _request(
    String method,
    Uri uri, {
    dynamic body,
    String? prefer,
  }) async {
    final client = HttpClient();

    try {
      final request = await client.openUrl(method, uri);
      request.headers.set('apikey', apiKey);
      if (legacyJwt) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
      }
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'csp11-fr5-shadow-parity/1',
      );

      if (prefer != null) {
        request.headers.set('Prefer', prefer);
      }

      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }

      final response = await request.close();
      final responseBody = await utf8.decoder.bind(response).join();

      return _HttpResult(statusCode: response.statusCode, body: responseBody);
    } finally {
      client.close(force: true);
    }
  }
}

class _HttpResult {
  const _HttpResult({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

class _Arguments {
  const _Arguments({
    required this.help,
    required this.fr4EvidencePath,
    required this.targetPath,
    required this.evidencePath,
    required this.applyShadow,
    required this.preflightOnly,
    required this.confirmation,
  });

  final bool help;
  final String fr4EvidencePath;
  final String? targetPath;
  final String evidencePath;
  final bool applyShadow;
  final bool preflightOnly;
  final String? confirmation;

  static _Arguments parse(List<String> args) {
    var help = false;
    String? fr4EvidencePath;
    String? targetPath;
    var evidencePath = 'build/fr5/fr5_shadow_parity_evidence.json';
    var applyShadow = false;
    var preflightOnly = false;
    String? confirmation;

    for (final arg in args) {
      if (arg == '--help' || arg == '-h') {
        help = true;
      } else if (arg.startsWith('--fr4-evidence=')) {
        fr4EvidencePath = arg.substring('--fr4-evidence='.length);
      } else if (arg.startsWith('--target=')) {
        targetPath = arg.substring('--target='.length);
      } else if (arg.startsWith('--evidence=')) {
        evidencePath = arg.substring('--evidence='.length);
      } else if (arg == '--apply-shadow') {
        applyShadow = true;
      } else if (arg == '--preflight') {
        preflightOnly = true;
      } else if (arg.startsWith('--confirm=')) {
        confirmation = arg.substring('--confirm='.length);
      } else {
        throw FormatException('Unknown FR5 argument: $arg');
      }
    }

    if (!help && (fr4EvidencePath == null || fr4EvidencePath.isEmpty)) {
      throw const FormatException('FR5 requires --fr4-evidence=<json>.');
    }

    return _Arguments(
      help: help,
      fr4EvidencePath: fr4EvidencePath ?? '',
      targetPath: targetPath,
      evidencePath: evidencePath,
      applyShadow: applyShadow,
      preflightOnly: preflightOnly,
      confirmation: confirmation,
    );
  }
}

Map<String, dynamic> _readJsonObject(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw StateError('JSON file does not exist: $path');
  }

  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map) {
    throw FormatException('JSON file "$path" must contain an object.');
  }
  return Map<String, dynamic>.from(decoded);
}

Future<void> _writeEvidence(String path, Map<String, dynamic> report) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(report),
    flush: true,
  );
}

const _usage = '''
CSP11 Phase FR5 shadow-data parity tool

Validate a deterministic local target fixture:
  dart run tool/fr5_shadow_parity/fr5_shadow_parity.dart \
    --fr4-evidence=build/fr5/fr4_plan.json \
    --target=test/fixtures/fr5/target_snapshot.json

Preflight current Supabase shadow data without writing:
  SUPABASE_URL=... SUPABASE_SECRET_KEY=... \
  dart run tool/fr5_shadow_parity/fr5_shadow_parity.dart \
    --fr4-evidence=<frozen-fr4-evidence.json> \
    --preflight

Validate current Supabase shadow data:
  SUPABASE_URL=... SUPABASE_SECRET_KEY=... \
  dart run tool/fr5_shadow_parity/fr5_shadow_parity.dart \
    --fr4-evidence=<frozen-fr4-evidence.json>

Apply the frozen FR4 plan to Supabase shadow tables, then verify exact parity:
  SUPABASE_URL=... SUPABASE_SECRET_KEY=... \
  dart run tool/fr5_shadow_parity/fr5_shadow_parity.dart \
    --fr4-evidence=<frozen-fr4-evidence.json> \
    --apply-shadow --confirm=FR5_SHADOW_ONLY

FR5 never changes learner runtime routing and never deletes unexpected target rows.
''';
