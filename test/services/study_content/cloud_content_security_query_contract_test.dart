import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String methodSlice({
    required String source,
    required String start,
    required String end,
  }) {
    final startIndex = source.indexOf(start);
    expect(startIndex, isNonNegative, reason: 'Missing method start: $start');

    final endIndex = source.indexOf(end, startIndex + start.length);
    expect(
      endIndex,
      greaterThan(startIndex),
      reason: 'Missing method end: $end',
    );

    return source.substring(startIndex, endIndex);
  }

  test(
    'published domain query matches learner Firestore read contract',
    () async {
      final source = await File(
        'lib/services/study_content/cloud_content_repository.dart',
      ).readAsString();

      final method = methodSlice(
        source: source,
        start:
            'Future<List<StudyContent>> loadPublishedDomain(String domainId)',
        end: 'Future<StudyContent?> loadPublishedCompetency(',
      );

      expect(method, contains(".where('domainId', isEqualTo: domainId)"));
      expect(method, contains(".where('copyType', isEqualTo: 'published')"));
      expect(method, contains(".where('status', isEqualTo: 'published')"));
    },
  );

  test(
    'published competency query matches learner Firestore read contract',
    () async {
      final source = await File(
        'lib/services/study_content/cloud_content_repository.dart',
      ).readAsString();

      final method = methodSlice(
        source: source,
        start: 'Future<StudyContent?> loadPublishedCompetency({',
        end: '/// Creates an independent published copy.',
      );

      expect(method, contains(".where('domainId', isEqualTo: domainId)"));
      expect(
        method,
        contains(".where('competencyId', isEqualTo: competencyId)"),
      );
      expect(method, contains(".where('copyType', isEqualTo: 'published')"));
      expect(method, contains(".where('status', isEqualTo: 'published')"));
    },
  );

  test('Firestore learner rule remains published-copy only', () async {
    final rules = await File('firestore.rules').readAsString();

    final start = rules.indexOf('match /contentVersions/{contentVersionId}');
    expect(start, isNonNegative);

    final end = rules.indexOf('// Fail closed for every Firestore path', start);
    expect(end, greaterThan(start));

    final contentRules = rules.substring(start, end);

    expect(contentRules, contains("resource.data.copyType == 'published'"));
    expect(contentRules, contains("resource.data.status == 'published'"));
  });
}
