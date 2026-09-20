import 'dart:convert';
import 'dart:io';

import 'package:exam_platform/features/flashcards/flashcards.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reference package earns FCQ100 and passes every rule', () {
    final contentPackage = _referencePackage();
    final result = const Fcq100Validator().validate(contentPackage);

    expect(result.maxScore, 100);
    expect(result.score, 100);
    expect(result.rules, hasLength(25));
    expect(result.failedRules, isEmpty);
    expect(result.passed, isTrue);
  });

  test('missing Why It Matters blocks learner-ready FCQ100', () {
    final json = _referenceJson();
    final cards = json['cards'] as List<dynamic>;
    final first = Map<String, dynamic>.from(cards.first as Map);
    first['whyItMatters'] = '';
    cards[0] = first;

    final contentPackage = FlashcardContentPackage.fromJson(json);
    final result = const Fcq100Validator().validate(contentPackage);

    expect(result.passed, isFalse);
    expect(result.failedRules.map((rule) => rule.id), contains('FCQ-018'));
  });

  test('semantic duplicate Concept labels fail closed', () {
    final json = _referenceJson();
    final concepts = json['concepts'] as List<dynamic>;
    final second = Map<String, dynamic>.from(concepts[1] as Map);
    second['canonicalLabel'] = 'Hierarchy of Controls';
    concepts[1] = second;

    final contentPackage = FlashcardContentPackage.fromJson(json);
    final result = const Fcq100Validator().validate(contentPackage);

    expect(result.passed, isFalse);
    expect(result.failedRules.map((rule) => rule.id), contains('FCQ-023'));
  });
}

FlashcardContentPackage _referencePackage() {
  return FlashcardContentPackage.fromJson(_referenceJson());
}

Map<String, dynamic> _referenceJson() {
  return Map<String, dynamic>.from(
    jsonDecode(
      File(
        'assets/flashcards/run3/fc_reference_package.v1.json',
      ).readAsStringSync(),
    ) as Map,
  );
}
