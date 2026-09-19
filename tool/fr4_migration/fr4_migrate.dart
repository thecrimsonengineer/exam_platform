import 'dart:convert';
import 'dart:io';

import 'fr4_migration_core.dart';

Future<void> main(List<String> args) async {
  final options = _Arguments.parse(args);

  if (options.help) {
    stdout.writeln(_usage);
    return;
  }

  final documents = options.inputPath != null
      ? await _loadLocalDocuments(options.inputPath!)
      : await _loadFirestoreDocuments(options);

  final engine = const Fr4MigrationEngine();
  final plan = engine.build(documents);

  final report = <String, dynamic>{
    ...plan.toJson(),
    'sourceMode': options.inputPath != null ? 'file' : 'firestore-rest',
    'applyRequested': options.apply,
  };

  if (!plan.readyToApply) {
    await _writeEvidence(options.evidencePath, report);
    stderr.writeln(
      'FR4 FAIL-CLOSED: migration plan has ${plan.issues.length} issue(s).',
    );
    exitCode = 2;
    return;
  }

  if (!options.apply) {
    await _writeEvidence(options.evidencePath, report);
    stdout.writeln(
      'FR4 PLAN-ONLY PASS: ${plan.rows.length} row(s) normalized with '
      'zero duplicate, failure, or unmapped issues.',
    );
    return;
  }

  if (options.confirmation != 'FR4_SHADOW_ONLY') {
    stderr.writeln(
      'FR4 apply is blocked. Pass --confirm=FR4_SHADOW_ONLY explicitly.',
    );
    exitCode = 3;
    return;
  }

  final supabaseUrl = Platform.environment['SUPABASE_URL']?.trim() ?? '';
  final serviceRole =
      Platform.environment['SUPABASE_SERVICE_ROLE_KEY']?.trim() ?? '';

  if (supabaseUrl.isEmpty || serviceRole.isEmpty) {
    stderr.writeln(
      'FR4 apply requires SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.',
    );
    exitCode = 4;
    return;
  }

  final client = _SupabaseRestClient(
    baseUrl: supabaseUrl,
    serviceRoleKey: serviceRole,
  );

  final applyEvidence = await _applyAndVerify(client, plan);
  final finalReport = <String, dynamic>{
    ...report,
    ...applyEvidence,
  };

  await _writeEvidence(options.evidencePath, finalReport);

  if (applyEvidence['verified'] != true) {
    stderr.writeln('FR4 APPLY VERIFICATION FAILED.');
    exitCode = 5;
    return;
  }

  stdout.writeln(
    'FR4 SHADOW APPLY PASS: ${plan.rows.length} row(s) upserted and verified.',
  );
}

Future<List<Fr4SourceDocument>> _loadLocalDocuments(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    throw StateError('Input file does not exist: $path');
  }

  final decoded = jsonDecode(await file.readAsString());
  final items = decoded is List
      ? decoded
      : decoded is Map && decoded['documents'] is List
      ? decoded['documents'] as List
      : throw const FormatException(
          'Input must be a JSON list or {"documents": [...]} object.',
        );

  return items.map((item) {
    if (item is! Map) {
      throw const FormatException('Each input document must be an object.');
    }
    final map = Map<String, dynamic>.from(item);
    final collection = map['collection']?.toString().trim() ?? '';
    final id = map['id']?.toString().trim() ?? '';
    final data = map['data'];
    if (collection.isEmpty || id.isEmpty || data is! Map) {
      throw const FormatException(
        'Each input document needs collection, id, and object data.',
      );
    }
    return Fr4SourceDocument(
      collection: collection,
      id: id,
      data: Map<String, dynamic>.from(data),
    );
  }).toList(growable: false);
}

Future<List<Fr4SourceDocument>> _loadFirestoreDocuments(
  _Arguments options,
) async {
  final projectId = options.firestoreProjectId;
  if (projectId == null || projectId.isEmpty) {
    throw StateError(
      'Remote extraction requires --firestore-project=<project-id>.',
    );
  }

  final token =
      Platform.environment['GOOGLE_OAUTH_ACCESS_TOKEN']?.trim() ?? '';
  if (token.isEmpty) {
    throw StateError(
      'Remote extraction requires GOOGLE_OAUTH_ACCESS_TOKEN.',
    );
  }

  final collections = options.collections.isEmpty
      ? (fr4SupportedCollections.toList()..sort())
      : options.collections;

  final client = HttpClient();
  try {
    final output = <Fr4SourceDocument>[];
    for (final collection in collections) {
      if (!fr4SupportedCollections.contains(collection)) {
        throw StateError(
          'Collection "$collection" has no frozen FR4 normalizer.',
        );
      }

      String? pageToken;
      do {
        final parameters = <String, String>{
          'pageSize': '1000',
          if (pageToken != null && pageToken.isNotEmpty)
            'pageToken': pageToken,
        };
        final uri = Uri.https(
          'firestore.googleapis.com',
          '/v1/projects/$projectId/databases/(default)/documents/$collection',
          parameters,
        );
        final request = await client.getUrl(uri);
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $token',
        );
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');

        final response = await request.close();
        final body = await utf8.decoder.bind(response).join();
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw HttpException(
            'Firestore list failed for $collection '
            '(${response.statusCode}): $body',
            uri: uri,
          );
        }

        final payload = jsonDecode(body);
        if (payload is! Map) {
          throw const FormatException('Firestore response is not an object.');
        }
        final map = Map<String, dynamic>.from(payload);
        final documents = map['documents'];
        if (documents is List) {
          for (final document in documents) {
            output.add(
              decodeFirestoreRestDocument(
                collection: collection,
                document: document,
              ),
            );
          }
        }
        pageToken = map['nextPageToken']?.toString();
      } while (pageToken != null && pageToken.isNotEmpty);
    }
    return output;
  } finally {
    client.close(force: true);
  }
}

Future<Map<String, dynamic>> _applyAndVerify(
  _SupabaseRestClient client,
  Fr4MigrationPlan plan,
) async {
  final rowsByTable = <String, List<Fr4TargetRow>>{};
  for (final row in plan.rows) {
    rowsByTable.putIfAbsent(row.targetTable, () => <Fr4TargetRow>[]).add(row);
  }

  final verification = <Map<String, dynamic>>[];
  var allVerified = true;

  for (final entry in rowsByTable.entries) {
    final conflictColumns = switch (entry.key) {
      'content_versions' => 'content_id,version',
      'questions' => 'question_id,version',
      _ => throw StateError('No FR4 conflict key for ${entry.key}.'),
    };

    await client.upsert(
      table: entry.key,
      conflictColumns: conflictColumns,
      rows: entry.value.map((row) => row.row).toList(growable: false),
    );

    for (final planned in entry.value) {
      final returned = await client.fetchTarget(planned);
      final matched = returned != null && fr4TargetMatches(planned, returned);
      allVerified = allVerified && matched;

      verification.add(<String, dynamic>{
        'sourceCollection': planned.sourceCollection,
        'sourceId': planned.sourceId,
        'targetTable': planned.targetTable,
        'targetKey': planned.targetKey,
        'matched': matched,
      });

      await client.upsertLedger(
        <String, dynamic>{
          ...planned.pendingLedgerRow(),
          'validation_status': matched ? 'matched' : 'mismatch',
          'failure_reason': matched ? null : 'Target checksum mismatch.',
          'validated_at': DateTime.now().toUtc().toIso8601String(),
          'migrated_at': DateTime.now().toUtc().toIso8601String(),
        },
      );
    }
  }

  return <String, dynamic>{
    'applied': true,
    'verified': allVerified,
    'verification': verification,
  };
}

class _SupabaseRestClient {
  _SupabaseRestClient({
    required String baseUrl,
    required this.serviceRoleKey,
  }) : baseUri = Uri.parse(baseUrl);

  final Uri baseUri;
  final String serviceRoleKey;

  Future<void> upsert({
    required String table,
    required String conflictColumns,
    required List<Map<String, dynamic>> rows,
  }) async {
    final uri = baseUri.replace(
      path: '${baseUri.path}/rest/v1/$table'.replaceAll('//', '/'),
      queryParameters: <String, String>{'on_conflict': conflictColumns},
    );
    final response = await _request(
      'POST',
      uri,
      body: rows,
      prefer: 'resolution=merge-duplicates,return=minimal',
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Supabase upsert failed for $table '
        '(${response.statusCode}): ${response.body}',
        uri: uri,
      );
    }
  }

  Future<void> upsertLedger(Map<String, dynamic> row) async {
    await upsert(
      table: 'fr_migration_ledger',
      conflictColumns: 'source_system,source_collection,source_id',
      rows: <Map<String, dynamic>>[row],
    );
  }

  Future<Map<String, dynamic>?> fetchTarget(Fr4TargetRow row) async {
    final query = switch (row.targetTable) {
      'content_versions' => <String, String>{
          'content_id': 'eq.${row.row['content_id']}',
          'version': 'eq.${row.row['version']}',
          'limit': '1',
        },
      'questions' => <String, String>{
          'question_id': 'eq.${row.row['question_id']}',
          'version': 'eq.${row.row['version']}',
          'limit': '1',
        },
      _ => throw StateError('No verification query for ${row.targetTable}.'),
    };

    final uri = baseUri.replace(
      path:
          '${baseUri.path}/rest/v1/${row.targetTable}'.replaceAll('//', '/'),
      queryParameters: query,
    );
    final response = await _request('GET', uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Supabase verification fetch failed '
        '(${response.statusCode}): ${response.body}',
        uri: uri,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty) return null;
    final first = decoded.first;
    if (first is! Map) {
      throw const FormatException('Supabase row is not an object.');
    }
    return Map<String, dynamic>.from(first);
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
      request.headers.set('apikey', serviceRoleKey);
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $serviceRoleKey',
      );
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (prefer != null) request.headers.set('Prefer', prefer);
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      final response = await request.close();
      final responseBody = await utf8.decoder.bind(response).join();
      return _HttpResult(response.statusCode, responseBody);
    } finally {
      client.close(force: true);
    }
  }
}

class _HttpResult {
  const _HttpResult(this.statusCode, this.body);
  final int statusCode;
  final String body;
}

class _Arguments {
  const _Arguments({
    required this.help,
    required this.apply,
    required this.inputPath,
    required this.evidencePath,
    required this.firestoreProjectId,
    required this.collections,
    required this.confirmation,
  });

  final bool help;
  final bool apply;
  final String? inputPath;
  final String evidencePath;
  final String? firestoreProjectId;
  final List<String> collections;
  final String? confirmation;

  static _Arguments parse(List<String> args) {
    var help = false;
    var apply = false;
    String? inputPath;
    var evidencePath = 'build/fr4/fr4_migration_evidence.json';
    String? projectId;
    String? confirmation;
    final collections = <String>[];

    for (final arg in args) {
      if (arg == '--help' || arg == '-h') {
        help = true;
      } else if (arg == '--apply') {
        apply = true;
      } else if (arg.startsWith('--input=')) {
        inputPath = arg.substring('--input='.length);
      } else if (arg.startsWith('--evidence=')) {
        evidencePath = arg.substring('--evidence='.length);
      } else if (arg.startsWith('--firestore-project=')) {
        projectId = arg.substring('--firestore-project='.length);
      } else if (arg.startsWith('--collection=')) {
        collections.add(arg.substring('--collection='.length));
      } else if (arg.startsWith('--confirm=')) {
        confirmation = arg.substring('--confirm='.length);
      } else {
        throw FormatException('Unknown FR4 argument: $arg');
      }
    }

    if (!help && inputPath == null && projectId == null) {
      throw const FormatException(
        'Use --input=<json> or --firestore-project=<project-id>.',
      );
    }
    if (inputPath != null && projectId != null) {
      throw const FormatException(
        'Choose either local input or Firestore REST extraction, not both.',
      );
    }

    return _Arguments(
      help: help,
      apply: apply,
      inputPath: inputPath,
      evidencePath: evidencePath,
      firestoreProjectId: projectId,
      collections: List<String>.unmodifiable(collections),
      confirmation: confirmation,
    );
  }
}

Future<void> _writeEvidence(
  String path,
  Map<String, dynamic> report,
) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(report),
    flush: true,
  );
}

const _usage = '''
CSP11 Phase FR4 deterministic Firestore-to-Supabase migration tool

Plan from a fixture/export:
  dart run tool/fr4_migration/fr4_migrate.dart \
    --input=test/fixtures/fr4/source_documents.json

Plan directly from Firestore REST:
  GOOGLE_OAUTH_ACCESS_TOKEN=... dart run \
    tool/fr4_migration/fr4_migrate.dart \
    --firestore-project=<firebase-project-id>

Apply to Supabase shadow tables:
  SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... \
  dart run tool/fr4_migration/fr4_migrate.dart \
    --input=<validated-export.json> \
    --apply --confirm=FR4_SHADOW_ONLY

FR4 never changes learner runtime routing. Default behavior is plan-only.
''';
