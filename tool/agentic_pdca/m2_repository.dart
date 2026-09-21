import 'dart:io';

import 'm1_repository.dart';
import 'm2_task_packet.dart';

final class M2WorkspaceEvidence {
  M2WorkspaceEvidence({
    required this.facts,
    required List<String> untrackedPaths,
    required List<String> commits,
    required this.diffStatistics,
    this.diffPatch = '',
  }) : untrackedPaths = List.unmodifiable(untrackedPaths),
       commits = List.unmodifiable(commits);

  final M1RepositoryFacts facts;
  final List<String> untrackedPaths;
  final List<String> commits;
  final String diffStatistics;
  final String diffPatch;
  bool get clean => facts.dirtyTrackedPaths.isEmpty && untrackedPaths.isEmpty;
}

/// Trusted composition boundary. Production reads retain the M1 repository
/// adapter and add only untracked files, commit inventory and diff statistics.
abstract interface class M2TrustedWorkspace {
  M1TrustedRepository get repository;
  Future<M2WorkspaceEvidence> read(String approvedBaseSha);
}

final class M2GitWorkspace implements M2TrustedWorkspace {
  M2GitWorkspace({required String root})
    : repository = M1GitRepository(root: root);

  @override
  final M1GitRepository repository;

  @override
  Future<M2WorkspaceEvidence> read(String approvedBaseSha) async {
    if (!m2ExactSha(approvedBaseSha)) {
      throw ArgumentError('Exact base required.');
    }
    final before = await repository.readFacts(approvedBaseSha: approvedBaseSha);
    final untracked = await _git([
      'ls-files',
      '--others',
      '--exclude-standard',
      '-z',
    ]);
    final commits = await _git([
      'rev-list',
      '--reverse',
      '$approvedBaseSha..HEAD',
    ]);
    final statistics = await _git(['diff', '--stat', '$approvedBaseSha..HEAD']);
    final patch = await _git([
      'diff',
      '--no-ext-diff',
      '--unified=0',
      '$approvedBaseSha..HEAD',
    ]);
    final rawChanged = (await _git([
      'diff',
      '--name-only',
      '-z',
      '$approvedBaseSha..HEAD',
    ])).split('\u0000').where((p) => p.isNotEmpty).toList()..sort();
    final after = await repository.readFacts(approvedBaseSha: approvedBaseSha);
    final inheritedChanged = [...after.changedPaths]..sort();
    if (before.head != after.head ||
        before.ref != after.ref ||
        m2CanonicalJson(rawChanged) != m2CanonicalJson(inheritedChanged) ||
        m2CanonicalJson(before.dirtyTrackedPaths) !=
            m2CanonicalJson(after.dirtyTrackedPaths)) {
      throw StateError('Repository moved during evidence capture.');
    }
    final untrackedAfter = await _git([
      'ls-files',
      '--others',
      '--exclude-standard',
      '-z',
    ]);
    if (untracked != untrackedAfter) {
      throw StateError('Untracked files changed during evidence capture.');
    }
    return M2WorkspaceEvidence(
      facts: after,
      untrackedPaths:
          untracked.split('\u0000').where((p) => p.isNotEmpty).toList()..sort(),
      commits: commits
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      diffStatistics: statistics.trim(),
      diffPatch: patch,
    );
  }

  Future<String> _git(List<String> arguments) async {
    final result = await Process.run(
      'git',
      arguments,
      workingDirectory: repository.root,
      runInShell: false,
    );
    if (result.exitCode != 0) throw StateError('Trusted M2 git read failed.');
    return result.stdout.toString();
  }
}
