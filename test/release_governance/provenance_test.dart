import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/release_governance/repository_provenance.dart';

void main() {
  group('RepositoryProvenanceInspector.normalizeRepositoryRemote', () {
    test('normalizes HTTPS GitHub remote', () {
      expect(
        RepositoryProvenanceInspector.normalizeRepositoryRemote(
          'https://github.com/thecrimsonengineer/exam_platform.git',
        ),
        'thecrimsonengineer/exam_platform',
      );
    });

    test('normalizes SCP-style SSH GitHub remote', () {
      expect(
        RepositoryProvenanceInspector.normalizeRepositoryRemote(
          'git@github.com:thecrimsonengineer/exam_platform.git',
        ),
        'thecrimsonengineer/exam_platform',
      );
    });

    test('normalizes URI-style SSH GitHub remote', () {
      expect(
        RepositoryProvenanceInspector.normalizeRepositoryRemote(
          'ssh://git@github.com/thecrimsonengineer/exam_platform.git',
        ),
        'thecrimsonengineer/exam_platform',
      );
    });

    test('rejects remote without owner and repository', () {
      expect(
        () => RepositoryProvenanceInspector.normalizeRepositoryRemote(
          'https://github.com/only-one-part',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('RepositoryProvenancePolicy', () {
    const cleanEvidence = RepositoryProvenanceEvidence(
      repository: 'thecrimsonengineer/exam_platform',
      remoteUrl: 'https://github.com/thecrimsonengineer/exam_platform.git',
      branch: 'release/test',
      headSha: '0123456789abcdef0123456789abcdef01234567',
      treeSha: '89abcdef0123456789abcdef0123456789abcdef',
      tagsAtHead: <String>['checkpoint-test'],
      changes: <RepositoryChange>[],
    );

    test('passes exact clean provenance', () {
      const policy = RepositoryProvenancePolicy(
        expectedRepository: 'thecrimsonengineer/exam_platform',
        expectedBranch: 'release/test',
        expectedCommitSha: '0123456789abcdef0123456789abcdef01234567',
        expectedTreeSha: '89abcdef0123456789abcdef0123456789abcdef',
        expectedTag: 'checkpoint-test',
      );

      expect(policy.evaluate(cleanEvidence).pass, isTrue);
    });

    test('reports repository, branch, commit, tree, and tag mismatches', () {
      const policy = RepositoryProvenancePolicy(
        expectedRepository: 'wrong/repository',
        expectedBranch: 'wrong-branch',
        expectedCommitSha: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        expectedTreeSha: 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        expectedTag: 'missing-tag',
      );

      expect(
        policy.evaluate(cleanEvidence).blockingFailures,
        <String>[
          'RGP001_REPOSITORY_MISMATCH',
          'RGP003_BRANCH_MISMATCH',
          'RGP004_COMMIT_MISMATCH',
          'RGP005_TREE_MISMATCH',
          'RGP006_EXPECTED_TAG_MISSING',
        ],
      );
    });

    test('blocks dirty evidence', () {
      const evidence = RepositoryProvenanceEvidence(
        repository: 'thecrimsonengineer/exam_platform',
        remoteUrl: 'https://github.com/thecrimsonengineer/exam_platform.git',
        branch: 'release/test',
        headSha: '0123456789abcdef0123456789abcdef01234567',
        treeSha: '89abcdef0123456789abcdef0123456789abcdef',
        tagsAtHead: <String>[],
        changes: <RepositoryChange>[
          RepositoryChange(
            status: ' M',
            path: 'pubspec.yaml',
            tracked: true,
          ),
        ],
      );

      const policy = RepositoryProvenancePolicy(
        expectedRepository: 'thecrimsonengineer/exam_platform',
      );

      expect(
        policy.evaluate(evidence).blockingFailures,
        contains('RGP002_DIRTY_WORKTREE'),
      );
    });

    test('blocks detached HEAD by default', () {
      const evidence = RepositoryProvenanceEvidence(
        repository: 'thecrimsonengineer/exam_platform',
        remoteUrl: 'https://github.com/thecrimsonengineer/exam_platform.git',
        branch: null,
        headSha: '0123456789abcdef0123456789abcdef01234567',
        treeSha: '89abcdef0123456789abcdef0123456789abcdef',
        tagsAtHead: <String>[],
        changes: <RepositoryChange>[],
      );

      const policy = RepositoryProvenancePolicy(
        expectedRepository: 'thecrimsonengineer/exam_platform',
      );

      expect(
        policy.evaluate(evidence).blockingFailures,
        contains('RGP007_DETACHED_HEAD_NOT_ALLOWED'),
      );
    });

    test('allows exact detached SHA when explicitly permitted', () {
      const evidence = RepositoryProvenanceEvidence(
        repository: 'thecrimsonengineer/exam_platform',
        remoteUrl: 'https://github.com/thecrimsonengineer/exam_platform.git',
        branch: null,
        headSha: '0123456789abcdef0123456789abcdef01234567',
        treeSha: '89abcdef0123456789abcdef0123456789abcdef',
        tagsAtHead: <String>[],
        changes: <RepositoryChange>[],
      );

      const policy = RepositoryProvenancePolicy(
        expectedRepository: 'thecrimsonengineer/exam_platform',
        expectedCommitSha: '0123456789abcdef0123456789abcdef01234567',
        allowDetachedHead: true,
      );

      expect(policy.evaluate(evidence).pass, isTrue);
    });

    test('requires exact commit expectation for detached acceptance', () {
      const evidence = RepositoryProvenanceEvidence(
        repository: 'thecrimsonengineer/exam_platform',
        remoteUrl: 'https://github.com/thecrimsonengineer/exam_platform.git',
        branch: null,
        headSha: '0123456789abcdef0123456789abcdef01234567',
        treeSha: '89abcdef0123456789abcdef0123456789abcdef',
        tagsAtHead: <String>[],
        changes: <RepositoryChange>[],
      );

      const policy = RepositoryProvenancePolicy(
        expectedRepository: 'thecrimsonengineer/exam_platform',
        allowDetachedHead: true,
      );

      expect(
        policy.evaluate(evidence).blockingFailures,
        contains('RGP008_DETACHED_HEAD_REQUIRES_EXPECTED_COMMIT'),
      );
    });

    test('cannot satisfy an expected branch while detached', () {
      const evidence = RepositoryProvenanceEvidence(
        repository: 'thecrimsonengineer/exam_platform',
        remoteUrl: 'https://github.com/thecrimsonengineer/exam_platform.git',
        branch: null,
        headSha: '0123456789abcdef0123456789abcdef01234567',
        treeSha: '89abcdef0123456789abcdef0123456789abcdef',
        tagsAtHead: <String>[],
        changes: <RepositoryChange>[],
      );

      const policy = RepositoryProvenancePolicy(
        expectedRepository: 'thecrimsonengineer/exam_platform',
        expectedBranch: 'release/test',
        expectedCommitSha: '0123456789abcdef0123456789abcdef01234567',
        allowDetachedHead: true,
      );

      expect(
        policy.evaluate(evidence).blockingFailures,
        contains('RGP009_EXPECTED_BRANCH_UNAVAILABLE'),
      );
    });
  });

  group('RepositoryProvenanceInspector integration', () {
    late Directory repository;

    setUp(() async {
      repository = await Directory.systemTemp.createTemp('rel_gov_provenance_');

      await _git(repository, <String>['init']);
      await _git(repository, <String>['config', 'user.name', 'REL-GOV Test']);
      await _git(
        repository,
        <String>['config', 'user.email', 'rel-gov-test@example.invalid'],
      );
      await _git(
        repository,
        <String>[
          'remote',
          'add',
          'origin',
          'https://github.com/thecrimsonengineer/exam_platform.git',
        ],
      );

      await File(
        '${repository.path}/tracked.txt',
      ).writeAsString('frozen source\n');
      await _git(repository, <String>['add', 'tracked.txt']);
      await _git(repository, <String>['commit', '-m', 'initial']);
    });

    tearDown(() async {
      if (repository.existsSync()) {
        await repository.delete(recursive: true);
      }
    });

    test('captures exact clean repository identity', () async {
      const inspector = RepositoryProvenanceInspector();
      final evidence = await inspector.inspect(directory: repository.path);

      expect(evidence.repository, 'thecrimsonengineer/exam_platform');
      expect(evidence.remoteUrl, contains('thecrimsonengineer/exam_platform'));
      expect(evidence.headSha, matches(RegExp(r'^[0-9a-f]{40}$')));
      expect(evidence.treeSha, matches(RegExp(r'^[0-9a-f]{40}$')));
      expect(evidence.branch, isNotNull);
      expect(evidence.clean, isTrue);
      expect(evidence.changes, isEmpty);
    });

    test('captures checkpoint tags at HEAD in sorted order', () async {
      await _git(repository, <String>['tag', 'z-checkpoint']);
      await _git(repository, <String>['tag', 'a-checkpoint']);

      const inspector = RepositoryProvenanceInspector();
      final evidence = await inspector.inspect(directory: repository.path);

      expect(evidence.tagsAtHead, <String>['a-checkpoint', 'z-checkpoint']);
    });

    test('detects tracked and untracked changes', () async {
      await File(
        '${repository.path}/tracked.txt',
      ).writeAsString('changed source\n');
      await File(
        '${repository.path}/untracked.txt',
      ).writeAsString('new source\n');

      const inspector = RepositoryProvenanceInspector();
      final evidence = await inspector.inspect(directory: repository.path);

      expect(evidence.clean, isFalse);
      expect(
        evidence.changes.any(
          (change) =>
              change.path == 'tracked.txt' &&
              change.tracked &&
              change.status.contains('M'),
        ),
        isTrue,
      );
      expect(
        evidence.changes.any(
          (change) =>
              change.path == 'untracked.txt' &&
              !change.tracked &&
              change.status == '??',
        ),
        isTrue,
      );
    });

    test('captures detached HEAD and supports exact-SHA policy', () async {
      final head = await _git(repository, <String>['rev-parse', 'HEAD']);
      await _git(repository, <String>['checkout', '--detach', head]);

      const inspector = RepositoryProvenanceInspector();
      final evidence = await inspector.inspect(directory: repository.path);

      expect(evidence.branch, isNull);
      expect(evidence.headSha, head);

      final check = RepositoryProvenancePolicy(
        expectedRepository: 'thecrimsonengineer/exam_platform',
        expectedCommitSha: head,
        allowDetachedHead: true,
      ).evaluate(evidence);

      expect(check.pass, isTrue);
    });
  });
}

Future<String> _git(Directory directory, List<String> arguments) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: directory.path,
  );

  if (result.exitCode != 0) {
    throw StateError(
      'git ${arguments.join(' ')} failed with '
      'exitCode=${result.exitCode}: ${result.stderr}',
    );
  }

  return (result.stdout as String).trim();
}
