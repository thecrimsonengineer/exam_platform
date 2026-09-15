import 'dart:io';

import 'package:exam_platform/screens/courses/csp/quiz/quiz_domain_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('quiz domain labels come from the canonical CSP11 blueprint', () {
    expect(
      csp11QuizDomainTitle(1),
      'Domain 01 • Advanced Application of Safety Principles',
    );
    expect(csp11QuizDomainTitle(2), 'Domain 02 • Program Management');
    expect(csp11QuizDomainTitle(3), 'Domain 03 • Risk Management');
    expect(csp11QuizDomainTitle(4), 'Domain 04 • Emergency Management');
    expect(csp11QuizDomainTitle(5), 'Domain 05 • Environmental Management');
    expect(
      csp11QuizDomainTitle(6),
      'Domain 06 • Occupational Health and Applied Science',
    );
    expect(csp11QuizDomainTitle(7), 'Domain 07 • Training');
  });

  test('quiz domain label has a safe fallback for unknown domains', () {
    expect(csp11QuizDomainTitle(99), 'Domain 99');
    expect(csp11QuizDomainTitle(0), 'CSP11 Practice Quiz');
  });

  test('QuizScreen no longer hard-codes Training Needs Assessment', () async {
    final source = await File(
      'lib/screens/courses/csp/quiz/quiz_screen.dart',
    ).readAsString();

    expect(source, isNot(contains("'Training Needs Assessment'")));
    expect(source, contains('csp11QuizDomainTitle(widget.domain)'));
  });
}
