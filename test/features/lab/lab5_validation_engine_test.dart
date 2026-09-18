import 'dart:convert';

import 'package:exam_platform/features/lab/lab_validation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lab_l2_test_fixtures.dart';

Map<String, Object?> _map(Object? value) =>
    (value as Map).cast<String, Object?>();

List<Object?> _list(Object? value) => (value as List).cast<Object?>();

LabValidationReport _validate(
  Map<String, Object?> root, {
  Set<String>? assets,
}) => const LabValidationEngine().validateSource(
  jsonEncode(root),
  availableAssetIds: assets,
  allowedCompetencyIds: const <String>{'d07_c01'},
);

void main() {
  for (var i = 0; i < 20; i++) {
    test('LAB-5 valid deterministic package ' + (i + 1).toString(), () {
      final root = copyL2Root();
      _map(root['lab'])['title'] = 'Valid LAB ' + i.toString();
      final report = _validate(root);
      expect(report.isValid, isTrue);
      expect(report.errorCount, 0);
      expect(report.deterministic, isTrue);
      expect(report.simulationCount, greaterThan(0));
    });
  }

  for (var i = 0; i < 20; i++) {
    test('LAB-5 four option and BEST validation ' + (i + 1).toString(), () {
      final root = copyL2Root();
      final node = _map(_list(root['nodes']).first);
      final options = _list(node['options']);
      if (i < 10) {
        options.removeLast();
        final report = _validate(root);
        expect(report.hasCode('four_options'), isTrue);
      } else {
        _map(options[1])['isBest'] = true;
        final report = _validate(root);
        expect(report.hasCode('best_uniqueness'), isTrue);
      }
    });
  }

  for (var i = 0; i < 20; i++) {
    test('LAB-5 reference validation ' + (i + 1).toString(), () {
      final root = copyL2Root();
      final bucket = i % 4;

      if (bucket == 0) {
        _map(_list(root['gates'])[1])['targetNodeId'] = 'missing_node';
        expect(_validate(root).hasCode('gate_target_reference'), isTrue);
      } else if (bucket == 1) {
        final option = _map(
          _list(_map(_list(root['nodes']).first)['options']).first,
        );
        option['consequenceId'] = 'missing_consequence';
        expect(_validate(root).hasCode('consequence_reference'), isTrue);
      } else if (bucket == 2) {
        final consequence = _map(_list(root['consequences']).first);
        final mutation = _map(_list(consequence['mutations']).first);
        mutation['stateId'] = 'missing_state';
        expect(_validate(root).hasCode('state_reference'), isTrue);
      } else {
        _map(_list(root['gates'])[2])['endingId'] = 'missing_end';
        expect(_validate(root).hasCode('ending_reference'), isTrue);
      }
    });
  }

  for (var i = 0; i < 20; i++) {
    test('LAB-5 graph reachability and dead end ' + (i + 1).toString(), () {
      final root = copyL2Root();
      if (i < 10) {
        _list(root['nodes']).add(<String, Object?>{
          'id': 'orphan_scene',
          'type': 'SCENE',
          'text': 'Unreachable authored scene.',
        });
        expect(_validate(root).hasCode('orphan_node'), isTrue);
      } else {
        _list(root['gates']).removeAt(2);
        final report = _validate(root);
        expect(report.hasCode('dead_end'), isTrue);
        expect(report.hasCode('ending_unreachable'), isTrue);
      }
    });
  }

  for (var i = 0; i < 20; i++) {
    test('LAB-5 unsafe cycle detection ' + (i + 1).toString(), () {
      final root = copyL2Root();
      final completion = _map(_list(root['gates'])[2]);
      completion['type'] = 'ROUTE';
      completion['targetNodeId'] = 'decision_one';
      completion.remove('endingId');

      final report = _validate(root);
      expect(report.hasCode('unsafe_cycle'), isTrue);
      expect(report.hasCode('ending_unreachable'), isTrue);
    });
  }

  for (var i = 0; i < 20; i++) {
    test('LAB-5 gate ambiguity and priority ' + (i + 1).toString(), () {
      final root = copyL2Root();
      _list(root['gates']).add(<String, Object?>{
        'id': 'extra_route',
        'type': 'ROUTE',
        'priority': i < 10 ? 10 : 1,
        'fromNodeId': 'decision_one',
        'targetNodeId': 'decision_two',
        'condition': <String, Object?>{'op': 'ALWAYS'},
      });

      final report = _validate(root);
      if (i < 10) {
        expect(report.hasCode('gate_ambiguity'), isTrue);
      } else {
        expect(report.isValid, isTrue);
        expect(report.deterministic, isTrue);
      }
    });
  }

  for (var i = 0; i < 20; i++) {
    test(
      'LAB-5 evidence asset competency source validation ' + (i + 1).toString(),
      () {
        final root = copyL2Root();
        final bucket = i % 4;

        if (bucket == 0) {
          root['evidence'] = <Object?>[];
          expect(_validate(root).hasCode('evidence_reference'), isTrue);
        } else if (bucket == 1) {
          final evidence = _map(_list(root['evidence']).first);
          evidence['assetId'] = 'permit_asset';
          evidence['required'] = true;
          expect(
            _validate(
              root,
              assets: const <String>{},
            ).hasCode('asset_unavailable'),
            isTrue,
          );
        } else if (bucket == 2) {
          root['competencyMappings'] = <String>['invalid_mapping'];
          expect(_validate(root).hasCode('competency_mapping'), isTrue);
        } else {
          root['sources'] = <String>[];
          expect(_validate(root).hasCode('source_reference'), isTrue);
        }
      },
    );
  }

  for (var i = 0; i < 30; i++) {
    test('LAB-5 deterministic path simulation ' + (i + 1).toString(), () {
      final simulator = const LabPathSimulator();
      final package = buildL2Package();
      final limit = i < 15 ? i + 1 : 1000;
      final first = simulator.run(package, limit: limit);
      final second = simulator.run(package, limit: limit);

      expect(first.fingerprint, second.fingerprint);
      expect(first.traversalCount, second.traversalCount);
      expect(first.traversalCount, lessThanOrEqualTo(limit));
      expect(first.reachableNodeIds, contains('decision_one'));
      if (limit >= 4) {
        expect(first.reachableNodeIds, contains('decision_two'));
      }
    });
  }
}
