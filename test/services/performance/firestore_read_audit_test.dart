import 'package:exam_platform/services/performance/firestore_read_audit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    FirestoreReadAudit.enabled = true;
    FirestoreReadAudit.reset();
  });

  tearDown(() {
    FirestoreReadAudit.reset();
  });

  test('FR1 records query scope and returned document count', () {
    FirestoreReadAudit.recordQuery(
      operation: 'questions.loadPublished',
      collection: 'questions',
      scope: 'status=published',
      returnedDocuments: 12,
    );

    expect(FirestoreReadAudit.events, hasLength(1));
    expect(FirestoreReadAudit.totalReturnedDocuments, 12);
    expect(FirestoreReadAudit.countOperation('questions.loadPublished'), 1);
    expect(
      FirestoreReadAudit.returnedDocumentsFor('questions.loadPublished'),
      12,
    );
    expect(
      FirestoreReadAudit.events.single.kind,
      FirestoreReadAuditKind.query,
    );
  });

  test('FR1 records an existing single-document read as one document', () {
    FirestoreReadAudit.recordDocument(
      operation: 'questions.load',
      collection: 'questions',
      documentId: 'question_42',
      exists: true,
    );

    expect(FirestoreReadAudit.totalReturnedDocuments, 1);
    expect(FirestoreReadAudit.events.single.scope, 'document:question_42');
  });

  test('FR1 records a missing single-document read as zero returned documents', () {
    FirestoreReadAudit.recordDocument(
      operation: 'questions.load',
      collection: 'questions',
      documentId: 'question_404',
      exists: false,
    );

    expect(FirestoreReadAudit.totalReturnedDocuments, 0);
  });

  test('FR1 can be disabled without affecting repository behavior', () {
    FirestoreReadAudit.enabled = false;

    FirestoreReadAudit.recordQuery(
      operation: 'content.loadPublished',
      collection: 'contentVersions',
      scope: 'copyType=published,status=published',
      returnedDocuments: 30,
    );

    expect(FirestoreReadAudit.events, isEmpty);
  });
}
