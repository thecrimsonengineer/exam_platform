import 'dart:convert';

import 'package:exam_platform/features/lab/lab_contracts.dart';
import 'package:exam_platform/features/lab/lab_studio.dart';

Map<String, Object?> buildL2Root({
  String versionId = 'v1',
  String lifecycle = 'DRAFT',
}) {
  Map<String, Object?> consequence(
    String id,
    String route,
    int risk, {
    bool unlockPermit = false,
  }) => <String, Object?>{
    'id': id,
    'mutations': <Object?>[
      <String, Object?>{'op': 'SET', 'stateId': 'route', 'value': route},
      <String, Object?>{'op': 'SET', 'stateId': 'risk', 'value': risk},
    ],
    'evidenceUnlocks': unlockPermit ? <String>['permit'] : <String>[],
    'simulatedMinutes': 2,
  };

  Map<String, Object?> option(
    String id,
    String consequenceId,
    String quality, {
    bool best = false,
  }) => <String, Object?>{
    'id': id,
    'text': 'Authored option ' + id,
    'isBest': best,
    'quality': quality,
    'consequenceId': consequenceId,
  };

  return <String, Object?>{
    'schemaVersion': 'csp11.lab.v1',
    'lab': <String, Object?>{
      'id': 'l2_lab',
      'versionId': versionId,
      'title': 'L2 deterministic validation LAB',
      'description':
          'A compact two-decision LAB used to validate the L2 engine.',
      'lifecycle': lifecycle,
      'supportedModes': <String>['GUIDED', 'PROFESSIONAL', 'ASSESSMENT'],
      'startingNodeId': 'decision_one',
      'startingState': <String, Object?>{
        'isolated': false,
        'risk': 0,
        'route': 'start',
        'notes': <String>[],
      },
    },
    'stateSchema': <String, Object?>{
      'isolated': <String, Object?>{'type': 'BOOLEAN', 'irreversible': true},
      'risk': <String, Object?>{'type': 'BOUNDED_NUMERIC', 'min': 0, 'max': 10},
      'route': <String, Object?>{
        'type': 'ENUM',
        'allowedValues': <String>['start', 'safe', 'critical'],
      },
      'notes': <String, Object?>{'type': 'STRING_SET'},
    },
    'characters': <Object?>[],
    'evidence': <Object?>[
      <String, Object?>{'id': 'permit', 'type': 'permit', 'required': false},
    ],
    'consequences': <Object?>[
      consequence('c_safe', 'safe', 1, unlockPermit: true),
      consequence('c_defensible', 'safe', 2),
      consequence('c_weak', 'safe', 3),
      consequence('c_critical', 'critical', 9),
      consequence('c_end_best', 'safe', 0),
      consequence('c_end_defensible', 'safe', 1),
      consequence('c_end_weak', 'safe', 2),
      consequence('c_end_critical', 'critical', 8),
    ],
    'nodes': <Object?>[
      <String, Object?>{
        'id': 'decision_one',
        'type': 'DECISION',
        'prompt': 'What should you do first?',
        'options': <Object?>[
          option('o1', 'c_safe', 'OPTIMAL', best: true),
          option('o2', 'c_defensible', 'DEFENSIBLE'),
          option('o3', 'c_weak', 'WEAK'),
          option('o4', 'c_critical', 'CRITICAL'),
        ],
      },
      <String, Object?>{
        'id': 'decision_two',
        'type': 'DECISION',
        'prompt': 'How should the situation be closed out?',
        'options': <Object?>[
          option('o5', 'c_end_best', 'OPTIMAL', best: true),
          option('o6', 'c_end_defensible', 'DEFENSIBLE'),
          option('o7', 'c_end_weak', 'WEAK'),
          option('o8', 'c_end_critical', 'CRITICAL'),
        ],
      },
    ],
    'gates': <Object?>[
      <String, Object?>{
        'id': 'critical_route',
        'type': 'CRITICAL_EVENT',
        'priority': 100,
        'fromNodeId': 'decision_one',
        'targetNodeId': 'decision_two',
        'condition': <String, Object?>{
          'op': 'ENUM',
          'stateId': 'route',
          'equals': 'critical',
        },
      },
      <String, Object?>{
        'id': 'normal_route',
        'type': 'ROUTE',
        'priority': 10,
        'fromNodeId': 'decision_one',
        'targetNodeId': 'decision_two',
        'condition': <String, Object?>{'op': 'ALWAYS'},
      },
      <String, Object?>{
        'id': 'complete',
        'type': 'COMPLETION',
        'priority': 10,
        'fromNodeId': 'decision_two',
        'endingId': 'safe_end',
        'condition': <String, Object?>{'op': 'ALWAYS'},
      },
    ],
    'endings': <Object?>[
      <String, Object?>{
        'id': 'safe_end',
        'family': 'SAFE_COMPLETION',
        'title': 'Safe completion',
      },
    ],
    'competencyMappings': <String>['d07_c01'],
    'sources': <String>['HSE L101'],
    'debrief': <String, Object?>{},
    'learningSignals': <String, Object?>{},
  };
}

String buildL2Source({String versionId = 'v1', String lifecycle = 'DRAFT'}) =>
    jsonEncode(buildL2Root(versionId: versionId, lifecycle: lifecycle));

LabPackage buildL2Package({
  String versionId = 'v1',
  String lifecycle = 'DRAFT',
}) => LabPackage.decode(
  buildL2Source(versionId: versionId, lifecycle: lifecycle),
);

Map<String, Object?> copyL2Root() {
  final decoded = jsonDecode(jsonEncode(buildL2Root()));
  return (decoded as Map).cast<String, Object?>();
}

Lab1000StudioService buildL2StudioService() =>
    Lab1000StudioService(repository: InMemoryLabPublishedRepository());
