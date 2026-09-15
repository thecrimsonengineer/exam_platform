import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('main progress page is analytics-first and domain drill-down based', () {
    final source = read('lib/screens/progress/progress_analytics_screen.dart');

    expect(source, contains('WeeklyActivityLineChart'));
    expect(source, contains('WeeklyActivityHeatmap'));
    expect(source, contains('DomainProgressBars'));
    expect(source, contains('AccuracyDonut'));
    expect(source, contains('CompletionBars'));
    expect(source, contains('DataTable('));
    expect(source, contains('ProgressDomainDetailScreen'));
  });

  test(
    'overview uses persisted snapshot rather than blocking on full hierarchy',
    () {
      final source = read(
        'lib/screens/progress/progress_analytics_screen.dart',
      );

      expect(source, contains('_service.peek()'));
      expect(source, contains('_service.loadCached()'));
      expect(source, contains('_service.bootstrapLocal()'));
      expect(
        source,
        isNot(contains('FutureBuilder<StudentProgressDashboard>')),
      );
    },
  );

  test(
    'dark and light progress routes share the V2 analytics implementation',
    () {
      final light = read('lib/screens/progress/progress_screen.dart');
      final dark = read('lib/screens/progress/progress_screen_dark.dart');

      expect(light, contains('ProgressAnalyticsScreen'));
      expect(dark, contains('ProgressAnalyticsScreen'));
      expect(light, contains('onVisible()'));
      expect(dark, contains('onVisible()'));
    },
  );

  test('domain details are lazy and scoped to one domain', () {
    final service = read('lib/services/progress_domain_detail_service.dart');

    expect(service, contains('loadPublishedDomainContent(domainId)'));
    expect(service, contains('content.domainId == domainId'));
  });
}
