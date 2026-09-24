import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/release_governance/artifact_inventory.dart';

void main() {
  group('ArtifactInventoryService', () {
    const service = ArtifactInventoryService();

    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('rel_gov_artifacts_');
      await Directory('${root.path}/build').create(recursive: true);
      await File(
        '${root.path}/build/app-release.apk',
      ).writeAsString('CSP11 governed artifact\n', flush: true);
    });

    tearDown(() async {
      if (root.existsSync()) {
        await root.delete(recursive: true);
      }
    });

    test('captures deterministic artifact identity', () async {
      final result = await service.capture(
        rootDirectory: root.path,
        declarations: const <ArtifactDeclaration>[
          ArtifactDeclaration(
            artifactId: 'android-apk',
            fileName: 'build/app-release.apk',
          ),
        ],
      );

      expect(result.pass, isTrue);
      expect(result.records, hasLength(1));

      final record = result.records.single;
      expect(record.artifactId, 'android-apk');
      expect(record.fileName, 'build/app-release.apk');
      expect(record.sizeBytes, 24);
      expect(
        record.sha256,
        '7648e5b839bc546fa98609b9c5b7dc8952bf902d98040f45bc69a2446a71ce12',
      );
      expect(record.required, isTrue);
      expect(record.toJson(), <String, Object?>{
        'artifactId': 'android-apk',
        'fileName': 'build/app-release.apk',
        'sizeBytes': 24,
        'sha256':
            '7648e5b839bc546fa98609b9c5b7dc8952bf902d98040f45bc69a2446a71ce12',
        'required': true,
      });
    });

    test('sorts records by artifact ID', () async {
      await File(
        '${root.path}/build/windows.zip',
      ).writeAsString('windows', flush: true);

      final result = await service.capture(
        rootDirectory: root.path,
        declarations: const <ArtifactDeclaration>[
          ArtifactDeclaration(
            artifactId: 'windows-zip',
            fileName: 'build/windows.zip',
          ),
          ArtifactDeclaration(
            artifactId: 'android-apk',
            fileName: 'build/app-release.apk',
          ),
        ],
      );

      expect(
        result.records.map((record) => record.artifactId).toList(),
        <String>['android-apk', 'windows-zip'],
      );
    });

    test('blocks a missing required artifact', () async {
      final result = await service.capture(
        rootDirectory: root.path,
        declarations: const <ArtifactDeclaration>[
          ArtifactDeclaration(artifactId: 'web-zip', fileName: 'build/web.zip'),
        ],
      );

      expect(result.pass, isFalse);
      expect(
        result.issues.map((issue) => issue.code),
        contains('AIN005_REQUIRED_ARTIFACT_MISSING'),
      );
    });

    test(
      'allows an absent optional artifact without inventing a record',
      () async {
        final result = await service.capture(
          rootDirectory: root.path,
          declarations: const <ArtifactDeclaration>[
            ArtifactDeclaration(
              artifactId: 'symbols',
              fileName: 'build/symbols.zip',
              required: false,
            ),
          ],
        );

        expect(result.pass, isTrue);
        expect(result.records, isEmpty);
      },
    );

    test('blocks duplicate artifact IDs and file names', () async {
      final result = await service.capture(
        rootDirectory: root.path,
        declarations: const <ArtifactDeclaration>[
          ArtifactDeclaration(
            artifactId: 'android-apk',
            fileName: 'build/app-release.apk',
          ),
          ArtifactDeclaration(
            artifactId: 'android-apk',
            fileName: 'build/other.apk',
          ),
          ArtifactDeclaration(
            artifactId: 'android-copy',
            fileName: 'build/app-release.apk',
          ),
        ],
      );

      final codes = result.issues.map((issue) => issue.code).toList();
      expect(codes, contains('AIN003_DUPLICATE_ARTIFACT_ID'));
      expect(codes, contains('AIN004_DUPLICATE_FILE_NAME'));
    });

    test('blocks non-portable and traversal paths', () async {
      final result = await service.capture(
        rootDirectory: root.path,
        declarations: const <ArtifactDeclaration>[
          ArtifactDeclaration(artifactId: 'escape', fileName: '../outside.apk'),
          ArtifactDeclaration(
            artifactId: 'windows-absolute',
            fileName: 'C:/temp/app.apk',
          ),
          ArtifactDeclaration(
            artifactId: 'backslash',
            fileName: r'build\\app.apk',
          ),
        ],
      );

      expect(
        result.issues
            .where((issue) => issue.code == 'AIN002_INVALID_FILE_NAME')
            .length,
        3,
      );
    });

    test('rejects a directory where an artifact file is required', () async {
      await Directory('${root.path}/build/not-a-file').create();

      final result = await service.capture(
        rootDirectory: root.path,
        declarations: const <ArtifactDeclaration>[
          ArtifactDeclaration(
            artifactId: 'bad-artifact',
            fileName: 'build/not-a-file',
          ),
        ],
      );

      expect(
        result.issues.map((issue) => issue.code),
        contains('AIN006_ARTIFACT_NOT_FILE'),
      );
    });
  });

  group('ArtifactIntegrityVerifier', () {
    const verifier = ArtifactIntegrityVerifier();

    test('passes an exact inventory', () {
      final expected = <ArtifactRecord>[_record()];
      final result = verifier.verify(expected: expected, actual: expected);

      expect(result.pass, isTrue);
      expect(result.issues, isEmpty);
    });

    test('detects required artifact deletion', () {
      final result = verifier.verify(
        expected: <ArtifactRecord>[_record()],
        actual: const <ArtifactRecord>[],
      );

      expect(result.pass, isFalse);
      expect(
        result.issues.map((issue) => issue.code),
        contains('AIV007_REQUIRED_ARTIFACT_MISSING'),
      );
    });

    test('permits optional artifact absence', () {
      final result = verifier.verify(
        expected: <ArtifactRecord>[_record(required: false)],
        actual: const <ArtifactRecord>[],
      );

      expect(result.pass, isTrue);
    });

    test('detects file-name substitution for the same artifact ID', () {
      final result = verifier.verify(
        expected: <ArtifactRecord>[_record()],
        actual: <ArtifactRecord>[_record(fileName: 'build/substituted.apk')],
      );

      expect(
        result.issues.map((issue) => issue.code),
        contains('AIV008_FILE_NAME_SUBSTITUTION'),
      );
    });

    test('detects byte-size and SHA-256 modification', () {
      final result = verifier.verify(
        expected: <ArtifactRecord>[_record()],
        actual: <ArtifactRecord>[
          _record(
            sizeBytes: 11,
            sha256:
                '01630d6526a68a8a6b72828d3e7a2fedc4ca87acccfc297d143f90d5e6049f96',
          ),
        ],
      );

      final codes = result.issues.map((issue) => issue.code).toList();
      expect(codes, contains('AIV010_SIZE_MISMATCH'));
      expect(codes, contains('AIV011_SHA256_MISMATCH'));
    });

    test('detects same-size byte modification through SHA-256', () {
      final result = verifier.verify(
        expected: <ArtifactRecord>[
          _record(
            sizeBytes: 11,
            sha256:
                '305b2ffdc3a6097beb7469e1c7a9ce7f1c06b15b8c500b4b5914e7f0de50ee92',
          ),
        ],
        actual: <ArtifactRecord>[
          _record(
            sizeBytes: 11,
            sha256:
                '01630d6526a68a8a6b72828d3e7a2fedc4ca87acccfc297d143f90d5e6049f96',
          ),
        ],
      );

      expect(
        result.issues.map((issue) => issue.code),
        contains('AIV011_SHA256_MISMATCH'),
      );
      expect(
        result.issues.map((issue) => issue.code),
        isNot(contains('AIV010_SIZE_MISMATCH')),
      );
    });

    test('detects duplicate actual IDs and file names', () {
      final duplicate = _record();
      final result = verifier.verify(
        expected: <ArtifactRecord>[_record()],
        actual: <ArtifactRecord>[duplicate, duplicate],
      );

      final codes = result.issues.map((issue) => issue.code).toList();
      expect(codes, contains('AIV005_DUPLICATE_ACTUAL_ARTIFACT_ID'));
      expect(codes, contains('AIV006_DUPLICATE_ACTUAL_FILE_NAME'));
    });

    test('detects unexpected artifact identities', () {
      final result = verifier.verify(
        expected: <ArtifactRecord>[_record()],
        actual: <ArtifactRecord>[
          _record(),
          _record(
            artifactId: 'unexpected-zip',
            fileName: 'build/unexpected.zip',
          ),
        ],
      );

      expect(
        result.issues.map((issue) => issue.code),
        contains('AIV012_UNEXPECTED_ARTIFACT'),
      );
    });

    test('detects malformed expected and actual SHA-256 values', () {
      final result = verifier.verify(
        expected: <ArtifactRecord>[_record(sha256: 'bad')],
        actual: <ArtifactRecord>[_record(sha256: 'also-bad')],
      );

      final codes = result.issues.map((issue) => issue.code).toList();
      expect(codes, contains('AIV001_INVALID_EXPECTED_SHA256'));
      expect(codes, contains('AIV004_INVALID_ACTUAL_SHA256'));
    });

    test('detects required-flag drift', () {
      final result = verifier.verify(
        expected: <ArtifactRecord>[_record(required: true)],
        actual: <ArtifactRecord>[_record(required: false)],
      );

      expect(
        result.issues.map((issue) => issue.code),
        contains('AIV009_REQUIRED_FLAG_MISMATCH'),
      );
    });
  });
}

ArtifactRecord _record({
  String artifactId = 'android-apk',
  String fileName = 'build/app-release.apk',
  int sizeBytes = 24,
  String sha256 =
      '7648e5b839bc546fa98609b9c5b7dc8952bf902d98040f45bc69a2446a71ce12',
  bool required = true,
}) {
  return ArtifactRecord(
    artifactId: artifactId,
    fileName: fileName,
    sizeBytes: sizeBytes,
    sha256: sha256,
    required: required,
  );
}
