import 'package:flutter_test/flutter_test.dart';

import '../../tool/agentic_pdca/m2_bounded_authority.dart';
import '../../tool/agentic_pdca/m2_task_packet.dart';
import 'm2_test_support.dart';

void main() {
  final packet = testPacket();
  M2BuilderRequest request({
    String? hash,
    int revision = 1,
    int token = 7,
    String? path,
    String? head,
    String writer = 'builder',
  }) => M2BuilderRequest(
    packetHash: hash ?? packet.hash,
    revision: revision,
    expectedHead: head ?? packet.taskBaseSha,
    writerLeaseId: 'lease',
    writerIdentity: writer,
    fencingToken: token,
    requestedPaths: [path ?? packet.expectedPaths.first],
  );
  M2BoundedAuthority authority(
    M2FakeWorkspace workspace, {
    M2ApprovedManifest? manifest,
    bool conflict = false,
    bool expired = false,
    bool cancelled = false,
    String? lineageSha,
  }) => M2BoundedAuthority(
    manifest: manifest ?? testManifest(packet),
    workspace: workspace,
    trustedState: testState(
      packet,
      conflict: conflict,
      expired: expired,
      cancelled: cancelled,
      lineageSha: lineageSha,
    ),
    trustedClock: () => m2TestNow,
  );

  test(
    'approved Pilot A packet inherits M1 authority without executing mutation',
    () async {
      final workspace = M2FakeWorkspace(packet);
      expect(
        (await authority(workspace).authorize(request())).authorized,
        isTrue,
      );
      expect(workspace.head, packet.taskBaseSha);
      expect(workspace.changed, isEmpty);
    },
  );
  test(
    'forged packet, revision, base, identity, token and scope are denied',
    () async {
      for (final invalid in [
        request(hash: 'forged'),
        request(revision: 2),
        request(head: m2TestCandidate),
        request(writer: 'intruder'),
        request(token: 8),
        request(path: 'lib/main.dart'),
        request(path: 'tool/agentic_pdca/m2_unplanned.dart'),
      ]) {
        expect(
          (await authority(
            M2FakeWorkspace(packet),
          ).authorize(invalid)).authorized,
          isFalse,
        );
      }
    },
  );
  test(
    'forged, stale, future, expired and revoked approval are denied',
    () async {
      for (final manifest in [
        testManifest(packet, hash: 'forged'),
        testManifest(packet, revision: '2'),
        testManifest(packet, status: 'REVOKED'),
        testManifest(packet, issuedAt: m2TestNow.add(const Duration(days: 1))),
        testManifest(packet, expiresAt: m2TestNow),
      ]) {
        expect(
          (await authority(
            M2FakeWorkspace(packet),
            manifest: manifest,
          ).authorize(request())).authorized,
          isFalse,
        );
      }
    },
  );
  test(
    'immutable valid revised packet cannot reuse original manifest approval',
    () async {
      final revised = M2TaskPacket.fromJson(packetJson()..['revision'] = 2);
      expect(
        (await authority(
          M2FakeWorkspace(packet),
        ).authorize(request(hash: revised.hash, revision: 2))).authorized,
        isFalse,
      );
    },
  );
  test(
    'writer conflict, expired lease, cancellation and stale lineage deny DO',
    () async {
      final workspace = M2FakeWorkspace(packet);
      for (final control in [
        authority(workspace, conflict: true),
        authority(workspace, expired: true),
        authority(workspace, cancelled: true),
        authority(workspace, lineageSha: m2TestCandidate),
      ]) {
        expect((await control.authorize(request())).authorized, isFalse);
      }
    },
  );
  test(
    'dirty tracked, generated and untracked files block before DO',
    () async {
      for (final path in [
        'README.md',
        'windows/flutter/generated_plugins.cmake',
      ]) {
        final workspace = M2FakeWorkspace(packet)..dirty = [path];
        expect(
          (await authority(workspace).authorize(request())).authorized,
          isFalse,
        );
      }
      final workspace = M2FakeWorkspace(packet)..untracked = ['unexpected.txt'];
      expect(
        (await authority(workspace).authorize(request())).authorized,
        isFalse,
      );
    },
  );
  test('wrong ancestry, detached branch and branch race are denied', () async {
    final wrongBase = M2FakeWorkspace(packet)..wrongBase = m2TestCandidate;
    final detached = M2FakeWorkspace(packet)..ref = '';
    final race = M2FakeWorkspace(packet);
    race.onRead = () {
      if (race.reads == 2) race.ref = 'other';
    };
    for (final workspace in [wrongBase, detached, race]) {
      expect(
        (await authority(workspace).authorize(request())).authorized,
        isFalse,
      );
    }
  });
}
