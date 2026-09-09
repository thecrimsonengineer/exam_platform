import 'package:exam_platform/data/csp11_blueprint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('canonical CSP11 learner domain identity', () {
    test('Domain 7 canonical ID is d07', () {
      expect(domainForNumber(7).id, 'd07');
    });

    test('canonical learner match accepts d07', () {
      final domain = domainForNumber(7);
      expect('d07' == domain.id, isTrue);
    });

    test('canonical learner match rejects legacy domain_07', () {
      final domain = domainForNumber(7);
      expect('domain_07' == domain.id, isFalse);
    });

    test('canonical learner match rejects another domain', () {
      final domain = domainForNumber(7);
      expect('d06' == domain.id, isFalse);
    });
  });
}
