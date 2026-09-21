import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/fr7_package_publish/fr7_package_publish_core.dart';

void main() {
  const builder = Fr7PackageBuilder();

  test('FR7 content and question packages are byte deterministic', () {
    final first = builder.build(
      contentRows: _contentRows(),
      questionRows: _questionRows(),
    );
    final second = builder.build(
      contentRows: _contentRows().reversed,
      questionRows: _questionRows().reversed,
    );

    expect(first.toEvidenceJson(), second.toEvidenceJson());
    for (var index = 0; index < first.packages.length; index++) {
      expect(
        first.packages[index].artifact.compressedBytes,
        second.packages[index].artifact.compressedBytes,
      );
    }
  });

  test('FR7 selects latest content and latest version per question ID', () {
    final plan = builder.build(
      contentRows: _contentRows(),
      questionRows: _questionRows(),
    );

    final competency = plan.competencies.single;
    final contentJson =
        jsonDecode(
              utf8.decode(
                gzip.decode(competency.content.artifact.compressedBytes),
              ),
            )
            as Map<String, dynamic>;
    final questionsJson =
        jsonDecode(
              utf8.decode(
                gzip.decode(competency.questions.artifact.compressedBytes),
              ),
            )
            as Map<String, dynamic>;

    expect(contentJson['sourceVersion'], 2);
    final questions = questionsJson['questions'] as List<dynamic>;
    expect(questions.length, 2);
    expect((questions[0] as Map<String, dynamic>)['id'], 10);
    expect((questions[0] as Map<String, dynamic>)['version'], 2);
    expect((questions[1] as Map<String, dynamic>)['id'], 11);
  });

  test('FR7 initial package revisions start at one with immutable paths', () {
    final plan = builder.build(
      contentRows: _contentRows(),
      questionRows: _questionRows(),
    );

    final competency = plan.competencies.single;
    expect(competency.content.version, 1);
    expect(competency.questions.version, 1);
    expect(competency.content.storagePath, 'content/d01_c01/v1.json.gz');
    expect(competency.questions.storagePath, 'questions/d01_c01/v1.json.gz');
    expect(plan.newPackageCount, 2);
    expect(plan.reusedPackageCount, 0);
  });

  test('FR7 unchanged checksums reuse registered immutable packages', () {
    final initial = builder.build(
      contentRows: _contentRows(),
      questionRows: _questionRows(),
    );
    final history = initial.packages.map(_historyRow).toList(growable: false);

    final repeated = builder.build(
      contentRows: _contentRows(),
      questionRows: _questionRows(),
      existingPackageRows: history,
    );

    expect(repeated.newPackageCount, 0);
    expect(repeated.reusedPackageCount, 2);
    expect(repeated.competencies.single.content.version, 1);
    expect(repeated.competencies.single.questions.version, 1);
  });

  test('FR7 changed package increments revision without overwrite', () {
    final initial = builder.build(
      contentRows: _contentRows(),
      questionRows: _questionRows(),
    );
    final history = initial.packages.map(_historyRow).toList(growable: false);

    final changed = _questionRows();
    (changed.last['source_payload'] as Map<String, dynamic>)['question'] =
        'Changed published learner question';

    final repeated = builder.build(
      contentRows: _contentRows(),
      questionRows: changed,
      existingPackageRows: history,
    );

    expect(repeated.competencies.single.content.version, 1);
    expect(repeated.competencies.single.questions.version, 2);
    expect(
      repeated.competencies.single.questions.storagePath,
      'questions/d01_c01/v2.json.gz',
    );
  });

  test('FR7 rollback reuses a known historical checksum', () {
    final v1 = builder.build(
      contentRows: _contentRows(),
      questionRows: _questionRows(),
    );
    final history = v1.packages.map(_historyRow).toList(growable: true);

    final changedRows = _questionRows();
    (changedRows.last['source_payload'] as Map<String, dynamic>)['question'] =
        'Changed published learner question';
    final v2 = builder.build(
      contentRows: _contentRows(),
      questionRows: changedRows,
      existingPackageRows: history,
    );
    history.add(_historyRow(v2.competencies.single.questions, isCurrent: true));

    final rollback = builder.build(
      contentRows: _contentRows(),
      questionRows: _questionRows(),
      existingPackageRows: history,
    );

    expect(rollback.competencies.single.questions.version, 1);
    expect(
      rollback.competencies.single.questions.reusesExistingPackage,
      isTrue,
    );
  });

  test('FR7 fails closed when a competency lacks content or questions', () {
    expect(
      () => builder.build(
        contentRows: _contentRows(),
        questionRows: const <Map<String, dynamic>>[],
      ),
      throwsStateError,
    );
  });

  test('FR7 fails closed on duplicate latest question version', () {
    final rows = _questionRows();
    rows.add(Map<String, dynamic>.from(rows[1]));

    expect(
      () => builder.build(contentRows: _contentRows(), questionRows: rows),
      throwsStateError,
    );
  });
}

List<Map<String, dynamic>> _contentRows() => <Map<String, dynamic>>[
  <String, dynamic>{
    'content_id': 'content-a',
    'version': 1,
    'competency_id': 'd01_c01',
    'status': 'published',
    'content_payload': <String, dynamic>{
      'id': 'content-a',
      'competencyId': 'd01_c01',
      'version': 1,
      'topics': <dynamic>[],
    },
  },
  <String, dynamic>{
    'content_id': 'content-a',
    'version': 2,
    'competency_id': 'd01_c01',
    'status': 'published',
    'content_payload': <String, dynamic>{
      'id': 'content-a',
      'competencyId': 'd01_c01',
      'version': 2,
      'topics': <dynamic>[
        <String, dynamic>{'id': 'topic-1'},
      ],
    },
  },
];

List<Map<String, dynamic>> _questionRows() => <Map<String, dynamic>>[
  _questionRow(id: 10, version: 1, text: 'Older question'),
  _questionRow(id: 10, version: 2, text: 'Current question'),
  _questionRow(id: 11, version: 1, text: 'Second question'),
];

Map<String, dynamic> _questionRow({
  required int id,
  required int version,
  required String text,
}) => <String, dynamic>{
  'question_id': id,
  'version': version,
  'competency_id': 'd01_c01',
  'status': 'published',
  'source_payload': <String, dynamic>{
    'id': id,
    'version': version,
    'competencyId': 'd01_c01',
    'question': text,
    'options': const <String>['A', 'B', 'C', 'D'],
    'correctAnswer': 0,
  },
};

Map<String, dynamic> _historyRow(
  Fr7PlannedPackage package, {
  bool isCurrent = false,
}) => <String, dynamic>{
  'package_kind': package.kind,
  'package_key': package.competencyId,
  'version': package.version,
  'storage_bucket': fr7BucketId,
  'storage_path': package.storagePath,
  'checksum_sha256': package.artifact.checksumSha256,
  'compressed_bytes': package.artifact.compressedByteCount,
  'item_count': package.artifact.itemCount,
  'is_current': isCurrent,
};
