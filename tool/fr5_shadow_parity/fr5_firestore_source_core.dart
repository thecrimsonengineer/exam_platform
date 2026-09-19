import '../fr4_migration/fr4_migration_core.dart';

class Fr5SupersededSource {
  const Fr5SupersededSource({
    required this.targetKey,
    required this.selectedSourceId,
    required this.supersededSourceId,
    required this.reason,
  });

  final String targetKey;
  final String selectedSourceId;
  final String supersededSourceId;
  final String reason;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'targetKey': targetKey,
    'selectedSourceId': selectedSourceId,
    'supersededSourceId': supersededSourceId,
    'reason': reason,
  };
}

class Fr5SourceSelectionIssue {
  const Fr5SourceSelectionIssue({
    required this.kind,
    required this.targetKey,
    required this.sourceIds,
    required this.candidates,
    required this.message,
  });

  final String kind;
  final String targetKey;
  final List<String> sourceIds;
  final List<Map<String, dynamic>> candidates;
  final String message;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'kind': kind,
    'targetKey': targetKey,
    'sourceIds': sourceIds,
    'candidates': candidates,
    'message': message,
  };
}

class Fr5CanonicalSourceSelection {
  const Fr5CanonicalSourceSelection({
    required this.documents,
    required this.superseded,
    required this.issues,
    required this.rawSourceCounts,
    required this.selectedSourceCounts,
  });

  final List<Fr4SourceDocument> documents;
  final List<Fr5SupersededSource> superseded;
  final List<Fr5SourceSelectionIssue> issues;
  final Map<String, int> rawSourceCounts;
  final Map<String, int> selectedSourceCounts;

  bool get ready => issues.isEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schemaVersion': 1,
    'phase': 'FR5',
    'ready': ready,
    'policy': 'prefer_published_over_draft_for_same_content_id_and_version',
    'rawSourceCounts': rawSourceCounts,
    'selectedSourceCounts': selectedSourceCounts,
    'selectedDocumentCount': documents.length,
    'supersededDraftCount': superseded.length,
    'issueCount': issues.length,
    'superseded': superseded.map((item) => item.toJson()).toList(growable: false),
    'issues': issues.map((item) => item.toJson()).toList(growable: false),
  };
}

class Fr5CanonicalSourceSelector {
  const Fr5CanonicalSourceSelector();

  Fr5CanonicalSourceSelection select(Iterable<Fr4SourceDocument> source) {
    final raw = source.toList(growable: false)
      ..sort((left, right) {
        final byCollection = left.collection.compareTo(right.collection);
        if (byCollection != 0) return byCollection;
        return left.id.compareTo(right.id);
      });

    final rawCounts = <String, int>{};
    for (final document in raw) {
      rawCounts.update(
        document.collection,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    final selected = <Fr4SourceDocument>[];
    final superseded = <Fr5SupersededSource>[];
    final issues = <Fr5SourceSelectionIssue>[];
    final contentGroups = <String, List<_ContentCandidate>>{};

    for (final document in raw) {
      if (document.collection != 'contentVersions') {
        selected.add(document);
        continue;
      }

      final candidate = _contentCandidate(document);
      if (candidate == null) {
        selected.add(document);
        continue;
      }

      contentGroups
          .putIfAbsent(candidate.targetKey, () => <_ContentCandidate>[])
          .add(candidate);
    }

    final orderedKeys = contentGroups.keys.toList(growable: false)..sort();
    for (final key in orderedKeys) {
      final group = contentGroups[key]!
        ..sort(
          (left, right) => left.document.id.compareTo(right.document.id),
        );

      if (group.length == 1) {
        selected.add(group.single.document);
        continue;
      }

      final published = group
          .where((candidate) => candidate.status == 'published')
          .toList(growable: false);
      final drafts = group
          .where((candidate) => candidate.status == 'draft')
          .toList(growable: false);

      if (group.length == 2 && published.length == 1 && drafts.length == 1) {
        selected.add(published.single.document);
        superseded.add(
          Fr5SupersededSource(
            targetKey: key,
            selectedSourceId: published.single.document.id,
            supersededSourceId: drafts.single.document.id,
            reason:
                'Published lifecycle snapshot supersedes the draft snapshot '
                'for the same canonical content ID and version.',
          ),
        );
        continue;
      }

      issues.add(
        Fr5SourceSelectionIssue(
          kind: 'ambiguous_content_version_duplicate',
          targetKey: key,
          sourceIds: group
              .map((candidate) => candidate.document.id)
              .toList(growable: false),
          candidates: group
              .map(
                (candidate) => <String, dynamic>{
                  'sourceId': candidate.document.id,
                  'status': candidate.status,
                  'idPrefix': _sourceIdPrefix(candidate.document.id),
                },
              )
              .toList(growable: false),
          message:
              'Only an exact draft+published pair may be resolved '
              'automatically. All other duplicate lifecycle sets fail closed.',
        ),
      );
    }

    selected.sort((left, right) {
      final byCollection = left.collection.compareTo(right.collection);
      if (byCollection != 0) return byCollection;
      return left.id.compareTo(right.id);
    });

    final selectedCounts = <String, int>{};
    for (final document in selected) {
      selectedCounts.update(
        document.collection,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    return Fr5CanonicalSourceSelection(
      documents: List<Fr4SourceDocument>.unmodifiable(selected),
      superseded: List<Fr5SupersededSource>.unmodifiable(superseded),
      issues: List<Fr5SourceSelectionIssue>.unmodifiable(issues),
      rawSourceCounts: Map<String, int>.unmodifiable(rawCounts),
      selectedSourceCounts: Map<String, int>.unmodifiable(selectedCounts),
    );
  }

  _ContentCandidate? _contentCandidate(Fr4SourceDocument document) {
    try {
      final decoded = decodeCsp11FirestoreSafe(document.data);
      if (decoded is! Map) return null;
      final source = <String, dynamic>{
        for (final entry in decoded.entries)
          entry.key.toString(): entry.value,
      };

      final contentId = source['id']?.toString().trim() ?? '';
      final versionValue = source['version'];
      final version = versionValue is int
          ? versionValue
          : int.tryParse(versionValue?.toString() ?? '');
      final status = source['status']?.toString().trim().toLowerCase() ?? '';

      if (contentId.isEmpty || version == null || version <= 0 || status.isEmpty) {
        return null;
      }

      return _ContentCandidate(
        document: document,
        targetKey: '$contentId|v$version',
        status: status,
      );
    } catch (_) {
      return null;
    }
  }
}

String _sourceIdPrefix(String sourceId) {
  if (sourceId.startsWith('published_')) return 'published';
  if (sourceId.startsWith('draft_')) return 'draft';
  if (sourceId.startsWith('validated_')) return 'validated';
  if (sourceId.startsWith('review_')) return 'review';
  return 'other';
}

class _ContentCandidate {
  const _ContentCandidate({
    required this.document,
    required this.targetKey,
    required this.status,
  });

  final Fr4SourceDocument document;
  final String targetKey;
  final String status;
}
