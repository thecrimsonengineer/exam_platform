import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Progress V2 paints cached analytics before authoritative refresh',
    () async {
      final wrapper = await File(
        'lib/screens/progress/progress_screen.dart',
      ).readAsString();

      final analytics = await File(
        'lib/screens/progress/progress_analytics_screen.dart',
      ).readAsString();

      expect(wrapper, contains('ProgressAnalyticsScreen'));
      expect(wrapper, contains('onVisible()'));

      expect(analytics, contains('_service.peek()'));
      expect(analytics, contains('_service.loadCached()'));
      expect(analytics, contains('_service.bootstrapLocal()'));
      expect(analytics, contains('_refreshAuthoritative('));
      expect(
        analytics,
        isNot(contains('FutureBuilder<StudentProgressDashboard>')),
      );
      expect(analytics, contains('ProgressDomainDetailScreen'));
    },
  );

  test(
    'dashboard service parallelizes reads and indexes question roll-ups',
    () async {
      final source = await File(
        'lib/services/student_progress_dashboard_service.dart',
      ).readAsString();

      expect(source, contains('Future.wait<dynamic>(['));
      expect(source, contains('answeredBySubtopic'));
      expect(source, contains('answeredByTopic'));
      expect(source, contains('answeredByCompetency'));
      expect(source, contains('answeredByDomain'));
      expect(
        source,
        isNot(
          contains('final subtopicQuestions = questionProgress.values.where'),
        ),
      );
    },
  );

  test('V2 overview exposes charts tables and Domain drill-down', () async {
    final source = await File(
      'lib/screens/progress/progress_analytics_screen.dart',
    ).readAsString();

    expect(source, contains('WeeklyActivityLineChart'));
    expect(source, contains('WeeklyActivityHeatmap'));
    expect(source, contains('DomainProgressBars'));
    expect(source, contains('AccuracyDonut'));
    expect(source, contains('CompletionBars'));
    expect(source, contains('DataTable('));
    expect(source, contains('ProgressDomainDetailScreen'));
  });
}
