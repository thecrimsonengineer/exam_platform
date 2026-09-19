import '../fr4_migration/fr4_migration_core.dart';

class Fr5SourceExclusion {
  const Fr5SourceExclusion({
    required this.collection,
    required this.sourceId,
    required this.status,
    required this.reason,
  });

  final String collection;
  final String sourceId;
  final String status;
  final String reason;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'collection': collection,
    'sourceId': sourceId,
    'status': status,
    'reason': reason,
  };
}

class Fr5SourceSelectionIssue {
  const Fr5SourceSelectionIssue({
    required this.kind,
    required this.collection,
    required this.sourceId,
    required this.message,
  });

  final String kind;
  final String collection;
  final String sourceId;
  final String message;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'kind': kind,
    'collection': collection,
    'sourceId': sourceId,
    'message': message,
  };
}

class Fr5CanonicalSourceSelection {
  const Fr5CanonicalSourceSelection({
    required this.documents,
    required this.excluded,
    required this.issues,
    required this.rawSourceCounts,
    required this.selectedSourceCounts,
    required this.excludedSourceCounts,
  });

  final List<Fr4SourceDocument> documents;
  final List<Fr5SourceExclusion> excluded;
  final List<Fr5SourceSelectionIssue> issues;
  final Map<String, int> rawSourceCounts;
  final Map<String, int> selectedSourceCounts;
  final Map<String, int> excludedSourceCounts;

  bool get ready => issues.isEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schemaVersion': 2,
    'phase': 'FR5',
    'ready': ready,
    'policy': 'published_only_production_source_authoring_excluded',
    'rawSourceCounts': rawSourceCounts,
    'selectedSourceCounts': selectedSourceCounts,
    'excludedSourceCounts': excludedSourceCounts,
    'selectedDocumentCount': documents.length,
    'excludedAuthoringCount': excluded.length,
    'issueCount': issues.length,
    'excluded': excluded.map((item) => item.toJson()).toList(growable: false),
    'issues': issues.map((item) => item.toJson()).toList(growable: false),
  };
}

class Fr5CanonicalSourceSelector {
  const Fr5CanonicalSourceSelector();

  static const Set<String> _knownNonPublishedStatuses = <String>{
    'draft',
    'review',
    'validated',
    'archived',
  };

  Fr5CanonicalSourceSelection select(Iterable<Fr4SourceDocument> source) {
    final raw = source.toList(growable: false)
      ..sort((left, right) {
        final byCollection = left.collection.compareTo(right.collection);
        if (byCollection != 0) return byCollection;
        return left.id.compareTo(right.id);
      });

    final rawCounts = <String, int>{};
    final selectedCounts = <String, int>{};
    final excludedCounts = <String, int>{};
    final selected = <Fr4SourceDocument>[];
    final excluded = <Fr5SourceExclusion>[];
    final issues = <Fr5SourceSelectionIssue>[];

    for (final document in raw) {
      rawCounts.update(
        document.collection,
        (count) => count + 1,
        ifAbsent: () => 1,
      );

      final lifecycle = _decodeLifecycle(document);
      if (lifecycle == null) {
        issues.add(
          Fr5SourceSelectionIssue(
            kind: 'missing_or_invalid_lifecycle',
            collection: document.collection,
            sourceId: document.id,
            message:
                'FR5 production selection requires a readable lifecycle '
                'status before the document can be classified.',
          ),
        );
        continue;
      }

      if (document.collection == 'contentVersions') {
        final publishedIdentity =
            lifecycle.status == 'published' &&
            lifecycle.copyType == 'published' &&
            lifecycle.idPrefix == 'published';

        if (publishedIdentity) {
          selected.add(document);
          _increment(selectedCounts, document.collection);
          continue;
        }

        if (lifecycle.status == 'published') {
          issues.add(
            Fr5SourceSelectionIssue(
              kind: 'inconsistent_published_content_identity',
              collection: document.collection,
              sourceId: document.id,
              message:
                  'Published content must have copyType=published and a '
                  'published_ document identity.',
            ),
          );
          continue;
        }

        if (_knownNonPublishedStatuses.contains(lifecycle.status)) {
          excluded.add(
            Fr5SourceExclusion(
              collection: document.collection,
              sourceId: document.id,
              status: lifecycle.status,
              reason: 'authoring_or_non_published_content',
            ),
          );
          _increment(excludedCounts, document.collection);
          continue;
        }

        issues.add(
          Fr5SourceSelectionIssue(
            kind: 'unknown_content_lifecycle',
            collection: document.collection,
            sourceId: document.id,
            message:
                'Unsupported content lifecycle status: '
                '${lifecycle.status}.',
          ),
        );
        continue;
      }

      if (document.collection == 'questions') {
        if (lifecycle.status == 'published') {
          selected.add(document);
          _increment(selectedCounts, document.collection);
          continue;
        }

        if (_knownNonPublishedStatuses.contains(lifecycle.status)) {
          excluded.add(
            Fr5SourceExclusion(
              collection: document.collection,
              sourceId: document.id,
              status: lifecycle.status,
              reason: 'authoring_or_non_published_question',
            ),
          );
          _increment(excludedCounts, document.collection);
          continue;
        }

        issues.add(
          Fr5SourceSelectionIssue(
            kind: 'unknown_question_lifecycle',
            collection: document.collection,
            sourceId: document.id,
            message:
                'Unsupported question lifecycle status: '
                '${lifecycle.status}.',
          ),
        );
        continue;
      }

      issues.add(
        Fr5SourceSelectionIssue(
          kind: 'unsupported_source_collection',
          collection: document.collection,
          sourceId: document.id,
          message: 'FR5 does not migrate this source collection.',
        ),
      );
    }

    selected.sort((left, right) {
      final byCollection = left.collection.compareTo(right.collection);
      if (byCollection != 0) return byCollection;
      return left.id.compareTo(right.id);
    });

    return Fr5CanonicalSourceSelection(
      documents: List<Fr4SourceDocument>.unmodifiable(selected),
      excluded: List<Fr5SourceExclusion>.unmodifiable(excluded),
      issues: List<Fr5SourceSelectionIssue>.unmodifiable(issues),
      rawSourceCounts: Map<String, int>.unmodifiable(rawCounts),
      selectedSourceCounts: Map<String, int>.unmodifiable(selectedCounts),
      excludedSourceCounts: Map<String, int>.unmodifiable(excludedCounts),
    );
  }

  _Lifecycle? _decodeLifecycle(Fr4SourceDocument document) {
    try {
      final decoded = decodeCsp11FirestoreSafe(document.data);
      if (decoded is! Map) return null;

      final source = <String, dynamic>{
        for (final entry in decoded.entries) entry.key.toString(): entry.value,
      };
      final status = source['status']?.toString().trim().toLowerCase() ?? '';
      if (status.isEmpty) return null;

      return _Lifecycle(
        status: status,
        copyType: source['copyType']?.toString().trim().toLowerCase() ?? '',
        idPrefix: _sourceIdPrefix(document.id),
      );
    } catch (_) {
      return null;
    }
  }

  void _increment(Map<String, int> counts, String key) {
    counts.update(key, (count) => count + 1, ifAbsent: () => 1);
  }
}

String _sourceIdPrefix(String sourceId) {
  if (sourceId.startsWith('published_')) return 'published';
  if (sourceId.startsWith('draft_')) return 'draft';
  return 'other';
}

class _Lifecycle {
  const _Lifecycle({
    required this.status,
    required this.copyType,
    required this.idPrefix,
  });

  final String status;
  final String copyType;
  final String idPrefix;
}
