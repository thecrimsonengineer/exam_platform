import 'package:exam_platform/data/csp11_blueprint.dart';
import 'package:exam_platform/services/study_content_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FR10E domains come entirely from the canonical blueprint', () async {
    const loader = StudyContentLoader();

    final domains = await loader.loadDomains();

    expect(domains.length, csp11Domains.length);
    expect(domains.first['id'], 'd01');
    expect(domains.first['title'], csp11Domains.first.title);
    expect(domains.last['id'], 'd07');
  });

  test('FR10E competencies come from canonical structure without content', () async {
    const loader = StudyContentLoader();

    final competencies = await loader.loadCompetencies('d07');

    expect(competencies.length, csp11Domains.last.competencies.length);
    expect(competencies.first['id'], 'd07_c01');
    expect(competencies.first['domainId'], 'd07');
    expect(competencies.first['competencyNumber'], 1);
    expect(competencies.first['title'], isNotEmpty);
    expect(competencies.first.containsKey('version'), isFalse);
    expect(competencies.first.containsKey('status'), isFalse);
  });

  test('FR10E accepts legacy domain identity only for blueprint lookup', () async {
    const loader = StudyContentLoader();

    final canonical = await loader.loadCompetencies('d01');
    final legacy = await loader.loadCompetencies('domain_01');

    expect(legacy, canonical);
    expect(legacy.every((item) => item['domainId'] == 'd01'), isTrue);
  });

  test('FR10E canonical index lookup performs no package load', () async {
    const loader = StudyContentLoader();

    final entry = await loader.loadCompetencyIndexEntry('d01', 'd01_c01');

    expect(entry, isNotNull);
    expect(entry!['id'], 'd01_c01');
    expect(entry['domainId'], 'd01');
    expect(entry['competencyNumber'], 1);
  });

  test('FR10E zero-argument loader blocks retired broad content reads', () async {
    const loader = StudyContentLoader();

    await expectLater(
      loader.loadPublishedContent(),
      throwsA(isA<UnsupportedError>()),
    );
    await expectLater(
      loader.loadPublishedDomainContent('d01'),
      throwsA(isA<UnsupportedError>()),
    );
  });
}
