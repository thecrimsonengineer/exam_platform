import 'package:flutter/material.dart';

import '../../models/student_progress_dashboard.dart';
import 'progress_analytics_screen.dart';

class DarkProgressScreen extends StatefulWidget {
  final Future<StudentProgressDashboard> Function()? loadDashboard;

  const DarkProgressScreen({super.key, this.loadDashboard});

  @override
  State<DarkProgressScreen> createState() => DarkProgressScreenState();
}

class DarkProgressScreenState extends State<DarkProgressScreen> {
  final GlobalKey<ProgressAnalyticsScreenState> _analyticsKey =
      GlobalKey<ProgressAnalyticsScreenState>();

  Future<void> refresh() async {
    await _analyticsKey.currentState?.refresh();
  }

  Future<void> onVisible() async {
    await _analyticsKey.currentState?.onVisible();
  }

  @override
  Widget build(BuildContext context) {
    return ProgressAnalyticsScreen(
      key: _analyticsKey,
      dashboardLoader: widget.loadDashboard,
      isDarkMode: true,
    );
  }
}
