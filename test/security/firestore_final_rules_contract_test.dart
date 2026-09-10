import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CSP11 final Firestore security contract', () {
    late String rules;

    setUpAll(() {
      rules = File('firestore.rules').readAsStringSync();
    });

    test('database is no longer public', () {
      expect(rules, isNot(contains('allow read, write: if true')));
      expect(rules, contains('allow read, write: if false'));
    });

    test('learner cannot self-promote or change identity fields', () {
      expect(rules, contains("request.resource.data.role == 'student'"));
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

    test('student question access is published-only', () {
      expect(rules, contains('match /questions/{questionId}'));
      expect(rules, contains("resource.data.status == 'published'"));
      expect(rules, contains('allow create, update, delete: if isAdmin();'));
    });

    test('student content access is published-only', () {
      expect(rules, contains('match /contentVersions/{contentVersionId}'));
      expect(rules, contains("resource.data.copyType == 'published'"));
      expect(rules, contains("resource.data.status == 'published'"));
    });

    test('firebase.json points to firestore.rules', () {
      final raw = File('firebase.json').readAsStringSync();
      final decoded = jsonDecode(raw);

      expect(decoded, isA<Map<String, dynamic>>());

      final root = decoded as Map<String, dynamic>;
      expect(root['firestore'], isA<Map<String, dynamic>>());

      final firestore = root['firestore'] as Map<String, dynamic>;
      expect(firestore['rules'], 'firestore.rules');
    });
  });
}
