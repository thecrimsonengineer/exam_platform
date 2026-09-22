import 'package:exam_platform/models/student_learning_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HOME-R7 progress serialization preserves first and latest completion', () {
    final first = DateTime(2026, 8, 1, 10);
    final latest = DateTime(2026, 9, 22, 10);

    final progress = StudentSubtopicProgress(
      domainId: 'd04',
      domainNumber: 4,
      domainTitle: 'Emergency Management',
      competencyId: 'd04_c01',
      competencyTitle: 'Emergency response planning',
      subtopicId: 'd04_c01_t01_s01',
      subtopicTitle: 'Review',
      studyContentId: 'content',
      studyContentVersion: 1,
      state: StudentLearningState.completed,
      lastOpenedAt: latest,
      completedAt: first,
      lastCompletedAt: latest,
    );

    final restored = StudentSubtopicProgress.fromJson(progress.toJson());

    expect(restored.completedAt, first);
    expect(restored.lastCompletedAt, latest);
  });

  test('HOME-R7 legacy progress falls back to first completion timestamp', () {
    final first = DateTime(2026, 8, 1, 10);

    final restored = StudentSubtopicProgress.fromJson(<String, dynamic>{
      'domainId': 'd04',
      'domainNumber': 4,
      'domainTitle': 'Emergency Management',
      'competencyId': 'd04_c01',
      'competencyTitle': 'Emergency response planning',
      'subtopicId': 'd04_c01_t01_s01',
      'subtopicTitle': 'Review',
      'studyContentId': 'content',
      'studyContentVersion': 1,
      'state': 'completed',
      'lastOpenedAt': first.toIso8601String(),
      'completedAt': first.toIso8601String(),
    });

    expect(restored.completedAt, first);
    expect(restored.lastCompletedAt, first);
  });
}
