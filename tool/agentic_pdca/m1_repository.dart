import 'dart:convert';
import 'dart:io';

import 'm1_path_guard.dart';

final class M1RepositoryFacts {
  const M1RepositoryFacts({
    required this.root,
    required this.head,
    required this.ref,
    required this.mergeBase,
    required this.changedPaths,
    required this.deletedTestPaths,
    required this.dirtyTrackedPaths,
    required this.fileContents,
    required this.binaryPaths,
  });

  final String root;
  final String head;
  final String ref;
  final String mergeBase;
  final List<String> changedPaths;
  final List<String> deletedTestPaths;
  final List<String> dirtyTrackedPaths;
  final Map<String, String> fileContents;
  final List<String> binaryPaths;
}

abstract interface class M1TrustedRepository {
  String get root;
  Future<M1RepositoryFacts> readFacts({required String approvedBaseSha});
}

final class M1GitRepository implements M1TrustedRepository {
  M1GitRepository({required this.root});

  @override
  final String root;

  @override
  Future<M1RepositoryFacts> readFacts({required String approvedBaseSha}) async {
    final head = await _git(const ['rev-parse', 'HEAD']);
    final ref = await _git(const ['branch', '--show-current']);
    final mergeBase = await _git(<String>[
      'merge-base',
      'HEAD',
      approvedBaseSha,
    ]);
    final changed = await _git(<String>[
      'diff',
      '--name-only',
      '$approvedBaseSha..HEAD',
    ]);
    final deleted = await _git(<String>[
      'diff',
      '--diff-filter=D',
      '--name-only',
      '$approvedBaseSha..HEAD',
    ]);
    final status = await _git(const ['status', '--porcelain=v1']);
    final paths = _lines(changed);
    final contents = <String, String>{};
    final binaries = <String>[];
    for (final path in paths) {
      final canonical = const M1RepositoryPathGuard().canonicalize(path);
      if (canonical == null) {
        continue;
      }
      final file = File(_join(root, canonical));
      if (!await file.exists()) {
        continue;
      }
      final bytes = await file.readAsBytes();
      if (bytes.contains(0)) {
        binaries.add(canonical);
      } else {
        contents[canonical] = utf8.decode(bytes, allowMalformed: true);
      }
    }
    return M1RepositoryFacts(
      root: root,
      head: head,
      ref: ref,
      mergeBase: mergeBase,
      changedPaths: List.unmodifiable(paths),
      deletedTestPaths: List.unmodifiable(
        _lines(deleted).where((path) => path.startsWith('test/')).toList(),
      ),
      dirtyTrackedPaths: List.unmodifiable(
        status
            .split('\n')
            .where((line) => line.length > 3)
            .map((line) => line.substring(3))
            .toList(),
      ),
      fileContents: Map.unmodifiable(contents),
      binaryPaths: List.unmodifiable(binaries),
    );
  }

  Future<String> _git(List<String> arguments) async {
    final result = await Process.run(
      'git',
      arguments,
      workingDirectory: root,
      runInShell: false,
    );
    if (result.exitCode != 0) {
      throw StateError('Trusted git read failed for fixed operation.');
    }
    return result.stdout.toString().trim();
  }

  List<String> _lines(String value) => value
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  String _join(String base, String relative) =>
      '$base${Platform.pathSeparator}${relative.replaceAll('/', Platform.pathSeparator)}';
}
