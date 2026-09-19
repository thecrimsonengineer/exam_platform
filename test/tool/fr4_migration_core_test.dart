import 'package:flutter_test/flutter_test.dart';

import '../../tool/fr4_migration/fr4_migration_core.dart';

void main() {
  group('FR4 deterministic canonicalization', () {
    test('map key order does not change checksum', () {
      final left = <String, dynamic>{
        'b': 2,
        'a': <String, dynamic>{'z': 9, 'y': 8},
      };
      final right = <String, dynamic>{
        'a': <String, dynamic>{'y': 8, 'z': 9},
        'b': 2,
      };

      expect(fr4CanonicalJson(left), fr4CanonicalJson(right));
      expect(fr4Sha256(left), fr4Sha256(right));
      expect(fr4Sha256(left), hasLength(64));
    });

    test('decodes CSP11 nested-array marker before hashing', () {
      final decoded = decodeCsp11FirestoreSafe(<String, dynamic>{
        'rows': <String, dynamic>{
          'csp11FirestoreNestedListV1': true,
          'items': <String, dynamic>{
            '1': <String>['c', 'd'],
            '0': <String>['a', 'b'],
          },
        },
      });

      expect(
        decoded,
        <String, dynamic>{
          'rows': <dynamic>[
            <String>['a', 'b'],
            <String>['c', 'd'],
          ],
        },
      );
    });
  });

  group('FR4 Firestore REST decoding', () {
    test('decodes typed Firestore fields without lossy stringification', () {
      final document = decodeFirestoreRestDocument(
        collection: 'questions',
        document: <String, dynamic>{
          'name':
              'projects/csp11/databases/(default)/documents/questions/question_7',
          'fields': <String, dynamic>{
            'id': <String, dynamic>{'integerValue': '7'},
            'published': <String, dynamic>{'booleanValue': true},
            'tags': <String, dynamic>{
              'arrayValue': <String, dynamic>{
                'values': <dynamic>[
                  <String, dynamic>{'stringValue': 'hazard'},
                  <String, dynamic>{'stringValue': 'risk'},
                ],
              },
            },
            'meta': <String, dynamic>{
              'mapValue': <String, dynamic>{
                'fields': <String, dynamic>{
                  'score': <String, dynamic>{'doubleValue': 0.75},
                },
              },
            },
          },
        },
      );

      expect(document.id, 'question_7');
      expect(document.data['id'], 7);
      expect(document.data['published'], isTrue);
      expect(document.data['tags'], <String>['hazard', 'risk']);
      expect(document.data['meta'], <String, dynamic>{'score': 0.75});
    });
  });

  group('FR4 migration plan', () {
    test('normalizes content and questions with zero issues', () {
      final plan = const Fr4MigrationEngine().build(<Fr4SourceDocument>[
        Fr4SourceDocument(
          collection: 'contentVersions',
          id: 'published_d01_c01',
          data: <String, dynamic>{
            'id': 'd01_c01-v1',
            'domainId': 'd01',
            'competencyId': 'd01_c01',
            'competencyNumber': 1,
            'title': 'Safety Management Systems',
            'status': 'published',
            'version': 1,
            'copyType': 'published',
            'topics': <dynamic>[
              <String, dynamic>{
                'id': 'd01_c01_t01',
                'title': 'Foundations',
                'subtopics': <dynamic>[],
              },
            ],
          },
        ),
        Fr4SourceDocument(
          collection: 'questions',
          id: 'question_1001',
          data: <String, dynamic>{
            'id': 1001,
            'domain': 1,
            'competencyId': 'd01_c01',
            'subtopicId': 'd01_c01_t01_s01',
            'topicId': 'd01_c01_t01',
            'quizId': 'd01_c01_t01_s01_quiz',
            'contentPackageId': 'd01_c01-v1',
            'question':
                'A supervisor finds a guard removed before startup. What is the BEST first action?',
            'options': <String>[
              'Start slowly and observe',
              'Stop startup and restore the safeguard',
              'Warn workers verbally',
              'Record it after the shift',
            ],
            'correctAnswer': 1,
            'explanation': 'The hazard must be controlled before operation.',
            'bestAnswerRationale':
                'Stopping startup prevents exposure before work begins.',
            'reference': 'CSP11 controlled source',
            'difficulty': 'Hard',
            'cognitiveLevel': 'application',
            'questionType': 'scenario_mcq',
            'status': 'published',
            'version': 1,
            'tags': <String>['machine guarding', 'pre-start'],
          },
        ),
      ]);

      expect(plan.readyToApply, isTrue);
      expect(plan.issues, isEmpty);
      expect(plan.rows, hasLength(2));
      expect(plan.sourceCounts['contentVersions'], 1);
      expect(plan.sourceCounts['questions'], 1);
      expect(plan.targetCounts['content_versions'], 1);
      expect(plan.targetCounts['questions'], 1);

      final content = plan.rows.firstWhere(
        (row) => row.targetTable == 'content_versions',
      );
      expect(content.row['content_id'], 'd01_c01-v1');
      expect(content.row['status'], 'published');
      expect(content.row['source_document_id'], 'published_d01_c01');

      final question = plan.rows.firstWhere(
        (row) => row.targetTable == 'questions',
      );
      expect(question.row['question_id'], 1001);
      expect(question.row['correct_answer'], 1);
      expect(question.row['options'], hasLength(4));
      expect(question.sourceChecksumSha256, hasLength(64));
      expect(question.targetChecksumSha256, hasLength(64));
    });

    test('fails closed on duplicate target identity', () {
      final shared = <String, dynamic>{
        'id': 10,
        'domain': 1,
        'competencyId': 'd01_c01',
        'subtopicId': '',
        'topicId': '',
        'question': 'Which action should be taken first in this safety case?',
        'options': <String>['A', 'B', 'C', 'D'],
        'correctAnswer': 0,
        'explanation': 'A',
        'reference': 'source',
        'difficulty': 'Hard',
        'cognitiveLevel': 'application',
        'questionType': 'scenario_mcq',
        'status': 'draft',
        'version': 1,
        'tags': <String>['one', 'two'],
      };

      final plan = const Fr4MigrationEngine().build(<Fr4SourceDocument>[
        Fr4SourceDocument(
          collection: 'questions',
          id: 'question_10_a',
          data: shared,
        ),
        Fr4SourceDocument(
          collection: 'questions',
          id: 'question_10_b',
          data: shared,
        ),
      ]);

      expect(plan.readyToApply, isFalse);
      expect(plan.duplicateCount, 1);
      expect(plan.rows, hasLength(1));
    });

    test('fails closed on unknown collection and malformed record', () {
      final plan = const Fr4MigrationEngine().build(<Fr4SourceDocument>[
        const Fr4SourceDocument(
          collection: 'unknownCollection',
          id: 'x',
          data: <String, dynamic>{'value': 1},
        ),
        const Fr4SourceDocument(
          collection: 'questions',
          id: 'broken',
          data: <String, dynamic>{'id': 0},
        ),
      ]);

      expect(plan.readyToApply, isFalse);
      expect(plan.unmappedCount, 1);
      expect(plan.failureCount, 1);
      expect(plan.rows, isEmpty);
    });

    test('published questions must preserve four-option invariant', () {
      final plan = const Fr4MigrationEngine().build(<Fr4SourceDocument>[
        const Fr4SourceDocument(
          collection: 'questions',
          id: 'question_99',
          data: <String, dynamic>{
            'id': 99,
            'domain': 1,
            'competencyId': 'd01_c01',
            'question': 'What is the best action?',
            'options': <String>['A', 'B', 'C'],
            'correctAnswer': 0,
            'status': 'published',
            'version': 1,
          },
        ),
      ]);

      expect(plan.readyToApply, isFalse);
      expect(plan.failureCount, 1);
    });
  });

  group('FR4 target verification', () {
    test('checks only the frozen planned projection', () {
      final plan = const Fr4MigrationEngine().build(<Fr4SourceDocument>[
        const Fr4SourceDocument(
          collection: 'questions',
          id: 'question_12',
          data: <String, dynamic>{
            'id': 12,
            'domain': 1,
            'competencyId': 'd01_c01',
            'question': 'What should be done before work starts?',
            'options': <String>['A', 'B', 'C', 'D'],
            'correctAnswer': 0,
            'status': 'draft',
            'version': 1,
          },
        ),
      ]);
      final row = plan.rows.single;

      expect(
        fr4TargetMatches(
          row,
          <String, dynamic>{
            ...row.row,
            'created_at': '2099-01-01T00:00:00Z',
            'updated_at': '2099-01-01T00:00:00Z',
          },
        ),
        isTrue,
      );

      expect(
        fr4TargetMatches(
          row,
          <String, dynamic>{...row.row, 'stem': 'changed'},
        ),
        isFalse,
      );
    });
  });
}
