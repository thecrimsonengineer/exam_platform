import 'package:flutter/material.dart';

import 'progress_analytics_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => ProgressScreenState();
}

class ProgressScreenState extends State<ProgressScreen> {
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
    return ProgressAnalyticsScreen(key: _analyticsKey, isDarkMode: false);
  }
}
