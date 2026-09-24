import 'package:exam_platform/services/micro_learning/local_micro_fact_repository.dart';
import 'package:exam_platform/services/micro_learning/micro_fact_selector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ML-11 rotates across the complete frozen ML-10 corpus', () async {
    final snapshot = await LocalMicroFactRepository().load(
      now: DateTime(2026, 9, 24),
    );

    expect(snapshot.bundleValid, isTrue);
    expect(snapshot.eligibleFacts, hasLength(120));

    const selector = MicroFactSelector();
    final ids = <String>{};
    final categories = <String>{};

    for (var ordinal = 0; ordinal < snapshot.eligibleFacts.length; ordinal++) {
      final result = selector.select(
        snapshot.eligibleFacts,
        context: MicroFactSelectionContext(rotationOrdinal: ordinal),
      );

      expect(result.fact, isNotNull);
      ids.add(result.fact!.microFactId);
      categories.add(result.fact!.category);
    }

    expect(ids, hasLength(120));
    expect(categories, hasLength(10));
  });
}
