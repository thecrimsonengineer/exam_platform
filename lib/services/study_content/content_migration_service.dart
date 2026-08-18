import '../../models/study_content.dart';
import 'cloud_content_repository.dart';
import 'local_study_content_repository.dart';

enum MigrationCopyType { draft, published }

class MigrationInventoryItem {
  const MigrationInventoryItem({
    required this.copyType,
    required this.content,
    required this.cloudExists,
    required this.cloudMatches,
  });

  final MigrationCopyType copyType;
  final StudyContent content;
  final bool cloudExists;
  final bool cloudMatches;

  String get targetDocumentId =>
      '${copyType == MigrationCopyType.draft ? 'draft' : 'published'}_${content.id}';
}

class MigrationReport {
  const MigrationReport({
    required this.items,
    this.migrated = 0,
    this.skipped = 0,
    this.conflicts = 0,
  });

  final List<MigrationInventoryItem> items;
  final int migrated;
  final int skipped;
  final int conflicts;
}

/// Phase E2 migration service.
///
/// Reads the existing local repository and writes only missing, matching
/// records to Firebase. Existing cloud records that differ from local are
/// reported as conflicts and are never overwritten by this service.
class ContentMigrationService {
  ContentMigrationService({
    LocalStudyContentRepository? local,
    CloudContentRepository? cloud,
  }) : _local = local ?? LocalStudyContentRepository(),
       _cloud = cloud ?? CloudContentRepository();

  final LocalStudyContentRepository _local;
  final CloudContentRepository _cloud;

  Future<MigrationReport> inspect() async {
    final localDrafts = await _local.loadDrafts();
    final localPublished = await _local.loadPublished();
    final cloudDrafts = await _cloud.loadDrafts();
    final cloudPublished = await _cloud.loadPublished();

    final items = <MigrationInventoryItem>[];

    for (final content in localDrafts) {
      final cloud = _findById(cloudDrafts, content.id);
      items.add(
        MigrationInventoryItem(
          copyType: MigrationCopyType.draft,
          content: content,
          cloudExists: cloud != null,
          cloudMatches: cloud != null && _sameContent(content, cloud),
        ),
      );
    }

    for (final content in localPublished) {
      final cloud = _findById(cloudPublished, content.id);
      items.add(
        MigrationInventoryItem(
          copyType: MigrationCopyType.published,
          content: content,
          cloudExists: cloud != null,
          cloudMatches: cloud != null && _sameContent(content, cloud),
        ),
      );
    }

    return MigrationReport(items: items);
  }

  Future<MigrationReport> migrateMissing() async {
    final report = await inspect();
    var migrated = 0;
    var skipped = 0;
    var conflicts = 0;

    for (final item in report.items) {
      if (item.cloudExists && item.cloudMatches) {
        skipped++;
        continue;
      }

      if (item.cloudExists && !item.cloudMatches) {
        conflicts++;
        continue;
      }

      if (item.copyType == MigrationCopyType.draft) {
        await _cloud.saveDraft(item.content);
      } else {
        await _cloud.publish(item.content);
      }
      migrated++;
    }

    return MigrationReport(
      items: report.items,
      migrated: migrated,
      skipped: skipped,
      conflicts: conflicts,
    );
  }

  Future<MigrationReport> verify() async {
    final report = await inspect();
    final conflicts = report.items
        .where((item) => item.cloudExists && !item.cloudMatches)
        .length;
    final skipped = report.items
        .where((item) => item.cloudExists && item.cloudMatches)
        .length;

    return MigrationReport(
      items: report.items,
      skipped: skipped,
      conflicts: conflicts,
    );
  }

  StudyContent? _findById(List<StudyContent> contents, String id) {
    for (final content in contents) {
      if (content.id == id) return content;
    }
    return null;
  }

  bool _sameContent(StudyContent local, StudyContent cloud) {
    return _normalize(local.toJson()) == _normalize(cloud.toJson());
  }

  dynamic _normalize(dynamic value) {
    if (value is Map) {
      final entries = value.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      return entries
          .map((entry) => [entry.key.toString(), _normalize(entry.value)])
          .toList();
    }

    if (value is List) {
      return value.map(_normalize).toList();
    }

    return value;
  }
}
