import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/agentic_pdca/m2_handoff.dart';
import '../../tool/agentic_pdca/m2_repository.dart';
import 'm2_test_support.dart';

void main() {
  test(
    'real Git workspace reads untracked, staged and committed inventory',
    () async {
      final directory = await Directory.systemTemp.createTemp('m2-repository-');
      Future<String> git(List<String> args) async {
        final result = await Process.run(
          'git',
          args,
          workingDirectory: directory.path,
          runInShell: false,
        );
        expect(result.exitCode, 0, reason: result.stderr.toString());
        return result.stdout.toString().trim();
      }

      try {
        await git(['init']);
        await git(['config', 'user.name', 'M2 Fixture']);
        await git(['config', 'user.email', 'fixture@example.invalid']);
        final file = File('${directory.path}/fixture.txt');
        await file.writeAsString('base\n');
        await git(['add', 'fixture.txt']);
        await git(['commit', '-m', 'base']);
        final base = await git(['rev-parse', 'HEAD']);
        final repository = M2GitWorkspace(root: directory.path);
        expect((await repository.read(base)).clean, isTrue);
        final untracked = File('${directory.path}/untracked.txt');
        await untracked.writeAsString('fixture');
        expect((await repository.read(base)).untrackedPaths, ['untracked.txt']);
        await untracked.delete();
        await file.writeAsString('changed\n');
        await git(['add', 'fixture.txt']);
        await file.writeAsString('base\n');
        expect(
          (await repository.read(base)).facts.dirtyTrackedPaths,
          contains('fixture.txt'),
        );
        await file.writeAsString('changed\n');
        await git(['commit', '-m', 'candidate']);
        final evidence = await repository.read(base);
        expect(evidence.clean, isTrue);
        expect(evidence.facts.changedPaths, ['fixture.txt']);
        expect(evidence.commits, [
          await git(['rev-parse', 'HEAD']),
        ]);
        expect(evidence.diffStatistics, contains('fixture.txt'));
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
  final packet = testPacket();
  M2FakeWorkspace workspace() => M2FakeWorkspace(packet)
    ..head = m2TestCandidate
    ..commits = [m2TestCandidate]
    ..changed = [packet.expectedPaths.first];
  M2HandoffBuilder builder(
    M2FakeWorkspace work, {
    List<M2GateReceipt>? receipts,
  }) => M2HandoffBuilder(
    workspace: work,
    packet: packet,
    gateEvidence: M2FakeGates(receipts ?? greenReceipts(packet)),
  );

  test(
    'handoff is deterministic and uses trusted candidate inventory',
    () async {
      final handoff = builder(workspace());
      final first = await handoff.build(
        candidateSha: m2TestCandidate,
        knownLimitations: ['Pilot A only'],
      );
      final second = await handoff.build(
        candidateSha: m2TestCandidate,
        knownLimitations: ['Pilot A only'],
      );
      expect(first.canonicalJson, second.canonicalJson);
      final json = jsonDecode(first.canonicalJson) as Map;
      expect(json['candidate_sha'], m2TestCandidate);
      expect(json['changed_paths'], [packet.expectedPaths.first]);
      expect(json['packet_hash'], packet.hash);
      expect(json['state'], 'DO_HANDOFF');
      expect(json['clean_worktree'], isTrue);
      expect(json.keys, containsAll(packet.strings('expected_handoff')));
    },
  );
  test(
    'dirty, out-of-scope, deleted tests and binary files deny handoff',
    () async {
      for (final work in [
        workspace()..dirty = ['README.md'],
        workspace()..untracked = ['extra.txt'],
        workspace()..changed = ['lib/main.dart'],
        workspace()..deleted = ['test/removed_test.dart'],
        workspace()..binary = ['data.bin'],
      ]) {
        await expectLater(
          builder(
            work,
          ).build(candidateSha: m2TestCandidate, knownLimitations: []),
          throwsStateError,
        );
      }
    },
  );
  test(
    'missing, red, forged hash and stale candidate gate receipts are rejected',
    () async {
      for (final receipts in [
        <M2GateReceipt>[],
        greenReceipts(packet, exit: 1),
        greenReceipts(packet, hash: 'forged'),
        greenReceipts(packet, candidate: packet.taskBaseSha),
      ]) {
        await expectLater(
          builder(
            workspace(),
            receipts: receipts,
          ).build(candidateSha: m2TestCandidate, knownLimitations: []),
          throwsStateError,
        );
      }
    },
  );
  test(
    'candidate moving during handoff and wrong phase ancestry block',
    () async {
      final race = workspace();
      race.onRead = () {
        if (race.reads == 2) race.head = packet.taskBaseSha;
      };
      for (final work in [race, workspace()..wrongBase = m2TestCandidate]) {
        await expectLater(
          builder(
            work,
          ).build(candidateSha: m2TestCandidate, knownLimitations: []),
          throwsStateError,
        );
      }
    },
  );
  test(
    'unchanged, forged and nonexact candidate identities deny handoff',
    () async {
      for (final candidate in [
        'HEAD',
        packet.taskBaseSha,
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      ]) {
        await expectLater(
          builder(
            workspace(),
          ).build(candidateSha: candidate, knownLimitations: []),
          throwsStateError,
        );
      }
    },
  );
}
