import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'fcc_flashcard_publish_core.dart';

Future<void> main(List<String> args) async {
  final options = _Arguments.parse(args);

  if (options.help) {
    stdout.writeln(_usage);
    return;
  }

  if (options.preflight == options.publish) {
    throw StateError(
      'FCC remote mode requires exactly one of --preflight or --publish.',
    );
  }

  if (options.publish && options.confirmation != 'FCC_PUBLISH_FCP12') {
    stderr.writeln(
      'FCC publish blocked. Pass --confirm=FCC_PUBLISH_FCP12 explicitly.',
    );
    exitCode = 3;
    return;
  }

  final config = _SupabaseServerConfig.fromEnvironment();
  final client = _SupabaseFccClient(config);
  final packageRows = await client.fetchAll(
    'published_packages',
    query: const <String, String>{'package_kind': 'eq.flashcards'},
  );

  final plan = const FccFlashcardPackageBuilder().build(
    sources: loadFccFrozenFcp12Sources(),
    existingPackageRows: packageRows,
  );

  _validateNoUnexpectedCurrentRows(plan, packageRows);

  final bucket = await client.getBucket(fccBucketId);
  if (!bucket.exists || bucket.isPublic) {
    await _writeEvidence(options.evidencePath, <String, dynamic>{
      ...plan.toEvidenceJson(),
      'publishRequested': options.publish,
      'credentialKind': config.credentialKind,
      'bucketExists': bucket.exists,
      'bucketPrivate': bucket.exists && !bucket.isPublic,
      'readyToPublish': false,
      'blocker': bucket.exists
          ? 'published package bucket is public'
          : 'published package bucket is missing',
    });
    stderr.writeln('FCC FAIL-CLOSED: private package bucket is unavailable.');
    exitCode = 4;
    return;
  }

  if (options.preflight) {
    await _writeEvidence(options.evidencePath, <String, dynamic>{
      ...plan.toEvidenceJson(),
      'publishRequested': false,
      'credentialKind': config.credentialKind,
      'bucketExists': true,
      'bucketPrivate': true,
      'completePublication': false,
    });
    stdout.writeln(
      'FCC PREFLIGHT PASS: ${plan.packageCount} packages / '
      '${plan.cardCount} cards are ready.',
    );
    return;
  }

  final publishedAt = DateTime.now().toUtc().toIso8601String();
  for (final package in plan.packages) {
    await client.publishFlashcardPackage(
      package,
      publishedAt: publishedAt,
    );
  }

  final verifiedRows = await client.fetchAll(
    'published_packages',
    query: const <String, String>{'package_kind': 'eq.flashcards'},
  );
  _verifyDatabaseState(plan, verifiedRows);

  await _writeEvidence(options.evidencePath, <String, dynamic>{
    ...plan.toEvidenceJson(),
    'publishRequested': true,
    'credentialKind': config.credentialKind,
    'bucketExists': true,
    'bucketPrivate': true,
    'publishedAt': publishedAt,
    'completePublication': true,
  });

  stdout.writeln(
    'FCC PUBLISH PASS: ${plan.packageCount} immutable packages / '
    '${plan.cardCount} cards verified.',
  );
}

Map<String, dynamic> _packageCommitPayload(
  FccPlannedFlashcardPackage package,
) => <String, dynamic>{
  'kind': 'flashcards',
  'version': package.version,
  'domainId': package.artifact.domainId,
  'storageBucket': fccBucketId,
  'storagePath': package.storagePath,
  'checksumSha256': package.artifact.checksumSha256,
  'compressedBytes': package.artifact.compressedByteCount,
  'itemCount': package.artifact.cardCount,
  'metadata': <String, dynamic>{
    'phase': 'FCC-1',
    'deckId': package.artifact.deckId,
    'sourceFcp1Sha': fccSourceFcp1Sha,
    'sourceFcp2Sha': fccSourceFcp2Sha,
    'uncompressedChecksumSha256': package.artifact.uncompressedChecksumSha256,
  },
};

void _validateNoUnexpectedCurrentRows(
  FccFlashcardPublicationPlan plan,
  List<Map<String, dynamic>> packageRows,
) {
  final expected = plan.packages.map((item) => item.competencyId).toSet();
  final unexpected =
      packageRows
          .where((row) => row['is_current'] == true)
          .map((row) => row['package_key']?.toString() ?? '')
          .where((key) => key.isNotEmpty && !expected.contains(key))
          .toList()
        ..sort();

  if (unexpected.isNotEmpty) {
    throw StateError(
      'FCC refuses destructive cleanup of unexpected current Flashcards: '
      '$unexpected',
    );
  }
}

void _verifyDatabaseState(
  FccFlashcardPublicationPlan plan,
  List<Map<String, dynamic>> rows,
) {
  final current = <String, Map<String, dynamic>>{};

  for (final row in rows) {
    if (row['package_kind']?.toString() != 'flashcards' ||
        row['is_current'] != true) {
      continue;
    }

    final key = row['package_key']?.toString() ?? '';
    if (key.isEmpty || current.containsKey(key)) {
      throw StateError('FCC current package identity is invalid: $key');
    }
    current[key] = row;
  }

  if (current.length != plan.packageCount) {
    throw StateError(
      'FCC current package count mismatch: '
      '${current.length} vs ${plan.packageCount}.',
    );
  }

  for (final package in plan.packages) {
    final row = current[package.competencyId];
    if (row == null ||
        row['version']?.toString() != package.version.toString() ||
        row['checksum_sha256']?.toString() != package.artifact.checksumSha256 ||
        row['storage_path']?.toString() != package.storagePath ||
        row['item_count']?.toString() !=
            package.artifact.cardCount.toString()) {
      throw StateError(
        'FCC current package verification failed for '
        '${package.competencyId}.',
      );
    }
  }
}

Future<void> _verifyObjects(
  _SupabaseFccClient client,
  FccFlashcardPublicationPlan plan,
) async {
  for (final package in plan.packages) {
    final downloaded = await client.downloadObject(
      fccBucketId,
      package.storagePath,
    );
    if (downloaded.statusCode != 200 ||
        sha256.convert(downloaded.bytes).toString() !=
            package.artifact.checksumSha256) {
      throw StateError(
        'FCC object verification failed for ${package.storagePath}.',
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
    final legacy =
        Platform.environment['SUPABASE_SERVICE_ROLE_KEY']?.trim() ?? '';

    if (baseUrl.isEmpty) {
      throw StateError('FCC requires SUPABASE_URL.');
    }
    if (secretKey.isNotEmpty) {
      return _SupabaseServerConfig(
        baseUrl: baseUrl,
        apiKey: secretKey,
        credentialKind: 'secret_key',
      );
    }
    if (legacy.isNotEmpty) {
      return _SupabaseServerConfig(
        baseUrl: baseUrl,
        apiKey: legacy,
        credentialKind: 'legacy_service_role',
      );
    }
    throw StateError('FCC requires SUPABASE_SECRET_KEY.');
  }
}

class _SupabaseFccClient {
  _SupabaseFccClient(_SupabaseServerConfig config)
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
      final response = await _jsonRequest(
        'GET',
        _restUri(table, <String, String>{
          'select': '*',
          ...query,
          'limit': '$pageSize',
          'offset': '$offset',
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
          'FCC Supabase fetch failed for $table '
          '(${response.statusCode}): ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw StateError('FCC table $table did not return a list.');
      }
      for (final item in decoded) {
        if (item is! Map) {
          throw StateError('FCC table $table returned a non-object.');
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
    if (response.statusCode == 404) {
      return const _BucketState(exists: false, isPublic: false);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'FCC bucket lookup failed: HTTP ${response.statusCode}.',
      );
    }
    final decoded = jsonDecode(utf8.decode(response.bytes));
    if (decoded is! Map) {
      throw StateError('FCC bucket response must be an object.');
    }
    return _BucketState(
      exists: true,
      isPublic: Map<String, dynamic>.from(decoded)['public'] == true,
    );
  }

  Future<void> publishFlashcardPackage(
    FccPlannedFlashcardPackage package, {
    required String publishedAt,
  }) async {
    final response = await _jsonRequest(
      'POST',
      _functionUri('fcc-flashcard-publisher'),
      body: <String, dynamic>{
        'competencyId': package.competencyId,
        'domainId': package.artifact.domainId,
        'deckId': package.artifact.deckId,
        'version': package.version,
        'storagePath': package.storagePath,
        'checksumSha256': package.artifact.checksumSha256,
        'uncompressedChecksumSha256':
            package.artifact.uncompressedChecksumSha256,
        'compressedBytes': package.artifact.compressedByteCount,
        'itemCount': package.artifact.cardCount,
        'publishedAt': publishedAt,
        'payloadBase64': base64Encode(package.artifact.compressedBytes),
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'FCC server-side package publication failed for '
        '${package.competencyId} (${response.statusCode}): '
        '${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map ||
        decoded['complete'] != true ||
        decoded['competencyId']?.toString() != package.competencyId ||
        decoded['checksumSha256']?.toString() !=
            package.artifact.checksumSha256) {
      throw StateError(
        'FCC server-side package verification failed for '
        '${package.competencyId}.',
      );
    }
  }

  Future<void> ensureImmutableObject(FccPlannedFlashcardPackage package) async {
    final existing = await downloadObject(fccBucketId, package.storagePath);

    if (existing.statusCode == 200) {
      if (sha256.convert(existing.bytes).toString() !=
          package.artifact.checksumSha256) {
        throw StateError(
          'FCC immutable object collision at ${package.storagePath}.',
        );
      }
      return;
    }

    if (existing.statusCode != 404) {
      throw StateError(
        'FCC object preflight failed for ${package.storagePath}: '
        'HTTP ${existing.statusCode}.',
      );
    }

    if (package.reusesExistingPackage) {
      throw StateError(
        'FCC registered package object is missing: ${package.storagePath}.',
      );
    }

    final response = await _byteRequest(
      'POST',
      _storageUri(<String>[
        'object',
        fccBucketId,
        ...package.storagePath.split('/'),
      ]),
      bytes: package.artifact.compressedBytes,
      contentType: 'application/gzip',
      extraHeaders: const <String, String>{'x-upsert': 'false'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'FCC immutable upload failed for ${package.storagePath}: '
        'HTTP ${response.statusCode}.',
      );
    }

    final verified = await downloadObject(fccBucketId, package.storagePath);
    if (verified.statusCode != 200 ||
        sha256.convert(verified.bytes).toString() !=
            package.artifact.checksumSha256) {
      throw StateError(
        'FCC upload verification failed for ${package.storagePath}.',
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

  Future<void> commitFlashcardPublication(
    FccPlannedFlashcardPackage package, {
    required String publishedAt,
  }) async {
    final response = await _jsonRequest(
      'POST',
      _rpcUri('fcc_commit_flashcard_publication'),
      body: <String, dynamic>{
        'p_payload': <String, dynamic>{
          'competencyId': package.competencyId,
          'publishedAt': publishedAt,
          'flashcards': _packageCommitPayload(package),
        },
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'FCC atomic publication commit failed '
        '(${response.statusCode}): ${response.body}',
      );
    }
  }

  Uri _functionUri(String functionName) => baseUri.replace(
    pathSegments: <String>[
      ...baseUri.pathSegments.where((segment) => segment.isNotEmpty),
      'functions',
      'v1',
      functionName,
    ],
  );

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
  }) async {
    final response = await _byteRequest(
      method,
      uri,
      bytes: body == null ? null : utf8.encode(jsonEncode(body)),
      contentType: body == null ? null : 'application/json',
    );
    return _JsonHttpResult(
      statusCode: response.statusCode,
      body: utf8.decode(response.bytes, allowMalformed: true),
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

      final isStorage = uri.path.contains('/storage/v1/');
      if (legacyJwt || isStorage) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
      }

      request.headers.set(HttpHeaders.userAgentHeader, 'csp11-fcc-publisher/1');
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
    required this.preflight,
    required this.publish,
    required this.confirmation,
    required this.evidencePath,
    required this.help,
  });

  final bool preflight;
  final bool publish;
  final String confirmation;
  final String evidencePath;
  final bool help;

  factory _Arguments.parse(List<String> args) {
    var preflight = false;
    var publish = false;
    var confirmation = '';
    var evidencePath = 'build/fcc-fcp12/evidence.json';
    var help = false;

    for (final arg in args) {
      if (arg == '--preflight') {
        preflight = true;
      } else if (arg == '--publish') {
        publish = true;
      } else if (arg == '--help' || arg == '-h') {
        help = true;
      } else if (arg.startsWith('--confirm=')) {
        confirmation = arg.substring('--confirm='.length);
      } else if (arg.startsWith('--evidence=')) {
        evidencePath = arg.substring('--evidence='.length);
      } else {
        throw ArgumentError('Unknown FCC argument: $arg');
      }
    }

    return _Arguments(
      preflight: preflight,
      publish: publish,
      confirmation: confirmation,
      evidencePath: evidencePath,
      help: help,
    );
  }
}

Future<void> _writeEvidence(String path, Map<String, dynamic> evidence) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(evidence),
    flush: true,
  );
}

const String _usage = '''
CSP11 FCC-1 FCP1/FCP2 Flashcard publisher

Read-only preflight:
  SUPABASE_URL=... SUPABASE_SECRET_KEY=... \\
  dart run tool/fcc_flashcard_publish/fcc_flashcard_publish.dart \\
    --preflight --evidence=build/fcc-fcp12/preflight.json

One-shot publication:
  SUPABASE_URL=... SUPABASE_SECRET_KEY=... \\
  dart run tool/fcc_flashcard_publish/fcc_flashcard_publish.dart \\
    --publish --confirm=FCC_PUBLISH_FCP12 \\
    --evidence=build/fcc-fcp12/publication.json
''';
