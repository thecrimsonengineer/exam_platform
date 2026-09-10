import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CSP11 Firestore users rules contract', () {
    late String rules;

    setUpAll(() {
      rules = File(
        'security/firestore_users.rules.fragment',
      ).readAsStringSync();
    });

    test('requires self-owned student profile creation', () {
      expect(rules, contains('request.auth.uid == uid'));
      expect(rules, contains("request.resource.data.role == 'student'"));
      expect(rules, contains('request.resource.data.uid == uid'));
    });

    test('prevents learner privilege and identity mutation', () {
      expect(
        rules,
        contains('request.resource.data.role == resource.data.role'),
      );
      expect(rules, contains('request.resource.data.uid == resource.data.uid'));
      expect(
        rules,
        contains('request.resource.data.email == resource.data.email'),
      );
      expect(
        rules,
        contains('request.resource.data.createdAt == resource.data.createdAt'),
      );
    });

    test('allowlists learner-editable fields', () {
      expect(rules, contains('.affectedKeys()'));
      expect(rules, contains('.hasOnly(csp11LearnerMutableKeys())'));
      expect(rules, contains("'fullName'"));
      expect(rules, contains("'country'"));
      expect(rules, contains("'updatedAt'"));
    });

    test(
      'blocks learner list and delete while preserving admin management',
      () {
        expect(rules, contains('allow list: if csp11IsAdmin();'));
        expect(rules, contains('allow delete: if csp11IsAdmin();'));
        expect(
          rules,
          contains('allow get: if csp11IsSelf(uid) || csp11IsAdmin();'),
        );
      },
    );

    test('does not contain a broad recursive allow', () {
      expect(rules, isNot(contains('{document=**}')));
      expect(rules, isNot(contains('allow read, write:')));
    });
  });
}
