import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../lib/services/study_content/content_import_service.dart';

void main() {
  const service = ContentImportService();

  String readContent(String path) {
    return File(path).readAsStringSync();
  }

  test('imports legacy V1 with canonical competency identity', () {
    final result = service.importJson(
      readContent(
        'content/domain_07/competencies/01_needs_assessment.json',
      ),
    );

    expect(result.isSuccessful, isTrue);
    expect(result.content, isNotNull);

    final content = result.content!;

    expect(content.id, 'domain_07_01');
    expect(content.domainId, 'd07');
    expect(content.competencyId, 'd07_c01');
    expect(content.competencyNumber, 1);
    expect(content.version, 1);
    expect(content.status, 'draft');
    expect(content.title, 'Needs Assessment');
  });

  test('imports legacy V2 with canonical competency identity', () {
    final result = service.importJson(
      readContent(
        'content/domain_07/competencies/01_needs_assessment_V2.json',
      ),
    );

    expect(result.isSuccessful, isTrue);
    expect(result.content, isNotNull);

    final content = result.content!;

    expect(content.id, 'domain_07_01-v2');
    expect(content.domainId, 'd07');
    expect(content.competencyId, 'd07_c01');
    expect(content.competencyNumber, 1);
    expect(content.version, 2);
    expect(content.status, 'draft');
    expect(content.title, 'Needs Assessment');
  });

  test('preserves package identity independently from canonical competency identity', () {
    final result = service.importJson(
      readContent(
        'content/domain_07/competencies/01_needs_assessment_V2.json',
      ),
    );

    expect(result.isSuccessful, isTrue);
    expect(result.content, isNotNull);

    final content = result.content!;

    expect(content.id, 'domain_07_01-v2');
    expect(content.competencyId, 'd07_c01');
    expect(content.id, isNot(content.competencyId));
  });

  test('accepts already canonical content identity', () {
    const source = '''
{
  "id": "canonical_test_package",
  "domainId": "d07",
  "competencyId": "d07_c01",
  "competencyNumber": 1,
  "title": "Needs Assessment",
  "status": "draft",
  "version": 1,
  "subtopics": []
}
''';

    final result = service.importJson(source);

    expect(result.isSuccessful, isTrue);
    expect(result.content, isNotNull);
    expect(result.content!.domainId, 'd07');
    expect(result.content!.competencyId, 'd07_c01');
    expect(result.content!.id, 'canonical_test_package');
  });

  test('converts canonical identity mapping failure into an import error', () {
    const source = '''
{
  "id": "invalid_package",
  "domainId": "domain_99",
  "competencyId": "domain_99_01",
  "competencyNumber": 1,
  "title": "Invalid",
  "status": "draft",
  "version": 1,
  "subtopics": []
}
''';

    final result = service.importJson(source);

    expect(result.content, isNull);
    expect(result.hasErrors, isTrue);
    expect(result.isSuccessful, isFalse);

    expect(
      result.issues.any(
        (issue) =>
            issue.severity == ContentImportIssueSeverity.error &&
            issue.message.contains(
              'Canonical content identity mapping failed:',
            ),
      ),
      isTrue,
    );
  });

  test('preserves deterministic mapping error semantics for competency mismatch', () {
    const source = '''
{
  "id": "mismatch_package",
  "domainId": "domain_07",
  "competencyId": "domain_07_02",
  "competencyNumber": 1,
  "title": "Mismatch",
  "status": "draft",
  "version": 1,
  "subtopics": []
}
''';

    final result = service.importJson(source);

    expect(result.content, isNull);
    expect(result.hasErrors, isTrue);
    expect(result.isSuccessful, isFalse);

    final mappingIssues = result.issues
        .where(
          (issue) =>
              issue.severity == ContentImportIssueSeverity.error &&
              issue.message.contains(
                'Canonical content identity mapping failed:',
              ),
        )
        .toList();

    expect(mappingIssues, hasLength(1));
  });
}
