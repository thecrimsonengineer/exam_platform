import 'package:flutter_test/flutter_test.dart';

import '../../tool/fr4_migration/fr4_migration_core.dart';
import '../../tool/fr5_shadow_parity/fr5_shadow_parity_core.dart';

void main() {
  group('FR5 expected plan', () {
    test('accepts frozen ready FR4 evidence', () {
      final fr4 = _fr4Plan();
      final expected = Fr5ExpectedPlan.fromFr4Evidence(
        _fr4Evidence(fr4),
      );

      expect(expected.rows, hasLength(2));
      expect(expected.rows.map((row) => row.targetTable), containsAll(
        <String>['content_versions', 'questions'],
      ));
    });

    test('rejects FR4 evidence that is not ready', () {
      final evidence = _fr4Evidence(_fr4Plan())
        ..['readyToApply'] = false;

      expect(
        () => Fr5ExpectedPlan.fromFr4Evidence(evidence),
        throwsStateError,
      );
    });

    test('rejects tampered target checksum', () {
      final evidence = _fr4Evidence(_fr4Plan());
      final rows = evidence['rows'] as List<dynamic>;
      final first = Map<String, dynamic>.from(rows.first as Map)
        ..['targetChecksumSha256'] = '0' * 64;
      rows[0] = first;

      expect(
        () => Fr5ExpectedPlan.fromFr4Evidence(evidence),
        throwsStateError,
      );
    });
  });

  group('FR5 shadow parity engine', () {
    test('passes exact row, learner-visible and ledger parity', () {
      final expected = Fr5ExpectedPlan.fromFr4Evidence(
        _fr4Evidence(_fr4Plan()),
      );
      final targetRows = expected.rows
          .map(
            (row) => Fr5TargetRow(
              table: row.targetTable,
              row: <String, dynamic>{
                ...row.row,
                'created_at': '2099-01-01T00:00:00Z',
                'updated_at': '2099-01-01T00:00:00Z',
              },
            ),
          )
          .toList(growable: false);

      final report = const Fr5ShadowParityEngine().compare(
        expected: expected,
        targetRows: targetRows,
        ledgerRows: <Map<String, dynamic>>[],
      );

      expect(report.completeParity, isFalse);
      expect(report.matchedRowCount, expected.rows.length);
      expect(report.learnerVisibleMatchedCount, expected.rows.length);
      expect(report.countKind('missing_ledger'), expected.rows.length);

      final withLedger = const Fr5ShadowParityEngine().compare(
        expected: expected,
        targetRows: targetRows,
        ledgerRows: expected.rows
            .map(fr5MatchedLedgerRow)
            .toList(growable: false),
      );

      expect(withLedger.completeParity, isTrue);
      expect(withLedger.issues, isEmpty);
    });

    test('detects missing and extra target rows', () {
      final expected = Fr5ExpectedPlan.fromFr4Evidence(
        _fr4Evidence(_fr4Plan()),
      );
      final first = expected.rows.first;
      final targetRows = <Fr5TargetRow>[
        Fr5TargetRow(table: first.targetTable, row: first.row),
        const Fr5TargetRow(
          table: 'questions',
          row: <String, dynamic>{
            'question_id': 999999,
            'version': 1,
          },
        ),
      ];

      final report = const Fr5ShadowParityEngine().compare(
        expected: expected,
        targetRows: targetRows,
        ledgerRows: <Map<String, dynamic>>[],
      );

      expect(report.completeParity, isFalse);
      expect(report.countKind('missing_target'), 1);
      expect(report.countKind('extra_target'), 1);
    });

    test('detects target checksum and learner-visible mismatch', () {
      final expected = Fr5ExpectedPlan.fromFr4Evidence(
        _fr4Evidence(_fr4Plan()),
      );
      final question = expected.rows.firstWhere(
        (row) => row.targetTable == 'questions',
      );
      final changed = <String, dynamic>{
        ...question.row,
        'stem': 'Changed learner-visible stem',
      };

      final report = const Fr5ShadowParityEngine().compare(
        expected: expected,
        targetRows: <Fr5TargetRow>[
          Fr5TargetRow(table: 'questions', row: changed),
        ],
        ledgerRows: <Map<String, dynamic>>[],
      );

      expect(report.countKind('checksum_mismatch'), 1);
      expect(report.countKind('learner_visible_mismatch'), 1);
    });

    test('detects duplicate target identity', () {
      final expected = Fr5ExpectedPlan.fromFr4Evidence(
        _fr4Evidence(_fr4Plan()),
      );
      final row = expected.rows.first;

      final report = const Fr5ShadowParityEngine().compare(
        expected: expected,
        targetRows: <Fr5TargetRow>[
          Fr5TargetRow(table: row.targetTable, row: row.row),
          Fr5TargetRow(table: row.targetTable, row: row.row),
        ],
        ledgerRows: <Map<String, dynamic>>[],
      );

      expect(report.countKind('duplicate_target'), 1);
    });

    test('detects ledger checksum mismatch and extra ledger evidence', () {
      final expected = Fr5ExpectedPlan.fromFr4Evidence(
        _fr4Evidence(_fr4Plan()),
      );
      final targetRows = expected.rows
          .map(
            (row) => Fr5TargetRow(
              table: row.targetTable,
              row: row.row,
            ),
          )
          .toList(growable: false);

      final badLedger = expected.rows
          .map(fr5MatchedLedgerRow)
          .toList(growable: true);
      badLedger[0] = <String, dynamic>{
        ...badLedger[0],
        'target_checksum_sha256': '0' * 64,
      };
      badLedger.add(<String, dynamic>{
        'source_system': 'firestore',
        'source_collection': 'questions',
        'source_id': 'unexpected',
        'target_table': 'questions',
        'target_key': '999|v1',
        'source_checksum_sha256': '1' * 64,
        'target_checksum_sha256': '2' * 64,
        'validation_status': 'matched',
      });

      final report = const Fr5ShadowParityEngine().compare(
        expected: expected,
        targetRows: targetRows,
        ledgerRows: badLedger,
      );

      expect(report.countKind('ledger_mismatch'), 1);
      expect(report.countKind('extra_ledger'), 1);
      expect(report.completeParity, isFalse);
    });
  });

  group('FR5 learner-visible projection', () {
    test('content payload preserves decoded nested lists', () {
      final expected = Fr5ExpectedPlan.fromFr4Evidence(
        _fr4Evidence(_fr4Plan()),
      );
      final content = expected.rows.firstWhere(
        (row) => row.targetTable == 'content_versions',
      );
      final payload = content.row['content_payload'] as Map<String, dynamic>;
      final topics = payload['topics'] as List<dynamic>;
      final subtopics =
          (topics.first as Map<String, dynamic>)['subtopics'] as List<dynamic>;
      final blocks =
          (subtopics.first as Map<String, dynamic>)['blocks'] as List<dynamic>;
      final data =
          (blocks.first as Map<String, dynamic>)['data'] as Map<String, dynamic>;

      expect(
        data['rows'],
        <dynamic>[
          <String>['Aspect', 'Impact'],
          <String>['Fuel spill', 'Soil contamination'],
        ],
      );
    });
  });
}

Fr4MigrationPlan _fr4Plan() {
  return const Fr4MigrationEngine().build(<Fr4SourceDocument>[
    Fr4SourceDocument(
      collection: 'contentVersions',
      id: 'published_d07_c01',
      data: <String, dynamic>{
        'id': 'd07_c01-v1',
        'domainId': 'd07',
        'competencyId': 'd07_c01',
        'competencyNumber': 1,
        'title': 'Environmental Management',
        'status': 'published',
        'version': 1,
        'copyType': 'published',
        'topics': <dynamic>[
          <String, dynamic>{
            'id': 'd07_c01_t01',
            'title': 'Environmental foundations',
            'subtopics': <dynamic>[
              <String, dynamic>{
                'id': 'd07_c01_t01_s01',
                'title': 'Environmental aspects',
                'blocks': <dynamic>[
                  <String, dynamic>{
                    'id': 'table_1',
                    'type': 'table',
                    'data': <String, dynamic>{
                      'rows': <String, dynamic>{
                        'csp11FirestoreNestedListV1': true,
                        'items': <String, dynamic>{
                          '0': <String>['Aspect', 'Impact'],
                          '1': <String>[
                            'Fuel spill',
                            'Soil contamination',
                          ],
                        },
                      },
                    },
                  },
                ],
              },
            ],
          },
        ],
      },
    ),
    Fr4SourceDocument(
      collection: 'questions',
      id: 'question_7001001',
      data: <String, dynamic>{
        'id': 7001001,
        'domain': 7,
        'competencyId': 'd07_c01',
        'subtopicId': 'd07_c01_t01_s01',
        'topicId': 'd07_c01_t01',
        'quizId': 'd07_c01_t01_s01_quiz',
        'contentPackageId': 'd07_c01-v1',
        'question':
            'During a site inspection, a recurring diesel leak reaches bare '
            'soil. Which action is the BEST immediate response?',
        'options': <String>[
          'Record it for the annual review',
          'Stop the release and contain the spill',
          'Wait for laboratory sampling',
          'Move the inspection to another area',
        ],
        'correctAnswer': 1,
        'explanation':
            'Source control and containment prevent further environmental harm.',
        'bestAnswerRationale':
            'It controls the active release before longer-term investigation.',
        'reference': 'CSP11 controlled source',
        'difficulty': 'Hard',
        'cognitiveLevel': 'application',
        'questionType': 'scenario_mcq',
        'status': 'published',
        'version': 1,
        'tags': <String>['environmental aspect', 'spill control'],
      },
    ),
  ]);
}

Map<String, dynamic> _fr4Evidence(Fr4MigrationPlan plan) {
  return <String, dynamic>{
    ...plan.toJson(),
    'sourceMode': 'test',
    'applyRequested': false,
  };
}
