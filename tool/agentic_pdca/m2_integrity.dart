import 'm1_check_act.dart';
import 'm1_path_guard.dart';
import 'm2_repository.dart';
import 'm2_task_packet.dart';

final class M2IntegrityFinding {
  const M2IntegrityFinding(this.code, this.detail);

  final String code;
  final String detail;
}

final class M2IntegrityScanner {
  Future<List<M2IntegrityFinding>> scan({
    required M2TrustedWorkspace workspace,
    required M2WorkspaceEvidence evidence,
    required M2TaskPacket packet,
    required String candidateSha,
  }) async {
    final findings = <M2IntegrityFinding>[];

    final inherited = await M1IntegrityScanner().scanRepository(
      repository: workspace.repository,
      approvedBaseSha: packet.taskBaseSha,
      candidateSha: candidateSha,
      expectedPaths: packet.expectedPaths,
    );
    findings.addAll(
      inherited.map(
        (finding) => M2IntegrityFinding(
          'CHECK2_' + finding.code,
          finding.detail,
        ),
      ),
    );

    final patchPaths = _patchPaths(evidence.diffPatch);
    final trustedPaths = evidence.facts.changedPaths.toSet();
    if (patchPaths.length != trustedPaths.length ||
        !patchPaths.containsAll(trustedPaths)) {
      findings.add(
        const M2IntegrityFinding(
          'DIFF_PATCH_MISMATCH',
          'Trusted patch inventory does not match trusted changed paths.',
        ),
      );
    }

    for (final path in evidence.facts.changedPaths) {
      if (_dependencyOrConfig(path)) {
        findings.add(
          M2IntegrityFinding(
            'DEPENDENCY_CONFIG_CHANGE',
            path,
          ),
        );
      }
    }

    for (final entry in _addedLines(evidence.diffPatch)) {
      final path = entry.$1;
      final line = entry.$2.trim();
      if (!path.startsWith('test/') ||
          line.isEmpty ||
          line.startsWith('//')) {
        continue;
      }
      if (_introducesSkip(line)) {
        findings.add(
          M2IntegrityFinding(
            'TEST_SKIP_ADDED',
            path + ': ' + line,
          ),
        );
      }
    }

    return List.unmodifiable(_deduplicate(findings));
  }

  Set<String> _patchPaths(String patch) {
    final paths = <String>{};
    for (final raw in patch.split('\n')) {
      if (!raw.startsWith('diff --git a/')) continue;
      final marker = raw.indexOf(' b/');
      if (marker <= 'diff --git a/'.length) continue;
      final path = raw.substring(marker + 3).trim();
      if (const M1RepositoryPathGuard().canonicalize(path) != null) {
        paths.add(path);
      }
    }
    return paths;
  }

  List<(String, String)> _addedLines(String patch) {
    final result = <(String, String)>[];
    String? currentPath;
    for (final raw in patch.split('\n')) {
      if (raw.startsWith('diff --git a/')) {
        final marker = raw.indexOf(' b/');
        currentPath = marker < 0 ? null : raw.substring(marker + 3).trim();
        continue;
      }
      if (currentPath == null ||
          !raw.startsWith('+') ||
          raw.startsWith('+++')) {
        continue;
      }
      result.add((currentPath, raw.substring(1)));
    }
    return result;
  }

  bool _dependencyOrConfig(String path) =>
      path == 'pubspec.yaml' ||
      path == 'pubspec.lock' ||
      path.startsWith('.github/') ||
      path.startsWith('firebase/');

  bool _introducesSkip(String line) {
    if (RegExp(r'^@Skip\b').hasMatch(line) ||
        RegExp(r'\.skip\s*\(').hasMatch(line)) {
      return true;
    }
    final match = RegExp(r'\bskip\s*:\s*([^,)]+)').firstMatch(line);
    if (match == null) return false;
    final value = match.group(1)!.trim();
    return value != 'false';
  }

  List<M2IntegrityFinding> _deduplicate(List<M2IntegrityFinding> source) {
    final seen = <String>{};
    return [
      for (final finding in source)
        if (seen.add(finding.code + '\u001f' + finding.detail)) finding,
    ];
  }
}
