import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import '../../models/study_content.dart';

class PublishedContentPackageDescriptor {
  const PublishedContentPackageDescriptor({
    required this.competencyId,
    required this.version,
    required this.checksumSha256,
    required this.compressedBytes,
  });

  final String competencyId;
  final int version;
  final String checksumSha256;
  final int compressedBytes;

  factory PublishedContentPackageDescriptor.fromJson(
    Map<String, dynamic> json,
  ) {
    final competencyId = _requiredString(
      json,
      'competencyId',
    ).toLowerCase();

    if (!_competencyPattern.hasMatch(competencyId)) {
      throw const FormatException('Invalid content-package competency ID.');
    }

    final checksum = _requiredString(
      json,
      'contentChecksumSha256',
    ).toLowerCase();

    if (!_sha256Pattern.hasMatch(checksum)) {
      throw const FormatException('Invalid content-package SHA-256.');
    }

    return PublishedContentPackageDescriptor(
      competencyId: competencyId,
      version: _requiredPositiveInt(json, 'contentVersion'),
      checksumSha256: checksum,
      compressedBytes: _requiredNonNegativeInt(json, 'contentSizeBytes'),
    );
  }

  Map<String, dynamic> toKnownRequestJson() => <String, dynamic>{
    'competencyId': competencyId,
    'knownContentVersion': version,
    'knownContentChecksumSha256': checksumSha256,
  };
}

class ContentPackageResolution {
  const ContentPackageResolution({
    required this.descriptor,
    required this.current,
    this.signedUrl,
  });

  final PublishedContentPackageDescriptor descriptor;
  final bool current;
  final Uri? signedUrl;

  factory ContentPackageResolution.fromJson(Map<String, dynamic> json) {
    final descriptor = PublishedContentPackageDescriptor.fromJson(json);
    final current = json['current'];

    if (current is! bool) {
      throw const FormatException(
        'Content-package resolution must include current.',
      );
    }

    final rawSignedUrl = json['signedUrl']?.toString().trim();
    final signedUrl = rawSignedUrl == null || rawSignedUrl.isEmpty
        ? null
        : Uri.tryParse(rawSignedUrl);

    if (current && signedUrl != null) {
      throw const FormatException(
        'A current content package must not include a signed URL.',
      );
    }

    if (!current &&
        (signedUrl == null ||
            !signedUrl.hasScheme ||
            signedUrl.scheme.toLowerCase() != 'https')) {
      throw const FormatException(
        'A changed content package requires a valid HTTPS signed URL.',
      );
    }

    return ContentPackageResolution(
      descriptor: descriptor,
      current: current,
      signedUrl: signedUrl,
    );
  }
}

class VerifiedContentPackage {
  const VerifiedContentPackage({
    required this.descriptor,
    required this.content,
  });

  final PublishedContentPackageDescriptor descriptor;
  final StudyContent content;
}

class ContentPackageDecoder {
  const ContentPackageDecoder();

  VerifiedContentPackage decode({
    required PublishedContentPackageDescriptor descriptor,
    required List<int> compressedBytes,
  }) {
    if (compressedBytes.length != descriptor.compressedBytes) {
      throw const FormatException(
        'Content package compressed byte count does not match metadata.',
      );
    }

    final compressed = Uint8List.fromList(compressedBytes);
    final checksum = sha256.convert(compressed).toString();

    if (checksum != descriptor.checksumSha256) {
      throw const FormatException('Content package SHA-256 mismatch.');
    }

    late final List<int> decodedBytes;

    try {
      decodedBytes = GZipDecoder().decodeBytes(compressed);
    } catch (_) {
      throw const FormatException('Content package gzip decoding failed.');
    }

    late final Object? decodedJson;

    try {
      decodedJson = jsonDecode(utf8.decode(decodedBytes));
    } catch (_) {
      throw const FormatException('Content package JSON decoding failed.');
    }

    if (decodedJson is! Map) {
      throw const FormatException('Content package root must be an object.');
    }

    final envelope = Map<String, dynamic>.from(decodedJson);

    if (_requiredInt(envelope, 'schemaVersion') != 1) {
      throw const FormatException('Unsupported content package schema.');
    }

    if (_requiredString(envelope, 'kind') != 'content') {
      throw const FormatException('Content package kind must be content.');
    }

    if (_requiredString(envelope, 'competencyId').toLowerCase() !=
        descriptor.competencyId) {
      throw const FormatException('Content package competency mismatch.');
    }

    final sourceVersion = _requiredPositiveInt(envelope, 'sourceVersion');
    final rawContent = envelope['content'];

    if (rawContent is! Map) {
      throw const FormatException(
        'Content package content payload must be an object.',
      );
    }

    final contentJson = Map<String, dynamic>.from(rawContent);
    final payloadCompetency = _requiredString(
      contentJson,
      'competencyId',
    ).toLowerCase();

    if (payloadCompetency != descriptor.competencyId) {
      throw const FormatException(
        'Content package contains cross-competency StudyContent.',
      );
    }

    final expectedDomain = descriptor.competencyId.substring(0, 3);
    final payloadDomain = _requiredString(
      contentJson,
      'domainId',
    ).toLowerCase();

    if (payloadDomain != expectedDomain) {
      throw const FormatException('Content package domain mismatch.');
    }

    if (_requiredString(contentJson, 'status').toLowerCase() != 'published') {
      throw const FormatException(
        'Content package contains non-published StudyContent.',
      );
    }

    if (_requiredPositiveInt(contentJson, 'version') != sourceVersion) {
      throw const FormatException(
        'Content package source version does not match StudyContent.',
      );
    }

    final expectedCompetencyNumber = int.parse(
      descriptor.competencyId.substring(5),
    );

    if (_requiredPositiveInt(contentJson, 'competencyNumber') !=
        expectedCompetencyNumber) {
      throw const FormatException(
        'Content package competency number does not match competency ID.',
      );
    }

    if (_requiredString(contentJson, 'id').trim().isEmpty ||
        _requiredString(contentJson, 'title').trim().isEmpty) {
      throw const FormatException(
        'Content package StudyContent identity is incomplete.',
      );
    }

    late final StudyContent content;

    try {
      content = StudyContent.fromJson(contentJson);
    } catch (_) {
      throw const FormatException('Content package StudyContent is invalid.');
    }

    if (content.id.trim().isEmpty ||
        content.title.trim().isEmpty ||
        content.domainId.toLowerCase() != expectedDomain ||
        content.competencyId.toLowerCase() != descriptor.competencyId ||
        content.competencyNumber != expectedCompetencyNumber ||
        content.version != sourceVersion ||
        content.status.toLowerCase() != 'published') {
      throw const FormatException(
        'Content package normalized StudyContent failed validation.',
      );
    }

    return VerifiedContentPackage(
      descriptor: descriptor,
      content: content,
    );
  }
}

final RegExp _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');
final RegExp _competencyPattern = RegExp(
  r'^d\d{2}_c\d{2}$',
  caseSensitive: false,
);

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key]?.toString().trim();

  if (value == null || value.isEmpty) {
    throw FormatException('Missing required string "$key".');
  }

  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is int) {
    return value;
  }

  if (value is num && value == value.toInt()) {
    return value.toInt();
  }

  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null) {
    throw FormatException('Missing required integer "$key".');
  }

  return parsed;
}

int _requiredPositiveInt(Map<String, dynamic> json, String key) {
  final value = _requiredInt(json, key);

  if (value <= 0) {
    throw FormatException('"$key" must be positive.');
  }

  return value;
}

int _requiredNonNegativeInt(Map<String, dynamic> json, String key) {
  final value = _requiredInt(json, key);

  if (value < 0) {
    throw FormatException('"$key" cannot be negative.');
  }

  return value;
}
