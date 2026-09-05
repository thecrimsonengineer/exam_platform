import 'package:flutter_test/flutter_test.dart';

import '../../../lib/data/csp11_blueprint.dart';
import '../../../lib/models/study_content.dart';
import '../../../lib/services/study_content/canonical_content_identity_mapper.dart';

void main() {
  const mapper = CanonicalContentIdentityMapper();

  StudyContent makeContent({
    String id = 'domain_07_01-v2',
    String domainId = 'domain_07',
    String competencyId = 'domain_07_01',
    int competencyNumber = 1,
    int version = 2,
    String status = 'draft',
  }) {
    return StudyContent(
      id: id,
      domainId: domainId,
      competencyId: competencyId,
      competencyNumber: competencyNumber,
      title: 'Needs Assessment',
      status: status,
      version: version,
      subtopics: const [],
    );
  }

  test('maps legacy competency identity to canonical competency ID', () {
    final result = mapper.normalize(makeContent());

    expect(result.content.competencyId, 'd07_c01');
    expect(result.content.competencyNumber, 1);
    expect(result.content.domainId, 'd07');
  });

  test('preserves package identity, version, and lifecycle status', () {
    final result = mapper.normalize(
      makeContent(
        id: 'domain_07_01-v2',
        version: 2,
        status: 'draft',
      ),
    );

    expect(result.content.id, 'domain_07_01-v2');
    expect(result.content.version, 2);
    expect(result.content.status, 'draft');
  });

  test('preserves original legacy identity for diagnostics', () {
    final result = mapper.normalize(makeContent());

    expect(result.legacyDomainId, 'domain_07');
    expect(result.legacyCompetencyId, 'domain_07_01');
  });

  test('accepts an already canonical competency ID', () {
    final result = mapper.normalize(
      makeContent(
        domainId: 'd07',
        competencyId: 'd07_c01',
      ),
    );

    expect(result.content.domainId, 'd07');
    expect(result.content.competencyId, 'd07_c01');
  });

  test('rejects an unknown domain', () {
    expect(
      () => mapper.normalize(
        makeContent(domainId: 'domain_99'),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects a competency number that does not exist in the domain', () {
    expect(
      () => mapper.normalize(
        makeContent(
          competencyId: 'domain_07_99',
          competencyNumber: 99,
        ),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects mismatched competency ID and competency number', () {
    expect(
      () => mapper.normalize(
        makeContent(
          competencyId: 'domain_07_02',
          competencyNumber: 1,
        ),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('does not rewrite the package ID into the competency ID', () {
    final result = mapper.normalize(
      makeContent(id: 'domain_07_01-v2'),
    );

    expect(result.content.id, 'domain_07_01-v2');
    expect(result.content.competencyId, 'd07_c01');
  });

  test('preserves subtopics unchanged', () {
    final content = makeContent();

    final result = mapper.normalize(content);

    expect(result.content.subtopics, same(content.subtopics));
  });

  test('canonical resolution agrees with the frozen blueprint', () {
    final result = mapper.normalize(makeContent());

    final domain = domainForId('d07');
    expect(domain, isNotNull);

    final competency = competencyForId('d07_c01');
    expect(competency, isNotNull);

    expect(result.content.domainId, domain!.id);
    expect(result.content.competencyId, competency!.id);
  });
}
