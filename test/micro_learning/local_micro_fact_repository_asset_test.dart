import 'package:exam_platform/services/micro_learning/local_micro_fact_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled ML-10 production asset loads all 120 current facts', () async {
    final snapshot = await LocalMicroFactRepository().load(
      now: DateTime(2026, 9, 24),
    );

    expect(snapshot.bundleValid, isTrue);
    expect(snapshot.bundleId, LocalMicroFactRepository.requiredBundleId);
    expect(
      snapshot.bundleVersion,
      LocalMicroFactRepository.requiredBundleVersion,
    );
    expect(snapshot.bundleFactCount, 120);
    expect(snapshot.eligibleFacts, hasLength(120));
    expect(snapshot.staleFactCount, 0);
    expect(snapshot.diagnostics, isEmpty);
  });
}
