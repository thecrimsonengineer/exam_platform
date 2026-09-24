import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/release_governance/release_manifest_builder.dart';
import '../../tool/release_governance/release_version.dart';

const _commitSha = '0123456789abcdef0123456789abcdef01234567';
const _treeSha = '89abcdef0123456789abcdef0123456789abcdef';

ReleaseSourceIdentity _source() {
  return const ReleaseSourceIdentity(
    repository: 'thecrimsonengineer/exam_platform',
    branch: 'phase-rel-gov-release-governance',
    commitSha: _commitSha,
    treeSha: _treeSha,
    clean: true,
  );
}

void main() {
  group('release manifest schema file', () {
    late Map<String, Object?> schema;

    setUpAll(() {
      final raw = File(
        'schemas/release_governance/release_manifest.schema.json',
      ).readAsStringSync();
      schema = jsonDecode(raw) as Map<String, Object?>;
    });

    test('declares schema version 1 and rejects unknown top-level keys', () {
      final properties = schema['properties']! as Map<String, Object?>;

      expect(properties['schemaVersion'], <String, Object?>{'const': 1});
      expect(schema['additionalProperties'], isFalse);
    });

    test('requires every canonical top-level section', () {
      final required = (schema['required']! as List<Object?>).cast<String>();

      expect(
        required,
        containsAll(<String>[
          'schemaVersion',
          'release',
          'source',
          'environment',
          'dependencies',
          'components',
          'validation',
          'artifacts',
          'recovery',
        ]),
      );
    });

    test('freezes all governed release states', () {
      final properties = schema['properties']! as Map<String, Object?>;
      final release = properties['release']! as Map<String, Object?>;
      final releaseProperties = release['properties']! as Map<String, Object?>;
      final status = releaseProperties['status']! as Map<String, Object?>;
      final values = (status['enum']! as List<Object?>).cast<String>();

      expect(values, <String>[
        'development',
        'candidate',
        'validated',
        'frozen',
        'released',
        'withdrawn',
        'superseded',
      ]);
    });
  });

  group('ReleaseManifestBuilder', () {
    test('builds the canonical candidate identity', () {
      final manifest = ReleaseManifestBuilder.candidate(
        version: ReleaseVersion.parse('1.2.0+37'),
        candidateOrdinal: 1,
        createdAt: DateTime.utc(2026, 9, 24, 4, 30),
        source: _source(),
      ).build();

      final release = manifest['release']! as Map<String, Object?>;

      expect(manifest['schemaVersion'], 1);
      expect(release['releaseId'], 'csp11-1.2.0-rc.1');
      expect(release['versionName'], '1.2.0');
      expect(release['buildNumber'], 37);
      expect(release['status'], 'candidate');
      expect(release['createdAt'], '2026-09-24T04:30:00.000Z');
    });

    test('orders components by componentId', () {
      final manifest = ReleaseManifestBuilder.candidate(
        version: ReleaseVersion.parse('1.2.0+37'),
        candidateOrdinal: 1,
        createdAt: DateTime.utc(2026, 9, 24),
        source: _source(),
        components: const <ReleaseComponentCheckpoint>[
          ReleaseComponentCheckpoint(
            componentId: 'microLearning',
            status: 'closed',
            checkpoint: 'phase-ml-closed',
          ),
          ReleaseComponentCheckpoint(
            componentId: 'flashcards',
            status: 'closed',
            checkpoint: 'phase-fc-closed',
          ),
        ],
      ).build();

      final components = manifest['components']! as Map<String, Object?>;

      expect(components.keys.toList(), <String>['flashcards', 'microLearning']);
    });

    test('canonical JSON is independent of map insertion order', () {
      final first = ReleaseManifestBuilder.candidate(
        version: ReleaseVersion.parse('1.2.0+37'),
        candidateOrdinal: 1,
        createdAt: DateTime.utc(2026, 9, 24),
        source: _source(),
        environment: <String, Object?>{'flutter': '3.44.9', 'dart': '3.12.2'},
      ).buildCanonicalJson();

      final second = ReleaseManifestBuilder.candidate(
        version: ReleaseVersion.parse('1.2.0+37'),
        candidateOrdinal: 1,
        createdAt: DateTime.utc(2026, 9, 24),
        source: _source(),
        environment: <String, Object?>{'dart': '3.12.2', 'flutter': '3.44.9'},
      ).buildCanonicalJson();

      expect(first, second);
    });

    test('rejects duplicate component IDs', () {
      final builder = ReleaseManifestBuilder.candidate(
        version: ReleaseVersion.parse('1.2.0+37'),
        candidateOrdinal: 1,
        createdAt: DateTime.utc(2026, 9, 24),
        source: _source(),
        components: const <ReleaseComponentCheckpoint>[
          ReleaseComponentCheckpoint(
            componentId: 'flashcards',
            status: 'closed',
            checkpoint: 'phase-fc-closed',
          ),
          ReleaseComponentCheckpoint(
            componentId: 'flashcards',
            status: 'closed',
            checkpoint: 'phase-fc-closed-v2',
          ),
        ],
      );

      expect(builder.build, throwsArgumentError);
    });

    test('rejects malformed source Git SHAs', () {
      final builder = ReleaseManifestBuilder.candidate(
        version: ReleaseVersion.parse('1.2.0+37'),
        candidateOrdinal: 1,
        createdAt: DateTime.utc(2026, 9, 24),
        source: const ReleaseSourceIdentity(
          repository: 'thecrimsonengineer/exam_platform',
          branch: 'phase-rel-gov-release-governance',
          commitSha: 'not-a-sha',
          treeSha: _treeSha,
          clean: true,
        ),
      );

      expect(builder.build, throwsArgumentError);
    });

    test('requires evidence when passedGateCount is non-zero', () {
      final builder = ReleaseManifestBuilder.candidate(
        version: ReleaseVersion.parse('1.2.0+37'),
        candidateOrdinal: 1,
        createdAt: DateTime.utc(2026, 9, 24),
        source: _source(),
        validation: const ReleaseValidationSummary(
          requiredGateCount: 1,
          passedGateCount: 1,
          blockingFailureCount: 0,
        ),
      );

      expect(builder.build, throwsArgumentError);
    });

    test('rejects passedGateCount greater than requiredGateCount', () {
      final builder = ReleaseManifestBuilder.candidate(
        version: ReleaseVersion.parse('1.2.0+37'),
        candidateOrdinal: 1,
        createdAt: DateTime.utc(2026, 9, 24),
        source: _source(),
        validation: const ReleaseValidationSummary(
          requiredGateCount: 1,
          passedGateCount: 2,
          blockingFailureCount: 0,
          evidenceRefs: <String>['test_evidence.json'],
        ),
      );

      expect(builder.build, throwsArgumentError);
    });

    test('rejects duplicate validation evidence references', () {
      final builder = ReleaseManifestBuilder.candidate(
        version: ReleaseVersion.parse('1.2.0+37'),
        candidateOrdinal: 1,
        createdAt: DateTime.utc(2026, 9, 24),
        source: _source(),
        validation: const ReleaseValidationSummary(
          requiredGateCount: 1,
          passedGateCount: 1,
          blockingFailureCount: 0,
          evidenceRefs: <String>['test_evidence.json', 'test_evidence.json'],
        ),
      );

      expect(builder.build, throwsArgumentError);
    });

    test('permits blocked candidate summaries without declaring success', () {
      final manifest = ReleaseManifestBuilder.candidate(
        version: ReleaseVersion.parse('1.2.0+37'),
        candidateOrdinal: 1,
        createdAt: DateTime.utc(2026, 9, 24),
        source: _source(),
        validation: const ReleaseValidationSummary(
          requiredGateCount: 2,
          passedGateCount: 1,
          blockingFailureCount: 1,
          evidenceRefs: <String>['test_evidence.json'],
        ),
      ).build();

      final validation = manifest['validation']! as Map<String, Object?>;

      expect(validation['blockingFailureCount'], 1);
      expect(validation['passedGateCount'], 1);
    });
  });
}
