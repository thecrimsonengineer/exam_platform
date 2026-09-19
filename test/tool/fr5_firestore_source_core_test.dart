import 'package:flutter_test/flutter_test.dart';

import '../../tool/fr4_migration/fr4_migration_core.dart';
import '../../tool/fr5_shadow_parity/fr5_firestore_source_core.dart';

void main() {
  Fr4SourceDocument content({
    required String sourceId,
    required String contentId,
    required int version,
    required String status,
    required String copyType,
  }) {
    return Fr4SourceDocument(
      collection: 'contentVersions',
      id: sourceId,
      data: <String, dynamic>{
        'id': contentId,
        'version': version,
        'status': status,
        'copyType': copyType,
      },
    );
  }

  Fr4SourceDocument question({
    required String sourceId,
    required int questionId,
    required String status,
  }) {
    return Fr4SourceDocument(
      collection: 'questions',
      id: sourceId,
      data: <String, dynamic>{
        'id': questionId,
        'status': status,
      },
    );
  }

  test('FR5 selects only published production rows', () {
    final result = const Fr5CanonicalSourceSelector().select(
      <Fr4SourceDocument>[
        content(
          sourceId: 'published_d01_c01-v1',
          contentId: 'd01_c01-v1',
          version: 1,
          status: 'published',
          copyType: 'published',
        ),
        question(
          sourceId: 'question_101',
          questionId: 101,
          status: 'published',
        ),
      ],
    );

    expect(result.ready, isTrue);
    expect(result.documents, hasLength(2));
    expect(result.excluded, isEmpty);
    expect(result.issues, isEmpty);
    expect(result.selectedSourceCounts['contentVersions'], 1);
    expect(result.selectedSourceCounts['questions'], 1);
  });

  test('FR5 excludes authoring lifecycle rows from production migration', () {
    final result = const Fr5CanonicalSourceSelector().select(
      <Fr4SourceDocument>[
        content(
          sourceId: 'draft_d01_c01-v1',
          contentId: 'd01_c01-v1',
          version: 1,
          status: 'validated',
          copyType: 'draft',
        ),
        question(
          sourceId: 'question_102',
          questionId: 102,
          status: 'review',
        ),
      ],
    );

    expect(result.ready, isTrue);
    expect(result.documents, isEmpty);
    expect(result.excluded, hasLength(2));
    expect(result.excludedSourceCounts['contentVersions'], 1);
    expect(result.excludedSourceCounts['questions'], 1);
  });

  test('published content identity mismatch fails closed', () {
    final result = const Fr5CanonicalSourceSelector().select(
      <Fr4SourceDocument>[
        content(
          sourceId: 'draft_d01_c01-v1',
          contentId: 'd01_c01-v1',
          version: 1,
          status: 'published',
          copyType: 'draft',
        ),
      ],
    );

    expect(result.ready, isFalse);
    expect(result.documents, isEmpty);
    expect(result.issues, hasLength(1));
    expect(
      result.issues.single.kind,
      'inconsistent_published_content_identity',
    );
  });

  test('missing lifecycle status fails closed', () {
    const malformed = Fr4SourceDocument(
      collection: 'questions',
      id: 'question_103',
      data: <String, dynamic>{'id': 103},
    );

    final result = const Fr5CanonicalSourceSelector().select(
      <Fr4SourceDocument>[malformed],
    );

    expect(result.ready, isFalse);
    expect(result.issues.single.kind, 'missing_or_invalid_lifecycle');
  });
}
