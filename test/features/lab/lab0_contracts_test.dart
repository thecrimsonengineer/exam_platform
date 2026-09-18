import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lab_test_fixtures.dart';

void main() {
  final validIds = [
    'lab', 'lab_1', 'd01_c01', 'scene.start', 'route-a',
    'gate_001', 'evidence.sds', 'worker_1', 'state_flag', 'v1',
  ];

  for (var i = 0; i < validIds.length; i++) {
    test('LAB-0 canonical valid ' + (i + 1).toString(), () {
      expect(LabIds.isCanonical(validIds[i]), isTrue);
    });
  }

  final invalidIds = [
    '', 'LAB', 'Has Space', '_starts', '-starts',
    '.starts', 'two..dots', 'slash/id', 'emoji_🧪', 'white space',
  ];

  for (var i = 0; i < invalidIds.length; i++) {
    test('LAB-0 canonical invalid ' + (i + 1).toString(), () {
      expect(LabIds.isCanonical(invalidIds[i]), isFalse);
    });
  }

  final lifecycleCases = <String, LabLifecycleStatus>{
    'DRAFT': LabLifecycleStatus.draft,
    'REVIEW': LabLifecycleStatus.review,
    'VALIDATED': LabLifecycleStatus.validated,
    'PUBLISHED': LabLifecycleStatus.published,
  };

  var lifecycleIndex = 0;
  for (final entry in lifecycleCases.entries) {
    lifecycleIndex++;
    final index = lifecycleIndex;
    test('LAB-0 lifecycle parse ' + index.toString(), () {
      expect(parseLabLifecycle(entry.key), entry.value);
    });
  }

  test('LAB-0 lifecycle transition policy', () {
    expect(
      LabLifecyclePolicy.canTransition(
        LabLifecycleStatus.draft,
        LabLifecycleStatus.review,
      ),
      isTrue,
    );
    expect(
      LabLifecyclePolicy.canTransition(
        LabLifecycleStatus.published,
        LabLifecycleStatus.draft,
      ),
      isFalse,
    );
  });

  final modes = ['GUIDED', 'PROFESSIONAL', 'ASSESSMENT'];
  for (var i = 0; i < modes.length; i++) {
    test('LAB-0 mode contract ' + (i + 1).toString(), () {
      expect(parseLabMode(modes[i]), isA<LabMode>());
    });
  }

  final qualities = ['OPTIMAL', 'DEFENSIBLE', 'WEAK', 'CRITICAL'];
  for (var i = 0; i < qualities.length; i++) {
    test('LAB-0 decision quality ' + (i + 1).toString(), () {
      expect(parseDecisionQuality(qualities[i]), isA<LabDecisionQuality>());
    });
  }

  final stateKinds = [
    'BOOLEAN', 'BOUNDED_NUMERIC', 'ENUM',
    'STRING_ID', 'STRING_SET', 'STRING_LIST',
  ];
  for (var i = 0; i < stateKinds.length; i++) {
    test('LAB-0 state kind ' + (i + 1).toString(), () {
      expect(parseStateKind(stateKinds[i]), isA<LabStateKind>());
    });
  }

  final endings = [
    'SAFE_COMPLETION',
    'CONTROLLED_RECOVERY',
    'INCIDENT_CONTAINED',
    'MAJOR_INCIDENT',
    'CRITICAL_FAILURE',
  ];
  for (var i = 0; i < endings.length; i++) {
    test('LAB-0 ending family ' + (i + 1).toString(), () {
      expect(parseEndingFamily(endings[i]), isA<LabEndingFamily>());
    });
  }

  test('LAB-0 schema version is frozen v1', () {
    expect(kLabSchemaVersion, 'csp11.lab.v1');
  });

  test('LAB-0 decision requires exactly four options', () {
    final package = buildPackage();
    final node = package.nodes.single as LabDecisionNode;
    expect(node.options, hasLength(4));
  });

  test('LAB-0 decision requires exactly one BEST option', () {
    final package = buildPackage();
    final node = package.nodes.single as LabDecisionNode;
    expect(node.options.where((option) => option.isBest), hasLength(1));
  });

  test('LAB-0 option routing is consequence-first', () {
    final package = buildPackage();
    final node = package.nodes.single as LabDecisionNode;
    expect(node.options.every((option) => option.consequence != null), isTrue);
  });

  test('LAB-0 published package is immutable', () {
    final package = buildPackage(lifecycle: LabLifecycleStatus.published);
    expect(
      () => package.replaceNodes(package.nodes),
      throwsA(isA<LabContractException>()),
    );
  });

  test('LAB-0 executable JSON is rejected', () {
    expect(
      () => LabPackage.fromJson({
        'schemaVersion': kLabSchemaVersion,
        'script': 'unsafe',
      }),
      throwsA(isA<LabContractException>()),
    );
  });

  test('LAB-0 unknown schema version is rejected', () {
    expect(
      () => LabPackage.fromJson({'schemaVersion': 'csp11.lab.v999'}),
      throwsA(isA<LabContractException>()),
    );
  });
}
