import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/agentic_pdca/m2_integrity.dart';
import '../../tool/agentic_pdca/m2_task_packet.dart';
import 'm2_test_support.dart';

void main() {
  final sourcePacket = M2TaskPacket.parse(
    File('docs/agentic/implementation/m2/RUN_4_PACKET.json').readAsStringSync(),
  );

  M2TaskPacket packetFor(String suffix) {
    final json = Map<String, Object?>.from(sourcePacket.toJson());
    json['task_id'] = 'M2-RUN-4-' + suffix;
    json['lineage_id'] = 'M2-CONTROLS-4-' + suffix;
    return M2TaskPacket.fromJson(json);
  }

  test('clean matching patch produces no M2-only integrity findings', () async {
    final packet = packetFor('clean');
    final workspace = M2FakeWorkspace(packet)
      ..head = m2TestCandidate
      ..changed = [packet.expectedPaths.first]
      ..diffPatch =
          'diff --git a/' +
          packet.expectedPaths.first +
          ' b/' +
          packet.expectedPaths.first +
          '\n--- a/' +
          packet.expectedPaths.first +
          '\n+++ b/' +
          packet.expectedPaths.first +
          '\n@@ -0,0 +1 @@\n+final value = true;\n';
    final evidence = await workspace.read(packet.taskBaseSha);
    final findings = await M2IntegrityScanner().scan(
      workspace: workspace,
      evidence: evidence,
      packet: packet,
      candidateSha: m2TestCandidate,
    );
    expect(
      findings.where(
        (finding) =>
            finding.code == 'DIFF_PATCH_MISMATCH' ||
            finding.code == 'TEST_SKIP_ADDED' ||
            finding.code == 'DEPENDENCY_CONFIG_CHANGE',
      ),
      isEmpty,
    );
  });

  test('newly skipped tests are rejected from added patch lines', () async {
    final packet = packetFor('skip');
    final testPath = 'test/agentic_pdca/m2_integrity_test.dart';
    final workspace = M2FakeWorkspace(packet)
      ..head = m2TestCandidate
      ..changed = [testPath]
      ..diffPatch =
          'diff --git a/' +
          testPath +
          ' b/' +
          testPath +
          '\n--- a/' +
          testPath +
          '\n+++ b/' +
          testPath +
          '\n@@ -1 +1 @@\n+test(\'x\', () {}, skip: true);\n';
    final evidence = await workspace.read(packet.taskBaseSha);
    final findings = await M2IntegrityScanner().scan(
      workspace: workspace,
      evidence: evidence,
      packet: packet,
      candidateSha: m2TestCandidate,
    );
    expect(
      findings.any((finding) => finding.code == 'TEST_SKIP_ADDED'),
      isTrue,
    );
  });

  test('skip false and comments do not trigger skip finding', () async {
    final packet = packetFor('no-skip');
    final testPath = 'test/agentic_pdca/m2_integrity_test.dart';
    final workspace = M2FakeWorkspace(packet)
      ..head = m2TestCandidate
      ..changed = [testPath]
      ..diffPatch =
          'diff --git a/' +
          testPath +
          ' b/' +
          testPath +
          '\n--- a/' +
          testPath +
          '\n+++ b/' +
          testPath +
          '\n@@ -1 +1,2 @@\n+// skip: true is documentation only\n+test(\'x\', () {}, skip: false);\n';
    final evidence = await workspace.read(packet.taskBaseSha);
    final findings = await M2IntegrityScanner().scan(
      workspace: workspace,
      evidence: evidence,
      packet: packet,
      candidateSha: m2TestCandidate,
    );
    expect(
      findings.any((finding) => finding.code == 'TEST_SKIP_ADDED'),
      isFalse,
    );
  });

  test('patch inventory mismatch fails closed', () async {
    final packet = packetFor('patch-mismatch');
    final workspace = M2FakeWorkspace(packet)
      ..head = m2TestCandidate
      ..changed = [packet.expectedPaths.first]
      ..diffPatch = 'diff --git a/other.dart b/other.dart\n';
    final evidence = await workspace.read(packet.taskBaseSha);
    final findings = await M2IntegrityScanner().scan(
      workspace: workspace,
      evidence: evidence,
      packet: packet,
      candidateSha: m2TestCandidate,
    );
    expect(
      findings.any((finding) => finding.code == 'DIFF_PATCH_MISMATCH'),
      isTrue,
    );
  });

  test('dependency and CI config drift is explicitly identified', () async {
    for (final path in ['pubspec.yaml', '.github/workflows/x.yml', 'firebase/x']) {
      final packet = packetFor('config-' + path.hashCode.toString());
      final workspace = M2FakeWorkspace(packet)
        ..head = m2TestCandidate
        ..changed = [path]
        ..diffPatch = 'diff --git a/' + path + ' b/' + path + '\n';
      final evidence = await workspace.read(packet.taskBaseSha);
      final findings = await M2IntegrityScanner().scan(
        workspace: workspace,
        evidence: evidence,
        packet: packet,
        candidateSha: m2TestCandidate,
      );
      expect(
        findings.any(
          (finding) => finding.code == 'DEPENDENCY_CONFIG_CHANGE',
        ),
        isTrue,
      );
    }
  });

  test('M1 secret and assertion weakening findings are retained', () async {
    final packet = packetFor('inherit');
    final path = packet.expectedPaths.first;
    final workspace = M2FakeWorkspace(packet)
      ..head = m2TestCandidate
      ..changed = [path]
      ..fileContents = {
        path: 'final token = "ghp_123456789012345678901234";\n'
            'expect(value, isNot(true));',
      }
      ..diffPatch = 'diff --git a/' + path + ' b/' + path + '\n';
    final evidence = await workspace.read(packet.taskBaseSha);
    final findings = await M2IntegrityScanner().scan(
      workspace: workspace,
      evidence: evidence,
      packet: packet,
      candidateSha: m2TestCandidate,
    );
    expect(
      findings.any((finding) => finding.code == 'CHECK2_SECRET_LIKE'),
      isTrue,
    );
    expect(
      findings.any((finding) => finding.code == 'CHECK2_ASSERTION_WEAKENING'),
      isTrue,
    );
  });
}
