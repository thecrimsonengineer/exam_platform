import 'dart:convert';
import 'dart:io';

import '../fr4_migration/fr4_migration_core.dart';
import 'fr5_firestore_source_core.dart';

Future<void> main(List<String> args) async {
  final options = _Arguments.parse(args);

  if (options.help) {
    stdout.writeln(_usage);
    return;
  }

  final token = Platform.environment['GOOGLE_OAUTH_ACCESS_TOKEN']?.trim() ?? '';
  if (token.isEmpty) {
    throw StateError(
      'FR5 Firestore source snapshot requires GOOGLE_OAUTH_ACCESS_TOKEN.',
    );
  }

  final documents = await _loadFirestoreDocuments(
    projectId: options.firestoreProjectId,
    token: token,
  );

  final selection = const Fr5CanonicalSourceSelector().select(documents);
  await _writeJson(options.evidencePath, selection.toJson());

  if (!selection.ready) {
    stderr.writeln(
      'FR5 SOURCE FAIL-CLOSED: ${selection.issues.length} production '
      'source classification issue(s).',
    );
    exitCode = 2;
    return;
  }

  await _writeJson(options.outputPath, <String, dynamic>{
    'schemaVersion': 1,
    'phase': 'FR5',
    'documents': selection.documents
        .map((document) => document.toJson())
        .toList(growable: false),
  });

  stdout.writeln(
    'FR5 SOURCE PASS: ${selection.documents.length} published production '
    'document(s); ${selection.excluded.length} non-published authoring '
    'document(s) excluded.',
  );
}

Future<List<Fr4SourceDocument>> _loadFirestoreDocuments({
  required String projectId,
  required String token,
}) async {
  final collections = fr4SupportedCollections.toList(growable: false)..sort();
  final client = HttpClient();

  try {
    final output = <Fr4SourceDocument>[];

    for (final collection in collections) {
      String? pageToken;
      do {
        final parameters = <String, String>{
          'pageSize': '1000',
          if (pageToken != null && pageToken.isNotEmpty) 'pageToken': pageToken,
        };
        final uri = Uri.https(
          'firestore.googleapis.com',
          '/v1/projects/$projectId/databases/(default)/documents/$collection',
          parameters,
        );
        final map = await _loadFirestorePageWithRetry(
          client: client,
          uri: uri,
          token: token,
          collection: collection,
        );
        final rawDocuments = map['documents'];
        if (rawDocuments is List) {
          for (final rawDocument in rawDocuments) {
            output.add(
              decodeFirestoreRestDocument(
                collection: collection,
                document: rawDocument,
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

Future<Map<String, dynamic>> _loadFirestorePageWithRetry({
  required HttpClient client,
  required Uri uri,
  required String token,
  required String collection,
}) async {
  const retryDelays = <Duration>[
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(seconds: 60),
    Duration(seconds: 120),
  ];

  for (var attempt = 0; ; attempt++) {
    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');

    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final payload = jsonDecode(body);
      if (payload is! Map) {
        throw const FormatException('Firestore response is not an object.');
      }

      return <String, dynamic>{
        for (final entry in payload.entries)
          entry.key.toString(): entry.value,
      };
    }

    if (response.statusCode == 429 && attempt < retryDelays.length) {
      final delay = retryDelays[attempt];
      stderr.writeln(
        'Firestore quota response for $collection. Retrying page in '
        '${delay.inSeconds}s (attempt ${attempt + 2}/'
        '${retryDelays.length + 1}).',
      );
      await Future<void>.delayed(delay);
      continue;
    }

    throw HttpException(
      'Firestore list failed for $collection '
      '(${response.statusCode}): $body',
      uri: uri,
    );
  }
}

Future<void> _writeJson(String path, Map<String, dynamic> value) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(value),
    flush: true,
  );
}

class _Arguments {
  const _Arguments({
    required this.help,
    required this.firestoreProjectId,
    required this.outputPath,
    required this.evidencePath,
  });

  final bool help;
  final String firestoreProjectId;
  final String outputPath;
  final String evidencePath;

  static _Arguments parse(List<String> args) {
    var help = false;
    String? projectId;
    var outputPath = 'build/fr5/production_source.json';
    var evidencePath = 'build/fr5/production_source_selection.json';

    for (final arg in args) {
      if (arg == '--help' || arg == '-h') {
        help = true;
      } else if (arg.startsWith('--firestore-project=')) {
        projectId = arg.substring('--firestore-project='.length).trim();
      } else if (arg.startsWith('--output=')) {
        outputPath = arg.substring('--output='.length);
      } else if (arg.startsWith('--evidence=')) {
        evidencePath = arg.substring('--evidence='.length);
      } else {
        throw FormatException('Unknown FR5 source argument: $arg');
      }
    }

    if (!help && (projectId == null || projectId.isEmpty)) {
      throw const FormatException(
        'Use --firestore-project=<firebase-project-id>.',
      );
    }

    return _Arguments(
      help: help,
      firestoreProjectId: projectId ?? '',
      outputPath: outputPath,
      evidencePath: evidencePath,
    );
  }
}

const _usage = '''
CSP11 Phase FR5 canonical production Firestore source snapshot

GOOGLE_OAUTH_ACCESS_TOKEN=... dart run \
  tool/fr5_shadow_parity/fr5_firestore_source.dart \
  --firestore-project=<firebase-project-id> \
  --output=build/fr5/production_source.json \
  --evidence=build/fr5/production_source_selection.json

This command is read-only against Firestore. It selects only published
production content and questions. Draft, review, validated, and archived
authoring records are excluded from FR5 production migration.
''';
