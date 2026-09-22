import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HOME-R5 Home cards pass their category to Today Plan', () {
    for (final path in <String>[
      'lib/screens/home/home_screen.dart',
      'lib/screens/home/home_screen_dark.dart',
    ]) {
      final source = File(path).readAsStringSync();

      expect(source, contains('TodayPlanTaskCategory? category'));
      expect(
        source,
        contains('TodaysPlanScreen(initialCategory: category)'),
      );
      expect(
        source,
        contains('_openTodaysPlan(category: category)'),
      );
      expect(
        source,
        contains('onViewFullPlan: () => _openTodaysPlan()'),
      );
    }
  });

  test('HOME-R5 Today Plan filtering stays in presentation state', () {
    final source = File(
      'lib/features/exam_readiness/screens/todays_plan_screen.dart',
    ).readAsStringSync();

    for (final required in <String>[
      'final TodayPlanTaskCategory? initialCategory;',
      'final TodayPlanPresentationFilter presentationFilter;',
      '_activeCategory = widget.initialCategory;',
      'visibleBlocks = widget.presentationFilter.apply(',
      'blocks: plan.blocks,',
      'category: _activeCategory,',
      '_WhyThisPlan(blocks: visibleBlocks)',
      'setState(() => _activeCategory = null)',
    ]) {
      expect(source, contains(required));
    }

    expect(
      source,
      isNot(contains('copyWith(blocks: visibleBlocks')),
      reason: 'Filtering must never create a forked DailyStudyPlan.',
    );
  });
}
