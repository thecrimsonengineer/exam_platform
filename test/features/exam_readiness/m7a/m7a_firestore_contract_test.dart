import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String rules;

  setUpAll(() {
    rules = File('firestore.rules').readAsStringSync();
  });

  group('M7A Firestore exam plan contract', () {
    test('examPlans are nested under owning user path', () {
      expect(rules, contains('match /examPlans/{planId}'));
      expect(rules, contains('match /users/{uid}'));
    });

    test('exam plan reads require self or admin', () {
      expect(
        rules,
        contains('allow get, list: if isSelf(uid) || isAdmin();'),
      );
    });

    test('learner create requires owned exam-plan validation', () {
      expect(
        rules,
        contains('isSelf(uid) && validOwnedExamPlan(uid, planId)'),
      );
    });

    test('learner update preserves immutable ownership fields', () {
      expect(
        rules,
        contains('request.resource.data.userId == resource.data.userId'),
      );
      expect(
        rules,
        contains('request.resource.data.id == resource.data.id'),
      );
      expect(
        rules,
        contains('request.resource.data.createdAt == resource.data.createdAt'),
      );
    });

    test('exam plan validator has a field allowlist', () {
      expect(rules, contains('examPlanAllowedKeys()'));
      expect(
        rules,
        contains('request.resource.data.keys().hasOnly(examPlanAllowedKeys())'),
      );
      expect(rules, contains("'schemaVersion'"));
      expect(rules, contains("'serverUpdatedAt'"));
    });

    test('global Firestore fallback remains fail closed', () {
      expect(
        rules,
        contains('allow read, write: if false;'),
      );
    });
  });
}
