import 'dart:io';

class RepositoryChange {
  const RepositoryChange({
    required this.status,
    required this.path,
    required this.tracked,
  });

  final String status;
  final String path;
  final bool tracked;

  Map<String, Object?> toJson() => <String, Object?>{
    'status': status,
    'path': path,
    'tracked': tracked,
  };
}

class RepositoryProvenanceEvidence {
  const RepositoryProvenanceEvidence({
    required this.repository,
    required this.remoteUrl,
    required this.branch,
    required this.headSha,
    required this.treeSha,
    required this.tagsAtHead,
    required this.changes,
  });

  final String repository;
  final String remoteUrl;
  final String? branch;
  final String headSha;
  final String treeSha;
  final List<String> tagsAtHead;
  final List<RepositoryChange> changes;

  bool get clean => changes.isEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
    'repository': repository,
    'remoteUrl': remoteUrl,
    'branch': branch,
    'headSha': headSha,
    'treeSha': treeSha,
    'tagsAtHead': tagsAtHead,
    'changes': changes.map((change) => change.toJson()).toList(),
    'clean': clean,
  };
}

class RepositoryProvenancePolicy {
  const RepositoryProvenancePolicy({
    required this.expectedRepository,
    this.expectedBranch,
    this.expectedCommitSha,
    this.expectedTreeSha,
    this.expectedTag,
    this.allowDetachedHead = false,
    this.requireClean = true,
  });

  final String expectedRepository;
  final String? expectedBranch;
  final String? expectedCommitSha;
  final String? expectedTreeSha;
  final String? expectedTag;
  final bool allowDetachedHead;
  final bool requireClean;

  RepositoryProvenanceCheck evaluate(RepositoryProvenanceEvidence evidence) {
    final failures = <String>[];

    if (evidence.repository != expectedRepository) {
      failures.add('RGP001_REPOSITORY_MISMATCH');
    }

    if (requireClean && !evidence.clean) {
      failures.add('RGP002_DIRTY_WORKTREE');
    }

    if (evidence.branch == null) {
      if (!allowDetachedHead) {
        failures.add('RGP007_DETACHED_HEAD_NOT_ALLOWED');
      } else if (expectedCommitSha == null) {
        failures.add('RGP008_DETACHED_HEAD_REQUIRES_EXPECTED_COMMIT');
      }

      if (expectedBranch != null) {
        failures.add('RGP009_EXPECTED_BRANCH_UNAVAILABLE');
      }
    } else if (expectedBranch != null && evidence.branch != expectedBranch) {
      failures.add('RGP003_BRANCH_MISMATCH');
    }

    if (expectedCommitSha != null && evidence.headSha != expectedCommitSha) {
      failures.add('RGP004_COMMIT_MISMATCH');
    }

    if (expectedTreeSha != null && evidence.treeSha != expectedTreeSha) {
      failures.add('RGP005_TREE_MISMATCH');
    }

    if (expectedTag != null && !evidence.tagsAtHead.contains(expectedTag)) {
      failures.add('RGP006_EXPECTED_TAG_MISSING');
    }

    return RepositoryProvenanceCheck(
      blockingFailures: List<String>.unmodifiable(failures),
    );
  }
}

class RepositoryProvenanceCheck {
  const RepositoryProvenanceCheck({required this.blockingFailures});

  final List<String> blockingFailures;

  bool get pass => blockingFailures.isEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
    'pass': pass,
    'blockingFailureCount': blockingFailures.length,
    'blockingFailures': blockingFailures,
  };
}

class RepositoryProvenanceInspector {
  const RepositoryProvenanceInspector();

  static final RegExp _gitShaPattern = RegExp(r'^[0-9a-f]{40}$');

  Future<RepositoryProvenanceEvidence> inspect({String directory = '.'}) async {
    final root = await _git(directory, const <String>[
      'rev-parse',
      '--show-toplevel',
    ]);
    final remoteUrl = await _git(root, const <String>[
      'remote',
      'get-url',
      'origin',
    ]);
    final repository = normalizeRepositoryRemote(remoteUrl);
    final headSha = await _git(root, const <String>['rev-parse', 'HEAD']);
    final treeSha = await _git(root, const <String>[
      'rev-parse',
      'HEAD^{tree}',
    ]);

    _requireGitSha(headSha, 'HEAD');
    _requireGitSha(treeSha, 'HEAD tree');

    final branchOutput = await _git(root, const <String>[
      'symbolic-ref',
      '--short',
      '-q',
      'HEAD',
    ], allowFailure: true);
    final branch = branchOutput.isEmpty ? null : branchOutput;

    final tagOutput = await _git(root, const <String>[
      'tag',
      '--points-at',
      'HEAD',
    ]);
    final tags = _nonEmptyLines(tagOutput)..sort();

    final statusOutput = await _git(
      root,
      const <String>[
        '-c',
        'core.quotepath=false',
        'status',
        '--porcelain=v1',
        '--untracked-files=all',
      ],
      trimOutput: false,
    );
    final changes = _parseStatus(statusOutput);

    return RepositoryProvenanceEvidence(
      repository: repository,
      remoteUrl: remoteUrl,
      branch: branch,
      headSha: headSha,
      treeSha: treeSha,
      tagsAtHead: List<String>.unmodifiable(tags),
      changes: List<RepositoryChange>.unmodifiable(changes),
    );
  }

  static String normalizeRepositoryRemote(String remoteUrl) {
    var value = remoteUrl.trim();
    if (value.isEmpty) {
      throw const FormatException('Git origin remote URL is empty.');
    }

    if (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    if (value.endsWith('.git')) {
      value = value.substring(0, value.length - 4);
    }

    String path;
    if (value.startsWith('git@') && value.contains(':')) {
      path = value.substring(value.indexOf(':') + 1);
    } else {
      final uri = Uri.tryParse(value);
      if (uri == null || uri.host.isEmpty) {
        throw FormatException('Unsupported Git remote URL.', remoteUrl);
      }
      path = uri.path;
    }

    final parts = path
        .split('/')
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.length < 2) {
      throw FormatException(
        'Git remote URL does not identify owner/repository.',
        remoteUrl,
      );
    }

    final owner = parts[parts.length - 2];
    final repository = parts.last;
    if (owner.isEmpty || repository.isEmpty) {
      throw FormatException(
        'Git remote URL does not identify owner/repository.',
        remoteUrl,
      );
    }

    return '$owner/$repository';
  }

  static List<RepositoryChange> _parseStatus(String output) {
    if (output.isEmpty) {
      return const <RepositoryChange>[];
    }

    final changes = <RepositoryChange>[];
    for (final line in output.split('\n')) {
      if (line.trim().isEmpty) {
        continue;
      }
      if (line.length < 3) {
        throw FormatException('Malformed git status line.', line);
      }

      final status = line.substring(0, 2);
      final path = line.substring(3);
      changes.add(
        RepositoryChange(status: status, path: path, tracked: status != '??'),
      );
    }
    return changes;
  }

  static List<String> _nonEmptyLines(String output) {
    if (output.isEmpty) {
      return <String>[];
    }
    return output
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  static void _requireGitSha(String value, String label) {
    if (!_gitShaPattern.hasMatch(value)) {
      throw FormatException(
        '$label is not a lowercase 40-character Git SHA.',
        value,
      );
    }
  }

  static Future<String> _git(
    String directory,
    List<String> arguments, {
    bool allowFailure = false,
    bool trimOutput = true,
  }) async {
    final result = await Process.run(
      'git',
      arguments,
      workingDirectory: directory,
      runInShell: false,
    );

    if (result.exitCode != 0 && !allowFailure) {
      throw StateError(
        'Git command failed: git ${arguments.join(' ')}\n'
        'exitCode=${result.exitCode}\n'
        'stderr=${result.stderr}',
      );
    }

    if (result.exitCode != 0 && allowFailure) {
      return '';
    }

    final stdout = result.stdout as String;
    return trimOutput ? stdout.trim() : stdout;
  }
}
