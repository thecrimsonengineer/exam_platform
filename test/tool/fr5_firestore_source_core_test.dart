import 'package:flutter_test/flutter_test.dart';

import '../../tool/fr4_migration/fr4_migration_core.dart';
import '../../tool/fr5_shadow_parity/fr5_firestore_source_core.dart';

void main() {
  Fr4SourceDocument content({
    required String sourceId,
    required String contentId,
    required int version,
    required String status,
  }) {
    return Fr4SourceDocument(
      collection: 'contentVersions',
      id: sourceId,
      data: <String, dynamic>{
        'id': contentId,
        'version': version,
        'status': status,
      },
    );
  }

  test('published snapshot deterministically supersedes matching draft', () {
    final result = const Fr5CanonicalSourceSelector().select(
      <Fr4SourceDocument>[
        content(
          sourceId: 'published_d01_c01-v1',
          contentId: 'd01_c01-v1',
          version: 1,
          status: 'published',
        ),
        content(
          sourceId: 'draft_d01_c01-v1',
          contentId: 'd01_c01-v1',
          version: 1,
          status: 'draft',
        ),
        const Fr4SourceDocument(
          collection: 'questions',
          id: '101',
          data: <String, dynamic>{'id': 101},
        ),
      ],
    );

    expect(result.ready, isTrue);
    expect(result.issues, isEmpty);
    expect(result.superseded, hasLength(1));
    expect(result.documents, hasLength(2));
    expect(
      result.documents
          .where((document) => document.collection == 'contentVersions')
          .single
          .id,
      'published_d01_c01-v1',
    );
    expect(result.rawSourceCounts['contentVersions'], 2);
    expect(result.selectedSourceCounts['contentVersions'], 1);
  });

  test('duplicate lifecycle set other than exact draft+published fails closed', () {
    final result = const Fr5CanonicalSourceSelector().select(
      <Fr4SourceDocument>[
        content(
          sourceId: 'draft_a',
          contentId: 'd01_c01-v1',
          version: 1,
          status: 'draft',
        ),
        content(
          sourceId: 'review_a',
          contentId: 'd01_c01-v1',
          version: 1,
          status: 'review',
        ),
      ],
    );

    expect(result.ready, isFalse);
    expect(result.issues, hasLength(1));
    expect(result.issues.single.kind, 'ambiguous_content_version_duplicate');
    expect(result.documents, isEmpty);
  });

  test('malformed content remains selected for frozen FR4 to reject', () {
    const malformed = Fr4SourceDocument(
      collection: 'contentVersions',
      id: 'malformed',
      data: <String, dynamic>{'status': 'draft'},
    );

    final result = const Fr5CanonicalSourceSelector().select(
      <Fr4SourceDocument>[malformed],
    );

    expect(result.ready, isTrue);
    expect(result.documents, <Fr4SourceDocument>[malformed]);
    expect(result.superseded, isEmpty);
  });
}
