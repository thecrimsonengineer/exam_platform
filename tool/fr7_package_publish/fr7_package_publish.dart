import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'fr7_package_publish_core.dart';

Future<void> main(List<String> args) async {
  final options = _Arguments.parse(args);

  if (options.help) {
    stdout.writeln(_usage);
    return;
  }

  if (options.sourcePath != null) {
    if (options.preflight || options.publish) {
      throw StateError('FR7 local fixture mode is read-only.');
    }

    final fixture = _readJsonObject(options.sourcePath!);
    final plan = const Fr7PackageBuilder().build(
      contentRows: _mapList(fixture['content_versions'], 'content_versions'),
      questionRows: _mapList(fixture['questions'], 'questions'),
      existingPackageRows: _mapList(
        fixture['published_packages'] ?? const <dynamic>[],
        'published_packages',
      ),
    );

    if (options.packageDir != null) {
      await _writePackages(plan, options.packageDir!);
    }

    await _writeEvidence(options.evidencePath, <String, dynamic>{
      ...plan.toEvidenceJson(),
      'sourceMode': 'local-fixture',
      'publishRequested': false,
    });
    stdout.writeln(
      'FR7 FIXTURE PACKAGE PASS: ${plan.competencies.length} competencies, '
      '${plan.packages.length} deterministic package(s).',
    );
    return;
  }

  if (options.preflight == options.publish) {
    throw StateError(
      'FR7 remote mode requires exactly one of --preflight or --publish.',
    );
  }

  if (options.publish && options.confirmation != 'FR7_PUBLISH_PACKAGES') {
    stderr.writeln(
      'FR7 publish is blocked. Pass '
      '--confirm=FR7_PUBLISH_PACKAGES explicitly.',
    );
    exitCode = 3;
    return;
  }

  final config = _SupabaseServerConfig.fromEnvironment();
  final client = _SupabaseFr7Client(config);

  final contentRows = await client.fetchAll(
    'content_versions',
    query: const <String, String>{'status': 'eq.published'},
  );
  final questionRows = await client.fetchAll(
    'questions',
    query: const <String, String>{'status': 'eq.published'},
  );
  final packageRows = await client.fetchAll('published_packages');
  final catalogRows = await client.fetchAll('published_catalog');

  final plan = const Fr7PackageBuilder().build(
    contentRows: contentRows,
    questionRows: questionRows,
    existingPackageRows: packageRows,
  );

  _validateNoStaleCurrentRows(plan, packageRows, catalogRows);

  final bucket = await client.getBucket(fr7BucketId);
  if (bucket.exists && bucket.isPublic) {
    await _writeEvidence(options.evidencePath, <String, dynamic>{
      ...plan.toEvidenceJson(),
      'sourceMode': 'supabase-shadow',
      'publishRequested': options.publish,
      'credentialKind': config.credentialKind,
      'bucketExists': true,
      'bucketPrivate': false,
      'readyToPublish': false,
      'blocker': 'published package bucket is public',
    });
    stderr.writeln('FR7 FAIL-CLOSED: published package bucket is public.');
    exitCode = 4;
    return;
  }

  if (options.preflight) {
    await _writeEvidence(options.evidencePath, <String, dynamic>{
      ...plan.toEvidenceJson(),
      'sourceMode': 'supabase-shadow',
      'publishRequested': false,
      'credentialKind': config.credentialKind,
      'bucketExists': bucket.exists,
      'bucketPrivate': !bucket.exists || !bucket.isPublic,
      'catalogRowCount': catalogRows.length,
    });
    stdout.writeln(
      'FR7 PREFLIGHT PASS: ${plan.competencies.length} competencies and '
      '${plan.packages.length} package(s) are ready.',
    );
    return;
  }

  if (!bucket.exists) {
    await client.createPrivateBucket(fr7BucketId);
  }

  final publicationTimestamp = DateTime.now().toUtc().toIso8601String();

  for (final package in plan.packages) {
    await client.ensureImmutableObject(package);
  }

  // Storage bytes are immutable and verified before any database pointer moves.
  await _verifyObjects(client, plan);

  final existingCatalog = <String, Map<String, dynamic>>{
    for (final row in catalogRows)
      (row['competency_id']?.toString() ?? ''): row,
  };
  var catalogUpdatedCount = 0;

  for (final competency in plan.competencies) {
    final expected = _catalogPointer(
      competency,
      publishedAt: publicationTimestamp,
    );
    if (!_catalogPointerMatches(
      existingCatalog[competency.competencyId],
      expected,
    )) {
      catalogUpdatedCount++;
    }

    // Package registration, current-version selection and published_catalog
    // switch happen in one PostgreSQL transaction. The catalogue write is
    // last inside the RPC.
    await client.commitCompetencyPublication(
      competency,
      publishedAt: publicationTimestamp,
    );
  }

  final verifiedPackages = await client.fetchAll('published_packages');
  final verifiedCatalog = await client.fetchAll('published_catalog');
  _verifyDatabaseState(plan, verifiedPackages, verifiedCatalog);
  await _verifyObjects(client, plan);

  await _writeEvidence(options.evidencePath, <String, dynamic>{
    ...plan.toEvidenceJson(),
    'sourceMode': 'supabase-shadow',
    'publishRequested': true,
    'credentialKind': config.credentialKind,
    'bucketExists': true,
    'bucketPrivate': true,
    'catalogUpdatedCount': catalogUpdatedCount,
    'completePublication': true,
  });

  stdout.writeln(
    'FR7 PUBLISH PASS: ${plan.packages.length} immutable package(s) verified; '
    'catalogue pointers are current.',
  );
}

void _validateNoStaleCurrentRows(
  Fr7PublicationPlan plan,
  List<Map<String, dynamic>> packageRows,
  List<Map<String, dynamic>> catalogRows,
) {
  final competencies = plan.competencies
      .map((item) => item.competencyId)
      .toSet();

  final staleCurrentPackages = <String>[];
  for (final row in packageRows) {
    if (row['is_current'] != true) continue;
    final kind = row['package_kind']?.toString() ?? '';
    if (!fr7SupportedKinds.contains(kind)) continue;
    final key = row['package_key']?.toString() ?? '';
    if (!competencies.contains(key)) {
      staleCurrentPackages.add('$kind/$key');
    }
  }

  final staleCatalog = <String>[];
  for (final row in catalogRows) {
    if (row['active'] != true) continue;
    final key = row['competency_id']?.toString() ?? '';
    if (!competencies.contains(key)) staleCatalog.add(key);
  }

  if (staleCurrentPackages.isNotEmpty || staleCatalog.isNotEmpty) {
    staleCurrentPackages.sort();
    staleCatalog.sort();
    throw StateError(
      'FR7 refuses destructive cleanup. '
      'staleCurrentPackages=$staleCurrentPackages staleCatalog=$staleCatalog',
    );
  }
}

Map<String, dynamic> _packageCommitPayload(
  Fr7PlannedPackage package,
) => <String, dynamic>{
  'kind': package.kind,
  'version': package.version,
  'storageBucket': fr7BucketId,
  'storagePath': package.storagePath,
  'checksumSha256': package.artifact.checksumSha256,
  'compressedBytes': package.artifact.compressedByteCount,
  'itemCount': package.artifact.itemCount,
  'metadata': <String, dynamic>{
    'phase': 'FR7',
    'uncompressedChecksumSha256': package.artifact.uncompressedChecksumSha256,
    ...package.artifact.sourceMetadata,
  },
};

Map<String, dynamic> _catalogPointer(
  Fr7PlannedCompetency competency, {
  required String publishedAt,
}) => <String, dynamic>{
  'competency_id': competency.competencyId,
  'content_version': competency.content.version,
  'content_checksum_sha256': competency.content.artifact.checksumSha256,
  'content_object_path': competency.content.storagePath,
  'content_size_bytes': competency.content.artifact.compressedByteCount,
  'question_version': competency.questions.version,
  'question_checksum_sha256': competency.questions.artifact.checksumSha256,
  'question_object_path': competency.questions.storagePath,
  'question_size_bytes': competency.questions.artifact.compressedByteCount,
  'published_question_count': competency.questions.artifact.itemCount,
  'active': true,
  'published_at': publishedAt,
};

bool _catalogPointerMatches(
  Map<String, dynamic>? existing,
  Map<String, dynamic> expected,
) {
  if (existing == null) return false;
  for (final key in const <String>[
    'competency_id',
    'content_version',
    'content_checksum_sha256',
    'content_object_path',
    'content_size_bytes',
    'question_version',
    'question_checksum_sha256',
    'question_object_path',
    'question_size_bytes',
    'published_question_count',
    'active',
  ]) {
    if (existing[key]?.toString() != expected[key]?.toString()) return false;
  }
  return true;
}

void _verifyDatabaseState(
  Fr7PublicationPlan plan,
  List<Map<String, dynamic>> packageRows,
  List<Map<String, dynamic>> catalogRows,
) {
  final current = <String, Map<String, dynamic>>{};
  for (final row in packageRows) {
    if (row['is_current'] != true) continue;
    final kind = row['package_kind']?.toString() ?? '';
    final key = row['package_key']?.toString() ?? '';
    if (!fr7SupportedKinds.contains(kind)) continue;
    final historyKey = '$kind|$key';
    if (current.containsKey(historyKey)) {
      throw StateError('FR7 verification found duplicate current $historyKey.');
    }
    current[historyKey] = row;
  }

  final catalog = <String, Map<String, dynamic>>{
    for (final row in catalogRows)
      if (row['active'] == true) (row['competency_id']?.toString() ?? ''): row,
  };

  for (final competency in plan.competencies) {
    for (final package in <Fr7PlannedPackage>[
      competency.content,
      competency.questions,
    ]) {
      final key = '${package.kind}|${package.competencyId}';
      final row = current[key];
      if (row == null ||
          row['version']?.toString() != package.version.toString() ||
          row['checksum_sha256']?.toString() !=
              package.artifact.checksumSha256 ||
          row['storage_path']?.toString() != package.storagePath) {
        throw StateError('FR7 current package verification failed for $key.');
      }
    }

    final pointer = catalog[competency.competencyId];
    final expected = _catalogPointer(competency, publishedAt: 'ignored');
    if (!_catalogPointerMatches(pointer, expected)) {
      throw StateError(
        'FR7 catalogue verification failed for ${competency.competencyId}.',
      );
    }
  }

  if (catalog.length != plan.competencies.length) {
    throw StateError(
      'FR7 catalogue row count mismatch: ${catalog.length} vs '
      '${plan.competencies.length}.',
    );
  }
}

Future<void> _verifyObjects(
  _SupabaseFr7Client client,
  Fr7PublicationPlan plan,
) async {
  for (final package in plan.packages) {
    final downloaded = await client.downloadObject(
      fr7BucketId,
      package.storagePath,
    );
    if (downloaded.statusCode != 200) {
      throw StateError(
        'FR7 object verification failed for ${package.storagePath}: '
        'HTTP ${downloaded.statusCode}.',
      );
    }
    final checksum = sha256.convert(downloaded.bytes).toString();
    if (checksum != package.artifact.checksumSha256) {
      throw StateError(
        'FR7 object checksum mismatch for ${package.storagePath}.',
      );
    }
  }
}

class _BucketState {
  const _BucketState({required this.exists, required this.isPublic});

  final bool exists;
  final bool isPublic;
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
      throw StateError('FR7 remote mode requires SUPABASE_URL.');
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
      'FR7 remote mode requires SUPABASE_SECRET_KEY. '
      'SUPABASE_SERVICE_ROLE_KEY is accepted only for migration compatibility.',
    );
  }
}

class _SupabaseFr7Client {
  _SupabaseFr7Client(_SupabaseServerConfig config)
    : baseUri = Uri.parse(config.baseUrl),
      apiKey = config.apiKey,
      legacyJwt = config.credentialKind == 'legacy_service_role';

  final Uri baseUri;
  final String apiKey;
  final bool legacyJwt;

  Future<List<Map<String, dynamic>>> fetchAll(
    String table, {
    Map<String, String> query = const <String, String>{},
  }) async {
    const pageSize = 1000;
    final output = <Map<String, dynamic>>[];

    for (var offset = 0; ; offset += pageSize) {
      final uri = _restUri(table, <String, String>{
        'select': '*',
        ...query,
        'limit': '$pageSize',
        'offset': '$offset',
      });
      final response = await _jsonRequest('GET', uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'FR7 Supabase fetch failed for $table '
          '(${response.statusCode}): ${response.body}',
          uri: uri,
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw FormatException('FR7 table "$table" did not return a list.');
      }
      for (final item in decoded) {
        if (item is! Map) {
          throw FormatException('FR7 table "$table" returned a non-object.');
        }
        output.add(Map<String, dynamic>.from(item));
      }
      if (decoded.length < pageSize) break;
    }

    return output;
  }

  Future<_BucketState> getBucket(String bucketId) async {
    final response = await _byteRequest(
      'GET',
      _storageUri(<String>['bucket', bucketId]),
    );
    if (_isStorageNotFound(response, expectedCode: 'NoSuchBucket')) {
      return const _BucketState(exists: false, isPublic: false);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = utf8.decode(response.bytes, allowMalformed: true);
      throw HttpException(
        'FR7 bucket lookup failed (${response.statusCode}): $body',
      );
    }
    final decoded = jsonDecode(utf8.decode(response.bytes));
    if (decoded is! Map) {
      throw const FormatException('FR7 bucket response must be an object.');
    }
    final map = Map<String, dynamic>.from(decoded);
    return _BucketState(exists: true, isPublic: map['public'] == true);
  }

  Future<void> createPrivateBucket(String bucketId) async {
    final response = await _jsonRequest(
      'POST',
      _storageUri(const <String>['bucket']),
      body: <String, dynamic>{
        'id': bucketId,
        'name': bucketId,
        'public': false,
        'file_size_limit': 10 * 1024 * 1024,
        'allowed_mime_types': const <String>[
          'application/gzip',
          'application/octet-stream',
        ],
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'FR7 private bucket creation failed (${response.statusCode}): '
        '${response.body}',
      );
    }

    final verified = await getBucket(bucketId);
    if (!verified.exists || verified.isPublic) {
      throw StateError('FR7 private bucket verification failed.');
    }
  }

  Future<void> ensureImmutableObject(Fr7PlannedPackage package) async {
    final existing = await downloadObject(fr7BucketId, package.storagePath);
    if (existing.statusCode == 200) {
      final checksum = sha256.convert(existing.bytes).toString();
      if (checksum != package.artifact.checksumSha256) {
        throw StateError(
          'FR7 immutable object collision at ${package.storagePath}.',
        );
      }
      return;
    }

    if (!_isStorageNotFound(existing, expectedCode: 'NoSuchKey')) {
      final responseBody = utf8.decode(existing.bytes, allowMalformed: true);
      throw StateError(
        'FR7 object preflight failed for ${package.storagePath}: '
        'HTTP ${existing.statusCode} ${responseBody.trim()}.',
      );
    }

    if (package.reusesExistingPackage) {
      throw StateError(
        'FR7 registered immutable package object is missing: '
        '${package.storagePath}.',
      );
    }

    final response = await _byteRequest(
      'POST',
      _storageUri(<String>[
        'object',
        fr7BucketId,
        ...package.storagePath.split('/'),
      ]),
      bytes: package.artifact.compressedBytes,
      contentType: 'application/gzip',
      extraHeaders: const <String, String>{'x-upsert': 'false'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'FR7 immutable upload failed for ${package.storagePath}: '
        'HTTP ${response.statusCode} ${utf8.decode(response.bytes)}',
      );
    }

    final downloaded = await downloadObject(fr7BucketId, package.storagePath);
    if (downloaded.statusCode != 200 ||
        sha256.convert(downloaded.bytes).toString() !=
            package.artifact.checksumSha256) {
      throw StateError(
        'FR7 upload verification failed for ${package.storagePath}.',
      );
    }
  }

  Future<_ByteHttpResult> downloadObject(String bucketId, String storagePath) =>
      _byteRequest(
        'GET',
        _storageUri(<String>[
          'object',
          'authenticated',
          bucketId,
          ...storagePath.split('/'),
        ]),
      );

  Future<void> commitCompetencyPublication(
    Fr7PlannedCompetency competency, {
    required String publishedAt,
  }) async {
    final uri = _rpcUri('fr7_commit_competency_publication');
    final response = await _jsonRequest(
      'POST',
      uri,
      body: <String, dynamic>{
        'p_payload': <String, dynamic>{
          'competencyId': competency.competencyId,
          'publishedAt': publishedAt,
          'content': _packageCommitPayload(competency.content),
          'questions': _packageCommitPayload(competency.questions),
        },
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'FR7 atomic publication commit failed '
        '(${response.statusCode}): ${response.body}',
        uri: uri,
      );
    }
  }

  Uri _rpcUri(String functionName) => baseUri.replace(
    pathSegments: <String>[
      ...baseUri.pathSegments.where((segment) => segment.isNotEmpty),
      'rest',
      'v1',
      'rpc',
      functionName,
    ],
  );

  Uri _restUri(
    String table, [
    Map<String, String> query = const <String, String>{},
  ]) => baseUri.replace(
    pathSegments: <String>[
      ...baseUri.pathSegments.where((segment) => segment.isNotEmpty),
      'rest',
      'v1',
      table,
    ],
    queryParameters: query.isEmpty ? null : query,
  );

  Uri _storageUri(List<String> segments) => baseUri.replace(
    pathSegments: <String>[
      ...baseUri.pathSegments.where((segment) => segment.isNotEmpty),
      'storage',
      'v1',
      ...segments,
    ],
  );

  Future<_JsonHttpResult> _jsonRequest(
    String method,
    Uri uri, {
    dynamic body,
    String? prefer,
  }) async {
    final response = await _byteRequest(
      method,
      uri,
      bytes: body == null ? null : utf8.encode(jsonEncode(body)),
      contentType: body == null ? null : 'application/json',
      extraHeaders: prefer == null
          ? const <String, String>{}
          : <String, String>{'Prefer': prefer},
    );
    return _JsonHttpResult(
      statusCode: response.statusCode,
      body: utf8.decode(response.bytes),
    );
  }

  Future<_ByteHttpResult> _byteRequest(
    String method,
    Uri uri, {
    List<int>? bytes,
    String? contentType,
    Map<String, String> extraHeaders = const <String, String>{},
  }) async {
    final client = HttpClient();
    try {
      final request = await client.openUrl(method, uri);
      request.headers.set('apikey', apiKey);
      final isStorageRequest = uri.path.contains('/storage/v1/');
      if (legacyJwt || isStorageRequest) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
      }
      request.headers.set(HttpHeaders.userAgentHeader, 'csp11-fr7-publisher/1');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      for (final entry in extraHeaders.entries) {
        request.headers.set(entry.key, entry.value);
      }
      if (contentType != null) {
        request.headers.set(HttpHeaders.contentTypeHeader, contentType);
      }
      if (bytes != null) request.add(bytes);

      final response = await request.close();
      final output = await response.fold<List<int>>(
        <int>[],
        (buffer, chunk) => buffer..addAll(chunk),
      );
      return _ByteHttpResult(
        statusCode: response.statusCode,
        bytes: Uint8List.fromList(output),
      );
    } finally {
      client.close(force: true);
    }
  }
}

bool _isStorageNotFound(
  _ByteHttpResult response, {
  required String expectedCode,
}) {
  if (response.statusCode == 404) return true;

  final body = utf8.decode(response.bytes, allowMalformed: true);
  try {
    final decoded = jsonDecode(body);
    return decoded is Map &&
        decoded['code']?.toString() == expectedCode &&
        decoded['statusCode']?.toString() == '404';
  } on FormatException {
    return false;
  }
}

class _JsonHttpResult {
  const _JsonHttpResult({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

class _ByteHttpResult {
  const _ByteHttpResult({required this.statusCode, required this.bytes});

  final int statusCode;
  final Uint8List bytes;
}

class _Arguments {
  const _Arguments({
    required this.help,
    required this.sourcePath,
    required this.packageDir,
    required this.evidencePath,
    required this.preflight,
    required this.publish,
    required this.confirmation,
  });

  final bool help;
  final String? sourcePath;
  final String? packageDir;
  final String evidencePath;
  final bool preflight;
  final bool publish;
  final String? confirmation;

  static _Arguments parse(List<String> args) {
    var help = false;
    String? sourcePath;
    String? packageDir;
    var evidencePath = 'build/fr7/fr7_package_publish_evidence.json';
    var preflight = false;
    var publish = false;
    String? confirmation;

    for (final arg in args) {
      if (arg == '--help' || arg == '-h') {
        help = true;
      } else if (arg.startsWith('--source=')) {
        sourcePath = arg.substring('--source='.length);
      } else if (arg.startsWith('--package-dir=')) {
        packageDir = arg.substring('--package-dir='.length);
      } else if (arg.startsWith('--evidence=')) {
        evidencePath = arg.substring('--evidence='.length);
      } else if (arg == '--preflight') {
        preflight = true;
      } else if (arg == '--publish') {
        publish = true;
      } else if (arg.startsWith('--confirm=')) {
        confirmation = arg.substring('--confirm='.length);
      } else {
        throw FormatException('Unknown FR7 argument: $arg');
      }
    }

    return _Arguments(
      help: help,
      sourcePath: sourcePath,
      packageDir: packageDir,
      evidencePath: evidencePath,
      preflight: preflight,
      publish: publish,
      confirmation: confirmation,
    );
  }
}

List<Map<String, dynamic>> _mapList(dynamic raw, String label) {
  if (raw is! List) {
    throw FormatException('FR7 fixture "$label" must be a list.');
  }
  return raw
      .map((item) {
        if (item is! Map) {
          throw FormatException('FR7 fixture "$label" contains a non-object.');
        }
        return Map<String, dynamic>.from(item);
      })
      .toList(growable: false);
}

Map<String, dynamic> _readJsonObject(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw StateError('FR7 JSON file does not exist: $path');
  }
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map) {
    throw FormatException('FR7 JSON file "$path" must contain an object.');
  }
  return Map<String, dynamic>.from(decoded);
}

Future<void> _writePackages(Fr7PublicationPlan plan, String rootPath) async {
  for (final package in plan.packages) {
    final file = File('$rootPath/${package.storagePath}');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(package.artifact.compressedBytes, flush: true);
  }
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
CSP11 Phase FR7 immutable package publisher

Local deterministic fixture build:
  dart run tool/fr7_package_publish/fr7_package_publish.dart \\
    --source=test/fixtures/fr7/source_snapshot.json \\
    --package-dir=build/fr7/packages

Remote read-only preflight:
  SUPABASE_URL=... SUPABASE_SECRET_KEY=... \\
  dart run tool/fr7_package_publish/fr7_package_publish.dart --preflight

Publish immutable packages after explicit confirmation:
  SUPABASE_URL=... SUPABASE_SECRET_KEY=... \\
  dart run tool/fr7_package_publish/fr7_package_publish.dart \\
    --publish --confirm=FR7_PUBLISH_PACKAGES

FR7 never overwrites or deletes Storage objects. Catalogue pointers are updated
only after package upload, checksum verification, registration and current-row
selection have succeeded.
''';
