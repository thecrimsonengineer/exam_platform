import 'package:flutter/foundation.dart';

enum FirestoreReadAuditKind { query, document }

@immutable
class FirestoreReadAuditEvent {
  const FirestoreReadAuditEvent({
    required this.kind,
    required this.operation,
    required this.collection,
    required this.scope,
    required this.returnedDocuments,
  });

  final FirestoreReadAuditKind kind;
  final String operation;
  final String collection;
  final String scope;
  final int returnedDocuments;
}

class FirestoreReadAudit {
  FirestoreReadAudit._();

  static bool enabled = !kReleaseMode;

  static final List<FirestoreReadAuditEvent> _events =
      <FirestoreReadAuditEvent>[];

  static List<FirestoreReadAuditEvent> get events =>
      List<FirestoreReadAuditEvent>.unmodifiable(_events);

  static int get totalReturnedDocuments => _events.fold<int>(
    0,
    (total, event) => total + event.returnedDocuments,
  );

  static int countOperation(String operation) =>
      _events.where((event) => event.operation == operation).length;

  static int returnedDocumentsFor(String operation) => _events
      .where((event) => event.operation == operation)
      .fold<int>(0, (total, event) => total + event.returnedDocuments);

  static void recordQuery({
    required String operation,
    required String collection,
    required String scope,
    required int returnedDocuments,
  }) {
    if (!enabled) {
      return;
    }

    _events.add(
      FirestoreReadAuditEvent(
        kind: FirestoreReadAuditKind.query,
        operation: operation,
        collection: collection,
        scope: scope,
        returnedDocuments: returnedDocuments,
      ),
    );
  }

  static void recordDocument({
    required String operation,
    required String collection,
    required String documentId,
    required bool exists,
  }) {
    if (!enabled) {
      return;
    }

    _events.add(
      FirestoreReadAuditEvent(
        kind: FirestoreReadAuditKind.document,
        operation: operation,
        collection: collection,
        scope: 'document:$documentId',
        returnedDocuments: exists ? 1 : 0,
      ),
    );
  }

  @visibleForTesting
  static void reset() {
    _events.clear();
  }
}
