import 'dart:io';

import 'checksum_service.dart';

class ArtifactDeclaration {
  const ArtifactDeclaration({
    required this.artifactId,
    required this.fileName,
    this.required = true,
  });

  final String artifactId;
  final String fileName;
  final bool required;
}

class ArtifactRecord {
  const ArtifactRecord({
    required this.artifactId,
    required this.fileName,
    required this.sizeBytes,
    required this.sha256,
    required this.required,
  });

  final String artifactId;
  final String fileName;
  final int sizeBytes;
  final String sha256;
  final bool required;

  Map<String, Object?> toJson() => <String, Object?>{
    'artifactId': artifactId,
    'fileName': fileName,
    'sizeBytes': sizeBytes,
    'sha256': sha256,
    'required': required,
  };

  ChecksumEntry toChecksumEntry() {
    return ChecksumEntry(fileName: fileName, sha256: sha256);
  }
}

class ArtifactIntegrityIssue {
  const ArtifactIntegrityIssue({
    required this.code,
    required this.message,
    this.artifactId,
    this.fileName,
  });

  final String code;
  final String message;
  final String? artifactId;
  final String? fileName;

  Map<String, Object?> toJson() => <String, Object?>{
    'code': code,
    'artifactId': artifactId,
    'fileName': fileName,
    'message': message,
  };
}

class ArtifactInventoryResult {
  const ArtifactInventoryResult({
    required this.records,
    required this.issues,
  });

  final List<ArtifactRecord> records;
  final List<ArtifactIntegrityIssue> issues;

  bool get pass => issues.isEmpty;

  List<ChecksumEntry> get checksumEntries =>
      records.map((record) => record.toChecksumEntry()).toList();

  Map<String, Object?> toJson() => <String, Object?>{
    'pass': pass,
    'artifactCount': records.length,
    'blockingFailureCount': issues.length,
    'artifacts': records.map((record) => record.toJson()).toList(),
    'issues': issues.map((issue) => issue.toJson()).toList(),
  };
}

class ArtifactIntegrityResult {
  const ArtifactIntegrityResult({required this.issues});

  final List<ArtifactIntegrityIssue> issues;

  bool get pass => issues.isEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
    'pass': pass,
    'blockingFailureCount': issues.length,
    'issues': issues.map((issue) => issue.toJson()).toList(),
  };
}

class ArtifactInventoryService {
  const ArtifactInventoryService({
    this.checksumService = const ChecksumService(),
  });

  static final RegExp _artifactIdPattern = RegExp(
    r'^[A-Za-z][A-Za-z0-9._-]*$',
  );

  final ChecksumService checksumService;

  Future<ArtifactInventoryResult> capture({
    required String rootDirectory,
    required Iterable<ArtifactDeclaration> declarations,
  }) async {
    final records = <ArtifactRecord>[];
    final issues = <ArtifactIntegrityIssue>[];
    final seenArtifactIds = <String>{};
    final seenFileNames = <String>{};

    for (final declaration in declarations) {
      var declarationValid = true;

      if (!_artifactIdPattern.hasMatch(declaration.artifactId)) {
        issues.add(
          ArtifactIntegrityIssue(
            code: 'AIN001_INVALID_ARTIFACT_ID',
            artifactId: declaration.artifactId,
            fileName: declaration.fileName,
            message: 'Artifact ID does not match the governed format.',
          ),
        );
        declarationValid = false;
      }

      if (!_isPortableRelativePath(declaration.fileName)) {
        issues.add(
          ArtifactIntegrityIssue(
            code: 'AIN002_INVALID_FILE_NAME',
            artifactId: declaration.artifactId,
            fileName: declaration.fileName,
            message: 'Artifact file name must be a portable relative path.',
          ),
        );
        declarationValid = false;
      }

      if (!seenArtifactIds.add(declaration.artifactId)) {
        issues.add(
          ArtifactIntegrityIssue(
            code: 'AIN003_DUPLICATE_ARTIFACT_ID',
            artifactId: declaration.artifactId,
            fileName: declaration.fileName,
            message: 'Artifact IDs must be unique.',
          ),
        );
        declarationValid = false;
      }

      if (!seenFileNames.add(declaration.fileName)) {
        issues.add(
          ArtifactIntegrityIssue(
            code: 'AIN004_DUPLICATE_FILE_NAME',
            artifactId: declaration.artifactId,
            fileName: declaration.fileName,
            message: 'Artifact file names must be unique.',
          ),
        );
        declarationValid = false;
      }

      if (!declarationValid) {
        continue;
      }

      final file = _resolveArtifactFile(rootDirectory, declaration.fileName);
      final type = await FileSystemEntity.type(file.path);

      if (type == FileSystemEntityType.notFound) {
        if (declaration.required) {
          issues.add(
            ArtifactIntegrityIssue(
              code: 'AIN005_REQUIRED_ARTIFACT_MISSING',
              artifactId: declaration.artifactId,
              fileName: declaration.fileName,
              message: 'Required artifact is missing.',
            ),
          );
        }
        continue;
      }

      if (type != FileSystemEntityType.file) {
        issues.add(
          ArtifactIntegrityIssue(
            code: 'AIN006_ARTIFACT_NOT_FILE',
            artifactId: declaration.artifactId,
            fileName: declaration.fileName,
            message: 'Artifact path does not resolve to a regular file.',
          ),
        );
        continue;
      }

      try {
        final sizeBytes = await file.length();
        final sha256 = await checksumService.sha256File(file);
        records.add(
          ArtifactRecord(
            artifactId: declaration.artifactId,
            fileName: declaration.fileName,
            sizeBytes: sizeBytes,
            sha256: sha256,
            required: declaration.required,
          ),
        );
      } on FileSystemException {
        issues.add(
          ArtifactIntegrityIssue(
            code: 'AIN007_ARTIFACT_READ_FAILED',
            artifactId: declaration.artifactId,
            fileName: declaration.fileName,
            message: 'Artifact bytes could not be read deterministically.',
          ),
        );
      }
    }

    records.sort((left, right) {
      final idOrder = left.artifactId.compareTo(right.artifactId);
      if (idOrder != 0) {
        return idOrder;
      }
      return left.fileName.compareTo(right.fileName);
    });
    _sortIssues(issues);

    return ArtifactInventoryResult(
      records: List<ArtifactRecord>.unmodifiable(records),
      issues: List<ArtifactIntegrityIssue>.unmodifiable(issues),
    );
  }

  static bool _isPortableRelativePath(String value) {
    if (value.trim().isEmpty ||
        value.startsWith('/') ||
        value.contains('\\') ||
        value.contains('\n') ||
        value.contains('\r') ||
        RegExp(r'^[A-Za-z]:').hasMatch(value)) {
      return false;
    }

    final segments = value.split('/');
    return segments.every(
      (segment) =>
          segment.isNotEmpty && segment != '.' && segment != '..',
    );
  }

  static File _resolveArtifactFile(String rootDirectory, String fileName) {
    final relative = fileName.replaceAll('/', Platform.pathSeparator);
    final root = Directory(rootDirectory).absolute.path;
    return File('$root${Platform.pathSeparator}$relative');
  }
}

class ArtifactIntegrityVerifier {
  const ArtifactIntegrityVerifier();

  static final RegExp _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');

  ArtifactIntegrityResult verify({
    required Iterable<ArtifactRecord> expected,
    required Iterable<ArtifactRecord> actual,
  }) {
    final issues = <ArtifactIntegrityIssue>[];
    final expectedById = <String, ArtifactRecord>{};
    final expectedFileNames = <String>{};
    final actualById = <String, ArtifactRecord>{};
    final actualFileNames = <String>{};

    for (final record in expected) {
      if (!_sha256Pattern.hasMatch(record.sha256)) {
        issues.add(
          ArtifactIntegrityIssue(
            code: 'AIV001_INVALID_EXPECTED_SHA256',
            artifactId: record.artifactId,
            fileName: record.fileName,
            message: 'Expected artifact SHA-256 is malformed.',
          ),
        );
      }
      if (expectedById.containsKey(record.artifactId)) {
        issues.add(
          ArtifactIntegrityIssue(
            code: 'AIV002_DUPLICATE_EXPECTED_ARTIFACT_ID',
            artifactId: record.artifactId,
            fileName: record.fileName,
            message: 'Expected inventory contains a duplicate artifact ID.',
          ),
        );
      } else {
        expectedById[record.artifactId] = record;
      }
      if (!expectedFileNames.add(record.fileName)) {
        issues.add(
          ArtifactIntegrityIssue(
            code: 'AIV003_DUPLICATE_EXPECTED_FILE_NAME',
            artifactId: record.artifactId,
            fileName: record.fileName,
            message: 'Expected inventory contains a duplicate file name.',
          ),
        );
      }
    }

    for (final record in actual) {
      if (!_sha256Pattern.hasMatch(record.sha256)) {
        issues.add(
          ArtifactIntegrityIssue(
            code: 'AIV004_INVALID_ACTUAL_SHA256',
            artifactId: record.artifactId,
            fileName: record.fileName,
            message: 'Actual artifact SHA-256 is malformed.',
          ),
        );
      }
      if (actualById.containsKey(record.artifactId)) {
        issues.add(
          ArtifactIntegrityIssue(
            code: 'AIV005_DUPLICATE_ACTUAL_ARTIFACT_ID',
            artifactId: record.artifactId,
            fileName: record.fileName,
            message: 'Actual inventory contains a duplicate artifact ID.',
          ),
        );
      } else {
        actualById[record.artifactId] = record;
      }
      if (!actualFileNames.add(record.fileName)) {
        issues.add(
          ArtifactIntegrityIssue(
            code: 'AIV006_DUPLICATE_ACTUAL_FILE_NAME',
            artifactId: record.artifactId,
            fileName: record.fileName,
            message: 'Actual inventory contains a duplicate file name.',
          ),
        );
      }
    }

    for (final entry in expectedById.entries) {
      final expectedRecord = entry.value;
      final actualRecord = actualById[entry.key];

      if (actualRecord == null) {
        if (expectedRecord.required) {
          issues.add(
            ArtifactIntegrityIssue(
              code: 'AIV007_REQUIRED_ARTIFACT_MISSING',
              artifactId: expectedRecord.artifactId,
              fileName: expectedRecord.fileName,
              message: 'Required expected artifact is absent.',
            ),
          );
        }
        continue;
      }

      if (actualRecord.fileName != expectedRecord.fileName) {
        issues.add(
          ArtifactIntegrityIssue(
            code: 'AIV008_FILE_NAME_SUBSTITUTION',
            artifactId: expectedRecord.artifactId,
            fileName: actualRecord.fileName,
            message: 'Artifact ID resolves to a different file name.',
          ),
        );
      }

      if (actualRecord.required != expectedRecord.required) {
        issues.add(
          ArtifactIntegrityIssue(
            code: 'AIV009_REQUIRED_FLAG_MISMATCH',
            artifactId: expectedRecord.artifactId,
            fileName: actualRecord.fileName,
            message: 'Artifact required status differs from expected.',
          ),
        );
      }

      if (actualRecord.sizeBytes != expectedRecord.sizeBytes) {
        issues.add(
          ArtifactIntegrityIssue(
            code: 'AIV010_SIZE_MISMATCH',
            artifactId: expectedRecord.artifactId,
            fileName: actualRecord.fileName,
            message: 'Artifact byte size differs from expected.',
          ),
        );
      }

      if (actualRecord.sha256 != expectedRecord.sha256) {
        issues.add(
          ArtifactIntegrityIssue(
            code: 'AIV011_SHA256_MISMATCH',
            artifactId: expectedRecord.artifactId,
            fileName: actualRecord.fileName,
            message: 'Artifact SHA-256 differs from expected.',
          ),
        );
      }
    }

    for (final entry in actualById.entries) {
      if (!expectedById.containsKey(entry.key)) {
        final record = entry.value;
        issues.add(
          ArtifactIntegrityIssue(
            code: 'AIV012_UNEXPECTED_ARTIFACT',
            artifactId: record.artifactId,
            fileName: record.fileName,
            message: 'Actual inventory contains an unexpected artifact.',
          ),
        );
      }
    }

    _sortIssues(issues);
    return ArtifactIntegrityResult(
      issues: List<ArtifactIntegrityIssue>.unmodifiable(issues),
    );
  }
}

void _sortIssues(List<ArtifactIntegrityIssue> issues) {
  issues.sort((left, right) {
    final codeOrder = left.code.compareTo(right.code);
    if (codeOrder != 0) {
      return codeOrder;
    }

    final idOrder = (left.artifactId ?? '').compareTo(right.artifactId ?? '');
    if (idOrder != 0) {
      return idOrder;
    }

    return (left.fileName ?? '').compareTo(right.fileName ?? '');
  });
}
