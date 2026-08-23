import '../../models/study_content.dart';
import 'cloud_published_content_repository.dart';
import 'student_content_cache_repository.dart';

/// Synchronizes published CSP11 study content from Firebase into the
/// student-side local cache.
///
/// Firebase remains the authoritative source.
/// The local cache contains published content only.
///
/// Synchronization never downgrades an already cached competency version.
class StudentContentSyncService {
  StudentContentSyncService({
    required CloudPublishedContentRepository cloudRepository,
    required StudentContentCacheRepository cacheRepository,
  }) : _cloudRepository = cloudRepository,
       _cacheRepository = cacheRepository;

  final CloudPublishedContentRepository _cloudRepository;
  final StudentContentCacheRepository _cacheRepository;

  /// Synchronizes all currently published cloud content.
  ///
  /// Returns a result describing what happened during synchronization.
  Future<StudentContentSyncResult> synchronize() async {
    final publishedContents = await _cloudRepository.loadPublished();

    var downloaded = 0;
    var unchanged = 0;
    var skippedOlder = 0;

    for (final content in publishedContents) {
      final cached = await _cacheRepository.loadLatestForCompetency(
        content.competencyId,
      );

      if (cached == null) {
        await _cacheRepository.save(content);
        downloaded++;
        continue;
      }

      if (content.version > cached.version) {
        await _cacheRepository.save(content);
        downloaded++;
        continue;
      }

      if (content.version == cached.version) {
        unchanged++;
        continue;
      }

      skippedOlder++;
    }

    return StudentContentSyncResult(
      downloaded: downloaded,
      unchanged: unchanged,
      skippedOlder: skippedOlder,
    );
  }

  /// Synchronizes one competency only.
  ///
  /// This is useful when the student opens a specific competency and the
  /// application wants to refresh only that content.
  Future<StudentContentSyncResult> synchronizeCompetency(
    String competencyId,
  ) async {
    final publishedContents = await _cloudRepository.loadPublished();

    final matching = publishedContents
        .where((content) => content.competencyId == competencyId)
        .toList();

    if (matching.isEmpty) {
      return const StudentContentSyncResult();
    }

    final content = _latestVersion(matching);

    final cached = await _cacheRepository.loadLatestForCompetency(competencyId);

    if (cached == null) {
      await _cacheRepository.save(content);

      return const StudentContentSyncResult(downloaded: 1);
    }

    if (content.version > cached.version) {
      await _cacheRepository.save(content);

      return const StudentContentSyncResult(downloaded: 1);
    }

    if (content.version == cached.version) {
      return const StudentContentSyncResult(unchanged: 1);
    }

    return const StudentContentSyncResult(skippedOlder: 1);
  }

  StudyContent _latestVersion(List<StudyContent> contents) {
    return contents.reduce(
      (current, candidate) =>
          candidate.version > current.version ? candidate : current,
    );
  }
}

/// Result of a student content synchronization operation.
class StudentContentSyncResult {
  const StudentContentSyncResult({
    this.downloaded = 0,
    this.unchanged = 0,
    this.skippedOlder = 0,
  });

  final int downloaded;
  final int unchanged;
  final int skippedOlder;

  int get totalProcessed => downloaded + unchanged + skippedOlder;

  bool get changed => downloaded > 0;
}
