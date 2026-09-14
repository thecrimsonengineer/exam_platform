import '../../models/student_learning_progress.dart';
import '../../models/study_content.dart';
import '../student_learning_progress_session_cache.dart';
import 'student_study_content_session_cache.dart';

/// Chooses and warms exactly one likely next StudyContent item from content
/// already returned by the authoritative P4B domain query.
///
/// P5 deliberately performs no cloud read. It only promotes one already
/// published, already downloaded domain item into the existing 5-entry
/// process-memory LRU so the learner's first tap can use the P4A zero-frame
/// path.
class StudentStudyContentPrefetchService {
  const StudentStudyContentPrefetchService();

  StudyContent? warmOne({
    required String domainId,
    required List<StudyContent> contents,
    Map<String, StudentSubtopicProgress>? progress,
  }) {
    final effectiveProgress =
        progress ?? StudentLearningProgressSessionCache.peek();

    final candidate = selectCandidate(
      domainId: domainId,
      contents: contents,
      progress: effectiveProgress,
      isCached: (content) => StudentStudyContentSessionCache.contains(
        domainId: content.domainId,
        competencyId: content.competencyId,
      ),
    );

    if (candidate == null) {
      return null;
    }

    StudentStudyContentSessionCache.put(candidate);
    return candidate;
  }

  StudyContent? selectCandidate({
    required String domainId,
    required List<StudyContent> contents,
    Map<String, StudentSubtopicProgress>? progress,
    bool Function(StudyContent content)? isCached,
  }) {
    final candidates = <_PrefetchCandidate>[];

    for (final content in contents) {
      if (content.domainId != domainId ||
          content.status.toLowerCase() != 'published') {
        continue;
      }

      if (isCached?.call(content) ?? false) {
        continue;
      }

      final subtopicIds = _subtopicIds(content);

      // There is nothing useful to warm if this competency has no learner
      // content yet.
      if (subtopicIds.isEmpty) {
        continue;
      }

      final activity = (progress?.values ?? const <StudentSubtopicProgress>[])
          .where(
            (item) =>
                item.domainId == domainId &&
                item.competencyId == content.competencyId,
          )
          .toList(growable: false);

      final currentVersionProgress = activity
          .where(
            (item) =>
                item.studyContentId == content.id &&
                item.studyContentVersion == content.version,
          )
          .toList(growable: false);

      final completedCurrentSubtopics = currentVersionProgress
          .where((item) => item.state == StudentLearningState.completed)
          .map((item) => item.subtopicId)
          .where(subtopicIds.contains)
          .toSet();

      final fullyCompleted =
          completedCurrentSubtopics.length == subtopicIds.length;

      if (fullyCompleted) {
        continue;
      }

      final hasInProgress = activity.any(
        (item) => item.state == StudentLearningState.inProgress,
      );

      final priority = hasInProgress
          ? 0
          : activity.isNotEmpty
          ? 1
          : 2;

      DateTime? lastOpenedAt;

      for (final item in activity) {
        if (lastOpenedAt == null || item.lastOpenedAt.isAfter(lastOpenedAt)) {
          lastOpenedAt = item.lastOpenedAt;
        }
      }

      candidates.add(
        _PrefetchCandidate(
          content: content,
          priority: priority,
          lastOpenedAt: lastOpenedAt,
        ),
      );
    }

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort((a, b) {
      final priorityCompare = a.priority.compareTo(b.priority);

      if (priorityCompare != 0) {
        return priorityCompare;
      }

      final aTime = a.lastOpenedAt;
      final bTime = b.lastOpenedAt;

      if (aTime != null && bTime != null) {
        final timeCompare = bTime.compareTo(aTime);

        if (timeCompare != 0) {
          return timeCompare;
        }
      } else if (aTime != null) {
        return -1;
      } else if (bTime != null) {
        return 1;
      }

      final numberCompare = a.content.competencyNumber.compareTo(
        b.content.competencyNumber,
      );

      if (numberCompare != 0) {
        return numberCompare;
      }

      return a.content.competencyId.compareTo(b.content.competencyId);
    });

    return candidates.first.content;
  }

  Set<String> _subtopicIds(StudyContent content) {
    return <String>{
      for (final topic in content.topics)
        for (final subtopic in topic.subtopics)
          if (subtopic.id.trim().isNotEmpty) subtopic.id.trim(),
    };
  }
}

class _PrefetchCandidate {
  final StudyContent content;
  final int priority;
  final DateTime? lastOpenedAt;

  const _PrefetchCandidate({
    required this.content,
    required this.priority,
    required this.lastOpenedAt,
  });
}
