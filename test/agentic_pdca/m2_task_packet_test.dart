import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/agentic_pdca/m2_task_packet.dart';
import 'm2_test_support.dart';

void main() {
  test('packet cannot weaken the mandatory handoff inventory', () {
    expect(
      () => M2TaskPacket.fromJson(
        packetJson()..['expected_handoff'] = ['task_id'],
      ),
      throwsFormatException,
    );
  });
  test(
    'packet roundtrip and SHA-256 are deterministic across object key order',
    () {
      final source = packetJson();
      final packet = M2TaskPacket.fromJson(source);
      final reversed = {
        for (final key in source.keys.toList().reversed) key: source[key],
      };
      expect(M2TaskPacket.fromJson(reversed).hash, packet.hash);
      expect(
        M2TaskPacket.parse(packet.canonicalJson).canonicalJson,
        packet.canonicalJson,
      );
      expect(
        packet.hash,
        sha256.convert(utf8.encode(packet.canonicalJson)).toString(),
      );
    },
  );
  test(
    'caller mutation cannot alter packet or nested budgets after DO binding',
    () {
      final source = packetJson();
      final packet = M2TaskPacket.fromJson(source);
      final original = packet.hash;
      (source['allowed_paths'] as List).add('lib/main.dart');
      (source['repair_budgets'] as Map)['F1'] = 99;
      expect(packet.hash, original);
      expect(
        () => (packet.toJson()['repair_budgets'] as Map)['F1'] = 99,
        throwsUnsupportedError,
      );
      expect(
        () => packet.strings('allowed_paths').clear(),
        throwsUnsupportedError,
      );
    },
  );
  test('every required field is required; unknown fields fail closed', () {
    for (final key in packetJson().keys) {
      final source = packetJson()..remove(key);
      expect(
        () => M2TaskPacket.fromJson(source),
        throwsFormatException,
        reason: key,
      );
    }
    expect(
      () => M2TaskPacket.fromJson(packetJson()..['shell'] = 'arbitrary'),
      throwsFormatException,
    );
  });
  test(
    'wrong frozen identity, ambiguous risk, revision and base fail closed',
    () {
      for (final entry in {
        'plan_sha': m2TestCandidate,
        'governance_sha': m2TestCandidate,
        'phase_base_sha': m2TestCandidate,
        'task_base_sha': 'HEAD',
        'risk_class': 'security',
        'revision': 0,
        'maturity': 'M3',
        'branch': 'main',
      }.entries) {
        expect(
          () => M2TaskPacket.fromJson(packetJson()..[entry.key] = entry.value),
          throwsFormatException,
          reason: entry.key,
        );
      }
    },
  );
  test(
    'scope traversal, app paths, wildcard expansion and prefix tricks fail closed',
    () {
      for (final path in [
        'lib/main.dart',
        'tool/agentic_pdca/../main.dart',
        '/tmp/m2_a.dart',
        r'tool\agentic_pdca\m2_a.dart',
        'tool/agentic_pdca/**',
        'tool/agentic_pdca_extra/m2_a.dart',
        'pubspec.yaml',
      ]) {
        expect(
          () => M2TaskPacket.fromJson(packetJson()..['allowed_paths'] = [path]),
          throwsFormatException,
          reason: path,
        );
      }
    },
  );
  test(
    'overlapping forbidden paths reject packet, including narrower descendants',
    () {
      final source = packetJson();
      (source['forbidden_paths'] as List).add(
        'docs/agentic/implementation/m2/private/**',
      );
      expect(() => M2TaskPacket.fromJson(source), throwsFormatException);
    },
  );
  test('budget increases, zero-budget repairs and absent gates rejected', () {
    for (final key in M2TaskPacket.budgetCaps.keys) {
      final source = packetJson();
      (source['repair_budgets'] as Map)[key] =
          M2TaskPacket.budgetCaps[key]! + 1;
      expect(() => M2TaskPacket.fromJson(source), throwsFormatException);
    }
    final source = packetJson();
    (source['permitted_repair_classes'] as List).add('F9');
    expect(() => M2TaskPacket.fromJson(source), throwsFormatException);
    expect(
      () => M2TaskPacket.fromJson(
        packetJson()..['required_check_gates'] = ['TEST'],
      ),
      throwsFormatException,
    );
  });
  test('changed requirements and revisions change hash', () {
    final packet = testPacket();
    expect(
      M2TaskPacket.fromJson(packetJson()..['revision'] = 2).hash,
      isNot(packet.hash),
    );
    expect(
      M2TaskPacket.fromJson(
        packetJson()..['feature_objective'] = 'Changed objective',
      ).hash,
      isNot(packet.hash),
    );
  });
}
