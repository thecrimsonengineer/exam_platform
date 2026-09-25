import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

const String kLabPublishedChunkedFirestoreSchemaVersion =
    'csp11.lab.published_repository.chunked.v2';
const String kLabPublishedPayloadSchemaVersion =
    'csp11.lab.published_payload.v1';
const String kLabPublishedPayloadChunkSchemaVersion =
    'csp11.lab.published_payload_chunk.v1';
const String kLabPublishedPayloadEncoding = 'gzip+base64';
const int kLabPublishedPayloadChunkBytes = 480 * 1024;
const int kLabPublishedPayloadMaxChunksPerVersion = 450;

const List<String> kLabPublishedPayloadFieldNames = <String>[
  'publishedJson',
  'qualityEvidenceJson',
  'exhaustiveRouteEvidenceJson',
  'publishEvidenceJson',
];

class LabPublishedPayloadException implements Exception {
  const LabPublishedPayloadException(this.message);

  final String message;

  @override
  String toString() => 'LabPublishedPayloadException: ' + message;
}

class LabPublishedPayloadFieldManifest {
  const LabPublishedPayloadFieldManifest({
    required this.fieldName,
    required this.encoding,
    required this.chunkCount,
    required this.uncompressedByteLength,
    required this.compressedByteLength,
    required this.payloadFingerprint,
  });

  factory LabPublishedPayloadFieldManifest.fromJson(
    Map<String, Object?> json,
  ) {
    final chunkCount = json['chunkCount'];
    final uncompressedByteLength = json['uncompressedByteLength'];
    final compressedByteLength = json['compressedByteLength'];
    if (chunkCount is! int ||
        uncompressedByteLength is! int ||
        compressedByteLength is! int) {
      throw const LabPublishedPayloadException(
        'Published payload manifest requires integer size metadata.',
      );
    }
    return LabPublishedPayloadFieldManifest(
      fieldName: json['fieldName']?.toString() ?? '',
      encoding: json['encoding']?.toString() ?? '',
      chunkCount: chunkCount,
      uncompressedByteLength: uncompressedByteLength,
      compressedByteLength: compressedByteLength,
      payloadFingerprint: json['payloadFingerprint']?.toString() ?? '',
    );
  }

  final String fieldName;
  final String encoding;
  final int chunkCount;
  final int uncompressedByteLength;
  final int compressedByteLength;
  final String payloadFingerprint;

  Map<String, Object?> toJson() => <String, Object?>{
    'fieldName': fieldName,
    'encoding': encoding,
    'chunkCount': chunkCount,
    'uncompressedByteLength': uncompressedByteLength,
    'compressedByteLength': compressedByteLength,
    'payloadFingerprint': payloadFingerprint,
  };
}

class LabPublishedPayloadChunk {
  const LabPublishedPayloadChunk({
    required this.fieldName,
    required this.chunkIndex,
    required this.chunkCount,
    required this.payloadFingerprint,
    required this.chunkFingerprint,
    required this.dataBase64,
  });

  factory LabPublishedPayloadChunk.fromJson(Map<String, Object?> json) {
    final chunkIndex = json['chunkIndex'];
    final chunkCount = json['chunkCount'];
    if (chunkIndex is! int || chunkCount is! int) {
      throw const LabPublishedPayloadException(
        'Published payload chunk requires integer index metadata.',
      );
    }
    return LabPublishedPayloadChunk(
      fieldName: json['fieldName']?.toString() ?? '',
      chunkIndex: chunkIndex,
      chunkCount: chunkCount,
      payloadFingerprint: json['payloadFingerprint']?.toString() ?? '',
      chunkFingerprint: json['chunkFingerprint']?.toString() ?? '',
      dataBase64: json['dataBase64']?.toString() ?? '',
    );
  }

  final String fieldName;
  final int chunkIndex;
  final int chunkCount;
  final String payloadFingerprint;
  final String chunkFingerprint;
  final String dataBase64;

  String get documentId =>
      fieldName + '__' + chunkIndex.toString().padLeft(4, '0');

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': kLabPublishedPayloadChunkSchemaVersion,
    'fieldName': fieldName,
    'chunkIndex': chunkIndex,
    'chunkCount': chunkCount,
    'payloadFingerprint': payloadFingerprint,
    'chunkFingerprint': chunkFingerprint,
    'dataBase64': dataBase64,
  };
}

class LabPublishedPayloadBundle {
  LabPublishedPayloadBundle({
    required Map<String, LabPublishedPayloadFieldManifest> fields,
    required Iterable<LabPublishedPayloadChunk> chunks,
  }) : fields = Map<String, LabPublishedPayloadFieldManifest>.unmodifiable(
         fields,
       ),
       chunks = List<LabPublishedPayloadChunk>.unmodifiable(chunks);

  final Map<String, LabPublishedPayloadFieldManifest> fields;
  final List<LabPublishedPayloadChunk> chunks;

  Map<String, Object?> get manifestJson => <String, Object?>{
    'schemaVersion': kLabPublishedPayloadSchemaVersion,
    'encoding': kLabPublishedPayloadEncoding,
    'fields': <String, Object?>{
      for (final entry in fields.entries) entry.key: entry.value.toJson(),
    },
  };
}

class LabPublishedPayloadChunkCodec {
  const LabPublishedPayloadChunkCodec();

  LabPublishedPayloadBundle encode(Map<String, String> payloadFields) {
    if (payloadFields.keys.toSet().difference(
          kLabPublishedPayloadFieldNames.toSet(),
        ).isNotEmpty ||
        kLabPublishedPayloadFieldNames.any(
          (field) => !payloadFields.containsKey(field),
        )) {
      throw const LabPublishedPayloadException(
        'Published payload requires exactly the frozen four payload fields.',
      );
    }

    final manifests = <String, LabPublishedPayloadFieldManifest>{};
    final chunks = <LabPublishedPayloadChunk>[];

    for (final fieldName in kLabPublishedPayloadFieldNames) {
      final source = payloadFields[fieldName]!;
      final raw = utf8.encode(source);
      final compressed = GZipEncoder().encode(raw);
      if (compressed.isEmpty) {
        throw LabPublishedPayloadException(
          'Compression produced no bytes for ' + fieldName + '.',
        );
      }

      final payloadFingerprint = sha256.convert(raw).toString();
      final parts = <List<int>>[];
      for (var offset = 0;
          offset < compressed.length;
          offset += kLabPublishedPayloadChunkBytes) {
        final end =
            offset + kLabPublishedPayloadChunkBytes < compressed.length
            ? offset + kLabPublishedPayloadChunkBytes
            : compressed.length;
        parts.add(compressed.sublist(offset, end));
      }
      if (parts.isEmpty) {
        parts.add(<int>[]);
      }

      manifests[fieldName] = LabPublishedPayloadFieldManifest(
        fieldName: fieldName,
        encoding: kLabPublishedPayloadEncoding,
        chunkCount: parts.length,
        uncompressedByteLength: raw.length,
        compressedByteLength: compressed.length,
        payloadFingerprint: payloadFingerprint,
      );

      for (var index = 0; index < parts.length; index++) {
        final part = parts[index];
        chunks.add(
          LabPublishedPayloadChunk(
            fieldName: fieldName,
            chunkIndex: index,
            chunkCount: parts.length,
            payloadFingerprint: payloadFingerprint,
            chunkFingerprint: sha256.convert(part).toString(),
            dataBase64: base64Encode(part),
          ),
        );
      }
    }

    if (chunks.length > kLabPublishedPayloadMaxChunksPerVersion) {
      throw LabPublishedPayloadException(
        'Published payload requires ' +
            chunks.length.toString() +
            ' chunks, above the frozen per-version limit of ' +
            kLabPublishedPayloadMaxChunksPerVersion.toString() +
            '.',
      );
    }

    return LabPublishedPayloadBundle(fields: manifests, chunks: chunks);
  }

  Map<String, String> decode({
    required Map<String, Object?> manifestJson,
    required Iterable<Map<String, Object?>> chunkJson,
  }) {
    if (manifestJson['schemaVersion'] != kLabPublishedPayloadSchemaVersion ||
        manifestJson['encoding'] != kLabPublishedPayloadEncoding) {
      throw const LabPublishedPayloadException(
        'Unsupported published payload manifest.',
      );
    }

    final rawFields = manifestJson['fields'];
    if (rawFields is! Map) {
      throw const LabPublishedPayloadException(
        'Published payload manifest requires a fields map.',
      );
    }

    final manifests = <String, LabPublishedPayloadFieldManifest>{};
    for (final fieldName in kLabPublishedPayloadFieldNames) {
      final rawManifest = rawFields[fieldName];
      if (rawManifest is! Map) {
        throw LabPublishedPayloadException(
          'Published payload manifest is missing ' + fieldName + '.',
        );
      }
      final manifest = LabPublishedPayloadFieldManifest.fromJson(
        rawManifest.cast<String, Object?>(),
      );
      if (manifest.fieldName != fieldName ||
          manifest.encoding != kLabPublishedPayloadEncoding ||
          manifest.chunkCount <= 0 ||
          manifest.payloadFingerprint.isEmpty) {
        throw LabPublishedPayloadException(
          'Published payload manifest is invalid for ' + fieldName + '.',
        );
      }
      manifests[fieldName] = manifest;
    }

    final chunksByField = <String, List<LabPublishedPayloadChunk>>{
      for (final fieldName in kLabPublishedPayloadFieldNames)
        fieldName: <LabPublishedPayloadChunk>[],
    };
    for (final raw in chunkJson) {
      if (raw['schemaVersion'] != kLabPublishedPayloadChunkSchemaVersion) {
        throw const LabPublishedPayloadException(
          'Unsupported published payload chunk schema.',
        );
      }
      final chunk = LabPublishedPayloadChunk.fromJson(raw);
      final bucket = chunksByField[chunk.fieldName];
      if (bucket == null) {
        throw LabPublishedPayloadException(
          'Published payload chunk references unsupported field ' +
              chunk.fieldName +
              '.',
        );
      }
      bucket.add(chunk);
    }

    final decoded = <String, String>{};
    for (final fieldName in kLabPublishedPayloadFieldNames) {
      final manifest = manifests[fieldName]!;
      final chunks = chunksByField[fieldName]!
        ..sort((left, right) => left.chunkIndex.compareTo(right.chunkIndex));
      if (chunks.length != manifest.chunkCount) {
        throw LabPublishedPayloadException(
          'Published payload chunk count mismatch for ' + fieldName + '.',
        );
      }

      final compressed = <int>[];
      for (var index = 0; index < chunks.length; index++) {
        final chunk = chunks[index];
        if (chunk.chunkIndex != index ||
            chunk.chunkCount != manifest.chunkCount ||
            chunk.payloadFingerprint != manifest.payloadFingerprint) {
          throw LabPublishedPayloadException(
            'Published payload chunk metadata mismatch for ' + fieldName + '.',
          );
        }
        late final List<int> bytes;
        try {
          bytes = base64Decode(chunk.dataBase64);
        } on FormatException {
          throw LabPublishedPayloadException(
            'Published payload chunk encoding is invalid for ' +
                fieldName +
                '.',
          );
        }
        if (sha256.convert(bytes).toString() != chunk.chunkFingerprint) {
          throw LabPublishedPayloadException(
            'Published payload chunk fingerprint mismatch for ' +
                fieldName +
                '.',
          );
        }
        compressed.addAll(bytes);
      }

      if (compressed.length != manifest.compressedByteLength) {
        throw LabPublishedPayloadException(
          'Published payload compressed size mismatch for ' + fieldName + '.',
        );
      }
      final raw = GZipDecoder().decodeBytes(compressed);
      if (raw.length != manifest.uncompressedByteLength ||
          sha256.convert(raw).toString() != manifest.payloadFingerprint) {
        throw LabPublishedPayloadException(
          'Published payload fingerprint mismatch for ' + fieldName + '.',
        );
      }
      decoded[fieldName] = utf8.decode(raw);
    }

    return Map<String, String>.unmodifiable(decoded);
  }
}
