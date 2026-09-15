import 'package:exam_platform/models/student_progress_dashboard.dart';
import 'package:exam_platform/services/student_progress_dashboard_session_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(StudentProgressDashboardSessionCache.clearAll);

  const dashboard = StudentProgressDashboard(domains: [], latestActivity: null);

  test('session dashboard cache is isolated by learner UID', () {
    StudentProgressDashboardSessionCache.put('user-a', dashboard);

    expect(
      StudentProgressDashboardSessionCache.peek('user-a'),
      same(dashboard),
    );
    expect(StudentProgressDashboardSessionCache.peek('user-b'), isNull);
  });

  test(
    'session dashboard cache can be invalidated without touching another UID',
    () {
      StudentProgressDashboardSessionCache.put('user-a', dashboard);
      StudentProgressDashboardSessionCache.put('user-b', dashboard);

      StudentProgressDashboardSessionCache.invalidate('user-a');

      expect(StudentProgressDashboardSessionCache.peek('user-a'), isNull);
      expect(
        StudentProgressDashboardSessionCache.peek('user-b'),
        same(dashboard),
      );
    },
  );
}
