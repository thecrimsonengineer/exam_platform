import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ML LTAM bridge remains presentation-only', () async {
    final source = await File(
      'lib/features/learning_twin/integration/'
      'micro_learning_twin_presentation.dart',
    ).readAsString();

    expect(source, contains("models/micro_learning/micro_fact.dart"));
    expect(source, contains("../ui/learning_twin_asset.dart"));

    expect(source, isNot(contains('/domain/')));
    expect(source, isNot(contains('LearningTwinDecision')));
    expect(source, isNot(contains('LearningTwinSessionState')));
    expect(source, isNot(contains('firebase')));
    expect(source, isNot(contains('supabase')));
    expect(source, isNot(contains('http')));
    expect(source, isNot(contains('lottie')));
  });
}
